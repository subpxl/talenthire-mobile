import 'dart:async';

import 'package:flutter/material.dart';
import 'package:bombay_casting/core/services/messaging_service.dart';
import 'package:bombay_casting/features/messaging/models/conversation.dart';

class MessagingProvider extends ChangeNotifier {
  MessagingProvider({
    required this.userId,
    required this.userName,
    this.onChange,
  }) : _service = MessagingService(userId);

  final String userId;
  final String userName;
  final VoidCallback? onChange;
  final MessagingService _service;

  StreamSubscription<List<Map<String, dynamic>>>? _conversationsSub;
  StreamSubscription<List<Map<String, dynamic>>>? _messagesSub;

  List<ConversationThread> conversations = [];
  List<ChatMessage> activeMessages = [];
  ConversationThread? activeConversation;
  bool isLoading = true;
  bool isSending = false;
  String? pendingConversationId;

  int get unreadTotal => _service.totalUnread(
        conversations.map((thread) => thread.raw).toList(),
      );

  @override
  void notifyListeners() {
    super.notifyListeners();
    onChange?.call();
  }

  void start() {
    if (_conversationsSub != null) return;
    _conversationsSub = _service.watchConversations().listen(
      (items) {
        conversations = items
            .map((item) => ConversationThread.fromFirestore(userId, item))
            .toList();
        isLoading = false;
        notifyListeners();
        _syncActiveConversation();
      },
      onError: (_) {
        isLoading = false;
        notifyListeners();
      },
    );
  }

  void _syncActiveConversation() {
    if (activeConversation == null) return;
    for (final thread in conversations) {
      if (thread.id == activeConversation!.id) {
        activeConversation = thread;
        break;
      }
    }
  }

  Future<ConversationThread?> openConversation(String conversationId) async {
    ConversationThread? thread;
    for (final item in conversations) {
      if (item.id == conversationId) {
        thread = item;
        break;
      }
    }
    if (thread == null) {
      final conv = await _service.fetchConversation(conversationId);
      if (conv == null) return null;
      thread = ConversationThread.fromFirestore(userId, conv);
    }
    await openThread(thread);
    return thread;
  }

  Future<void> openThread(ConversationThread thread) async {
    activeConversation = thread;
    pendingConversationId = null;
    _messagesSub?.cancel();
    _messagesSub = _service.watchMessages(thread.id).listen((items) {
      activeMessages = items
          .map((item) => ChatMessage.fromRtdb(item, currentUserId: userId))
          .toList();
      notifyListeners();
    });
    await _service.markRead(thread.id);
    notifyListeners();
  }

  Future<ConversationThread?> startWithAgency({
    required String agencyUserId,
    required String agencyName,
  }) async {
    final conv = await _service.startConversation(
      otherUserId: agencyUserId,
      myName: userName,
      otherName: agencyName,
      myRole: 'influencer',
      otherRole: 'agency',
    );
    final thread = ConversationThread.fromFirestore(userId, conv);
    await openThread(thread);
    return thread;
  }

  Future<void> sendMessage(String text) async {
    final thread = activeConversation;
    if (thread == null || text.trim().isEmpty || isSending) return;
    isSending = true;
    notifyListeners();
    try {
      final otherUserId = _service.otherParticipantId(thread.raw);
      await _service.sendMessage(
        conversationId: thread.id,
        text: text,
        otherUserId: otherUserId,
        participants: List<String>.from(thread.raw['participants'] as List),
      );
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  void queueConversationOpen(String conversationId) {
    pendingConversationId = conversationId;
    notifyListeners();
  }

  Future<ConversationThread?> consumePendingConversation() async {
    final conversationId = pendingConversationId;
    if (conversationId == null) return null;
    pendingConversationId = null;
    notifyListeners();
    return openConversation(conversationId);
  }

  void closeThread() {
    _messagesSub?.cancel();
    _messagesSub = null;
    activeConversation = null;
    activeMessages = [];
    notifyListeners();
  }

  void reset() {
    _conversationsSub?.cancel();
    _messagesSub?.cancel();
    _conversationsSub = null;
    _messagesSub = null;
    conversations = [];
    activeMessages = [];
    activeConversation = null;
    pendingConversationId = null;
    isLoading = true;
    isSending = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _conversationsSub?.cancel();
    _messagesSub?.cancel();
    super.dispose();
  }
}
