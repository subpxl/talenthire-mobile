import 'package:flutter/material.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.isMine,
    required this.time,
    this.id = '',
    this.createdAtMillis,
  });

  final String id;
  final String text;
  final bool isMine;
  final String time;
  final int? createdAtMillis;

  factory ChatMessage.fromRtdb(
    Map<String, dynamic> data, {
    required String currentUserId,
  }) {
    final createdAt = (data['created_at'] as num?)?.toInt();
    return ChatMessage(
      id: (data['id'] ?? '').toString(),
      text: (data['text'] ?? '').toString(),
      isMine: data['sender_id'] == currentUserId,
      time: _formatMessageTime(createdAt),
      createdAtMillis: createdAt,
    );
  }

  factory ChatMessage.localNow({
    required String text,
    required bool isMine,
  }) {
    final now = DateTime.now();
    return ChatMessage(
      id: 'local_${now.millisecondsSinceEpoch}',
      text: text,
      isMine: isMine,
      time: _formatConversationTime(now),
      createdAtMillis: now.millisecondsSinceEpoch,
    );
  }

  factory ChatMessage.fromStored(Map<String, dynamic> data) {
    final createdAt = (data['created_at'] as num?)?.toInt();
    return ChatMessage(
      id: (data['id'] ?? '').toString(),
      text: (data['text'] ?? '').toString(),
      isMine: true,
      time: _formatMessageTime(createdAt),
      createdAtMillis: createdAt,
    );
  }

  Map<String, dynamic> toStored() {
    return {
      'id': id,
      'text': text,
      'created_at': createdAtMillis,
    };
  }
}

class ConversationThread {
  static const companyWelcomeId = 'company_welcome';

  const ConversationThread({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.avatarColor,
    required this.raw,
    this.imageIndex = 1,
    this.imageUrl = '',
    this.unreadCount = 0,
    this.lastSenderId = '',
    this.currentUserId = '',
    this.isVerified = false,
    this.messages = const [],
  });

  final String id;
  final String name;
  final String lastMessage;
  final String time;
  final Color avatarColor;
  final int imageIndex;
  final String imageUrl;
  final int unreadCount;
  final String lastSenderId;
  final String currentUserId;
  final bool isVerified;
  final List<ChatMessage> messages;
  final Map<String, dynamic> raw;

  bool get isCompanyWelcome => id == companyWelcomeId;

  /// Shown once after registration. Copy is localized in UI.
  factory ConversationThread.companyWelcome({
    required bool unread,
    List<ChatMessage> replies = const [],
  }) {
    final time = _formatConversationTime(DateTime.now());
    final lastReply = replies.isNotEmpty ? replies.last : null;
    final body = ChatMessage(
      id: '${companyWelcomeId}_body',
      text:
          'Hi there! Welcome to Bombay Casting Company.\n\nBrowse UGC opportunities, apply to brands you love, and chat with agencies right here. Complete your profile to stand out and land your next collab.\n\nWe\'re excited to have you on board!',
      isMine: false,
      time: time,
    );
    return ConversationThread(
      id: companyWelcomeId,
      name: 'Bombay Casting Company',
      lastMessage: lastReply?.text ??
          'Welcome! Browse UGC jobs and start your next collab.',
      time: lastReply?.time ?? time,
      avatarColor: AppColors.primary,
      unreadCount: unread ? 1 : 0,
      lastSenderId: lastReply != null ? 'local' : companyWelcomeId,
      currentUserId: 'local',
      isVerified: true,
      messages: [body, ...replies],
      raw: const {
        'participants': <String>[],
        'is_company_welcome': true,
      },
    );
  }

  /// Count pill only when the other person sent messages we haven't opened.
  bool get hasIncomingUnread {
    if (unreadCount <= 0) return false;
    if (lastSenderId.isEmpty || currentUserId.isEmpty) return true;
    return lastSenderId != currentUserId;
  }

  factory ConversationThread.fromFirestore(
    String currentUserId,
    Map<String, dynamic> data,
  ) {
    final participants = List<String>.from(data['participants'] as List? ?? []);
    final otherId = participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    final names = data['participant_names'];
    final types = data['participant_types'];
    final unread = data['unread_counts'];
    final name = names is Map && otherId.isNotEmpty
        ? (names[otherId] ?? 'Agency').toString()
        : 'Agency';
    final isAgency = types is Map &&
        otherId.isNotEmpty &&
        types[otherId] == 'agency';
    final unreadCount = unread is Map
        ? (unread[currentUserId] as num?)?.toInt() ?? 0
        : 0;
    final updatedAt = DateTime.tryParse('${data['updated_at']}');
    final lastSenderId = (data['last_sender_id'] ?? '').toString();

    return ConversationThread(
      id: (data['id'] ?? '').toString(),
      name: name,
      lastMessage: (data['last_message'] ?? '').toString(),
      time: _formatConversationTime(updatedAt),
      avatarColor: _colorForName(name),
      unreadCount: unreadCount,
      lastSenderId: lastSenderId,
      currentUserId: currentUserId,
      isVerified: isAgency,
      raw: data,
    );
  }
}

Color _colorForName(String name) {
  const palette = [
    AppColors.primary,
    AppColors.chatGreen,
    Color(0xFF1565C0),
    Color(0xFF6A1B9A),
    Color(0xFFEF6C00),
  ];
  var hash = 0;
  for (final codeUnit in name.codeUnits) {
    hash = (hash + codeUnit) % palette.length;
  }
  return palette[hash];
}

String _formatConversationTime(DateTime? date) {
  if (date == null) return '';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final messageDay = DateTime(date.year, date.month, date.day);
  if (messageDay == today) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
  if (messageDay == today.subtract(const Duration(days: 1))) {
    return 'Yesterday';
  }
  return '${date.day}/${date.month}/${date.year}';
}

String _formatMessageTime(int? millis) {
  if (millis == null) return '';
  return _formatConversationTime(
    DateTime.fromMillisecondsSinceEpoch(millis),
  );
}
