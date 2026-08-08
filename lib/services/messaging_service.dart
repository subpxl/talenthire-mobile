import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class MessagingService {
  static const databaseUrl =
      'https://talenthire-d86a1-default-rtdb.asia-southeast1.firebasedatabase.app';

  final FirebaseDatabase _rtdb = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: databaseUrl,
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    return _rtdb.ref('messages/$conversationId').onValue.map((event) {
      final value = event.snapshot.value;
      if (value == null || value is! Map) return <ChatMessage>[];

      final messages = value.entries.map((entry) {
        final data = Map<String, dynamic>.from(entry.value as Map);
        data['id'] ??= entry.key.toString();
        data['conversation_id'] ??= conversationId;
        return ChatMessage.fromJson(data);
      }).toList();

      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return messages;
    });
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String recipientId,
    required String text,
  }) async {
    final messageId = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now();

    await _rtdb.ref('messages/$conversationId/$messageId').set({
      'id': messageId,
      'conversation_id': conversationId,
      'text': text,
      'sender_id': senderId,
      'created_at': now.millisecondsSinceEpoch,
    });

    await _firestore.collection('conversations').doc(conversationId).update({
      'last_message': text,
      'updated_at': now.toIso8601String(),
      'unread_counts.$recipientId': FieldValue.increment(1),
    });
  }

  Future<void> markAsRead(String conversationId, String userId) async {
    await _firestore.collection('conversations').doc(conversationId).update({
      'unread_counts.$userId': 0,
    });
  }

  Future<Conversation?> findExistingConversation(
    String userId,
    String participantId,
  ) async {
    final snapshot = await _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      data['id'] = doc.id;
      final conv = Conversation.fromJson(data);
      if (conv.participants.contains(participantId)) {
        return conv;
      }
    }
    return null;
  }

  Future<Conversation> createConversation(Conversation conversation) async {
    await _firestore
        .collection('conversations')
        .doc(conversation.id)
        .set(conversation.toJson());
    return conversation;
  }
}

String formatTimeAgo(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
}
