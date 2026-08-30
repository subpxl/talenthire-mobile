import 'package:flutter/material.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/l10n/app_localizations.dart';

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.isMine,
    required this.time,
  });

  final String text;
  final bool isMine;
  final String time;
}

class ConversationThread {
  const ConversationThread({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.avatarColor,
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
}

ConversationThread welcomeConversation(AppLocalizations l10n) {
  return ConversationThread(
    id: 'welcome',
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
  );
}
