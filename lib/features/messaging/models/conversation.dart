import 'package:flutter/material.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/l10n/app_localizations.dart';

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.isMine,
    required this.time,
    this.id = '',
  });

  final String id;
  final String text;
  final bool isMine;
  final String time;

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
    );
  }
}

class ConversationThread {
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
  final bool isVerified;
  final List<ChatMessage> messages;
  final Map<String, dynamic> raw;

  static const welcomeId = 'welcome';

  bool get isWelcome => id == welcomeId;

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

    return ConversationThread(
      id: (data['id'] ?? '').toString(),
      name: name,
      lastMessage: (data['last_message'] ?? '').toString(),
      time: _formatConversationTime(updatedAt),
      avatarColor: _colorForName(name),
      unreadCount: unreadCount,
      isVerified: isAgency,
      raw: data,
    );
  }
}

ConversationThread welcomeConversation(AppLocalizations l10n) {
  return ConversationThread(
    id: ConversationThread.welcomeId,
    name: l10n.bombayCastingCompany,
    lastMessage: l10n.companyWelcomeMessagePreview,
    time: l10n.today,
    avatarColor: AppColors.primary,
    unreadCount: 1,
    isVerified: true,
    messages: [
      ChatMessage(
        text: l10n.companyWelcomeMessageBody,
        isMine: false,
        time: l10n.today,
      ),
    ],
    raw: const {},
  );
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
