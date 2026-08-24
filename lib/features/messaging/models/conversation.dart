import 'package:flutter/material.dart';

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
