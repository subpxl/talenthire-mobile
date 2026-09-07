import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class MessagingService {
  MessagingService(this.userId);

  final String userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseReference _messagesRoot =
      FirebaseDatabase.instance.ref('messages');

  /// Messages per page. Keeps live listener + "load older" queries cheap
  /// (only ~30 nodes transferred at a time instead of full chat history).
  static const int pageSize = 30;

  static String conversationId(String uidA, String uidB) {
    final ids = [uidA, uidB]..sort();
    return ids.join('_');
  }

  List<Map<String, dynamic>> _mapAndSort(Object? value) {
    if (value is! Map) return <Map<String, dynamic>>[];
    final messages = value.entries.map((entry) {
      final data = Map<String, dynamic>.from(entry.value as Map);
      data['id'] ??= entry.key;
      return data;
    }).toList();
    messages.sort((a, b) {
      final aTs = (a['created_at'] as num?)?.toInt() ?? 0;
      final bTs = (b['created_at'] as num?)?.toInt() ?? 0;
      return aTs.compareTo(bTs);
    });
    return messages;
  }

  Stream<List<Map<String, dynamic>>> watchConversations() {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      final conversations = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
      conversations.sort((a, b) {
        final aDate = DateTime.tryParse('${a['updated_at']}') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = DateTime.tryParse('${b['updated_at']}') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return conversations;
    });
  }

  /// Live "tail window": only the most recent [limit] messages. Older
  /// history is fetched on demand via [fetchOlderMessages] instead of
  /// streaming (and re-downloading) the entire conversation on every open.
  Stream<List<Map<String, dynamic>>> watchMessages(
    String conversationId, {
    int limit = pageSize,
  }) {
    return _messagesRoot
        .child(conversationId)
        .orderByChild('created_at')
        .limitToLast(limit)
        .onValue
        .map((event) => _mapAndSort(event.snapshot.value));
  }

  /// One-time fetch of up to [limit] messages older than [beforeMillis].
  /// Used for "load more" when the user scrolls to the top of a chat.
  Future<List<Map<String, dynamic>>> fetchOlderMessages(
    String conversationId, {
    required int beforeMillis,
    int limit = pageSize,
  }) async {
    final snapshot = await _messagesRoot
        .child(conversationId)
        .orderByChild('created_at')
        .endBefore(beforeMillis)
        .limitToLast(limit)
        .get();
    return _mapAndSort(snapshot.value);
  }

  Future<Map<String, dynamic>?> fetchUser(String uid) async {
    final snap = await _firestore.collection('users').doc(uid).get();
    if (!snap.exists) return null;
    return snap.data();
  }

  Future<Map<String, dynamic>> startConversation({
    required String otherUserId,
    required String myName,
    required String otherName,
    String myRole = 'influencer',
    String otherRole = 'agency',
  }) async {
    final existing = await _findExistingConversation(otherUserId);
    if (existing != null) {
      await ensureRtdbConversation(existing['id'] as String);
      return existing;
    }

    final convId = conversationId(userId, otherUserId);
    final now = DateTime.now().toIso8601String();
    final conv = {
      'participants': [userId, otherUserId],
      'last_message': '',
      'updated_at': now,
      'unread_counts': {userId: 0, otherUserId: 0},
      'participant_names': {userId: myName, otherUserId: otherName},
      'participant_types': {userId: myRole, otherUserId: otherRole},
      'participant_initials': {
        userId: _initials(myName),
        otherUserId: _initials(otherName),
      },
    };

    await _firestore.collection('conversations').doc(convId).set(conv);
    await ensureRtdbConversation(convId);
    return {'id': convId, ...conv};
  }

  Future<Map<String, dynamic>?> _findExistingConversation(
    String otherUserId,
  ) async {
    final canonicalId = conversationId(userId, otherUserId);
    final canonical = await _firestore
        .collection('conversations')
        .doc(canonicalId)
        .get();
    if (canonical.exists) {
      return {'id': canonical.id, ...canonical.data()!};
    }

    final legacyId = '${userId}_$otherUserId';
    if (legacyId != canonicalId) {
      final legacy =
          await _firestore.collection('conversations').doc(legacyId).get();
      if (legacy.exists) {
        return {'id': legacy.id, ...legacy.data()!};
      }
    }

    final reverseLegacyId = '${otherUserId}_$userId';
    if (reverseLegacyId != canonicalId && reverseLegacyId != legacyId) {
      final reverse = await _firestore
          .collection('conversations')
          .doc(reverseLegacyId)
          .get();
      if (reverse.exists) {
        return {'id': reverse.id, ...reverse.data()!};
      }
    }

    return null;
  }

  Future<void> ensureRtdbConversation(String conversationId) async {
    // RTDB rules only allow each user to write their own participant flag.
    await _ensureRtdbParticipant(conversationId);
  }

  /// Registers the signed-in user for RTDB reads/writes on this conversation.
  Future<void> _ensureRtdbParticipant(String conversationId) async {
    final ref = FirebaseDatabase.instance
        .ref('conversations/$conversationId/participants/$userId');
    try {
      await ref.set(true);
    } catch (error, stackTrace) {
      debugPrint(
        'RTDB participant setup failed for $conversationId/$userId: $error',
      );
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  /// Ensures RTDB access for every loaded Firestore conversation.
  Future<void> syncRtdbParticipants(
    Iterable<Map<String, dynamic>> conversations,
  ) async {
    final futures = <Future<void>>[];
    for (final conversation in conversations) {
      final conversationId = conversation['id']?.toString();
      if (conversationId == null || conversationId.isEmpty) continue;
      futures.add(
        _ensureRtdbParticipant(conversationId).catchError((Object error) {
          debugPrint(
            'RTDB participant sync skipped for $conversationId: $error',
          );
        }),
      );
    }
    if (futures.isEmpty) return;
    await Future.wait(futures);
  }

  Future<void> sendMessage({
    required String conversationId,
    required String text,
    required String otherUserId,
  }) async {
    await ensureRtdbConversation(conversationId);
    final trimmed = text.trim();
    final displayText =
        trimmed.isEmpty ? 'Sent an attachment' : trimmed;
    final now = DateTime.now();
    final msgRef = _messagesRoot.child(conversationId).push();
    await msgRef.set({
      'id': msgRef.key,
      'conversation_id': conversationId,
      'text': displayText,
      'sender_id': userId,
      'created_at': now.millisecondsSinceEpoch,
      'attachment_url': null,
      'attachment_name': null,
    });

    final convRef = _firestore.collection('conversations').doc(conversationId);
    final convSnap = await convRef.get();
    final convData = convSnap.data() ?? {};
    final unread = convData['unread_counts'];
    final currentUnread =
        unread is Map ? (unread[otherUserId] as num?)?.toInt() ?? 0 : 0;

    await convRef.update({
      'last_message': displayText,
      'last_sender_id': userId,
      'updated_at': now.toIso8601String(),
      'unread_counts.$otherUserId': currentUnread + 1,
      'unread_counts.$userId': 0,
    });
  }

  Future<void> markRead(String conversationId) async {
    await _firestore.collection('conversations').doc(conversationId).update({
      'unread_counts.$userId': 0,
    });
  }

  Future<Map<String, dynamic>?> fetchConversation(String conversationId) async {
    final snap =
        await _firestore.collection('conversations').doc(conversationId).get();
    if (!snap.exists) return null;
    return {'id': snap.id, ...snap.data()!};
  }

  int totalUnread(List<Map<String, dynamic>> conversations) {
    var total = 0;
    for (final conv in conversations) {
      final lastSenderId = (conv['last_sender_id'] ?? '').toString();
      if (lastSenderId.isNotEmpty && lastSenderId == userId) continue;
      final unread = conv['unread_counts'];
      if (unread is Map) {
        total += (unread[userId] as num?)?.toInt() ?? 0;
      }
    }
    return total;
  }

  String otherParticipantId(Map<String, dynamic> conversation) {
    final participants = List<String>.from(conversation['participants'] as List);
    return participants.firstWhere((id) => id != userId, orElse: () => '');
  }

  String participantName(Map<String, dynamic> conversation) {
    final otherId = otherParticipantId(conversation);
    final names = conversation['participant_names'];
    if (names is Map && otherId.isNotEmpty) {
      return (names[otherId] ?? 'Agency').toString();
    }
    return 'Agency';
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final list = parts.toList();
    if (list.isEmpty) return '??';
    if (list.length >= 2) {
      return '${list[0][0]}${list[1][0]}'.toUpperCase();
    }
    return list.first.substring(0, list.first.length >= 2 ? 2 : 1).toUpperCase();
  }
}
