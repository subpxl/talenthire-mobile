import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bombay_casting/core/services/messaging_service.dart';
import 'package:bombay_casting/features/messaging/models/conversation.dart';

class MessagingProvider extends ChangeNotifier {
  MessagingProvider({
    required this.userId,
    required this.userName,
    this.isNewUser = false,
    this.onChange,
  })  : _service = MessagingService(userId),
        _showCompanyWelcome = isNewUser,
        _companyWelcomeRead = !isNewUser;

  final String userId;
  final String userName;
  final bool isNewUser;
  final VoidCallback? onChange;
  final MessagingService _service;

  StreamSubscription<List<Map<String, dynamic>>>? _conversationsSub;
  StreamSubscription<List<Map<String, dynamic>>>? _messagesSub;

  List<ConversationThread> _remoteConversations = [];
  /// Synthetic company welcome is registration-only, not every login.
  bool _showCompanyWelcome;
  /// Default read so returning sessions never flash an unread "1".
  bool _companyWelcomeRead;
  List<ChatMessage> _welcomeReplies = [];

  List<ConversationThread> get conversations {
    if (!_showCompanyWelcome) return List.of(_remoteConversations);
    final welcome = ConversationThread.companyWelcome(
      unread: !_companyWelcomeRead,
      replies: _welcomeReplies,
    );
    return [welcome, ..._remoteConversations];
  }

  List<ChatMessage> activeMessages = [];
  ConversationThread? activeConversation;
  bool isLoading = true;
  bool isSending = false;
  Object? loadError;
  String? pendingConversationId;

  /// Messages loaded via "load more" (older than the live tail window).
  List<ChatMessage> _olderMessages = [];
  /// Most recent page, kept in sync by the live RTDB listener.
  List<ChatMessage> _liveMessages = [];
  bool hasMoreMessages = true;
  bool isLoadingMore = false;

  String get _welcomeReadKey => 'company_welcome_read_$userId';
  String get _welcomeRepliesKey => 'company_welcome_replies_$userId';

  int get unreadTotal {
    var total = _service.totalUnread(
      _remoteConversations.map((thread) => thread.raw).toList(),
    );
    if (_showCompanyWelcome && !_companyWelcomeRead) total += 1;
    return total;
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    onChange?.call();
  }

  void start() {
    if (_conversationsSub != null) return;
    unawaited(_loadWelcomeState());
    _conversationsSub = _service.watchConversations().listen(
      (items) {
        unawaited(_service.syncRtdbParticipants(items));
        _remoteConversations = items
            .map((item) => ConversationThread.fromFirestore(userId, item))
            .toList();
        loadError = null;
        isLoading = false;
        notifyListeners();
        _syncActiveConversation();
      },
      onError: (error, stackTrace) {
        debugPrint('Error loading conversations: $error');
        loadError = error;
        isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> _loadWelcomeState() async {
    final prefs = await SharedPreferences.getInstance();
    _welcomeReplies = _decodeWelcomeReplies(prefs.getString(_welcomeRepliesKey));

    if (isNewUser) {
      _showCompanyWelcome = true;
      _companyWelcomeRead = prefs.getBool(_welcomeReadKey) ?? false;
    } else {
      _showCompanyWelcome = false;
      _companyWelcomeRead = true;
    }

    if (activeConversation?.isCompanyWelcome == true) {
      if (!_showCompanyWelcome) {
        closeThread();
        return;
      }
      activeMessages = ConversationThread.companyWelcome(
        unread: false,
        replies: _welcomeReplies,
      ).messages;
    }
    notifyListeners();
  }

  List<ChatMessage> _decodeWelcomeReplies(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .map((item) => ChatMessage.fromStored(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList();
    } catch (error) {
      debugPrint('Error decoding welcome replies: $error');
      return [];
    }
  }

  Future<void> _persistWelcomeReplies() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _welcomeRepliesKey,
      jsonEncode(_welcomeReplies.map((reply) => reply.toStored()).toList()),
    );
  }

  Future<void> _markCompanyWelcomeRead() async {
    if (_companyWelcomeRead) return;
    _companyWelcomeRead = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_welcomeReadKey, true);
  }

  void retry() {
    _conversationsSub?.cancel();
    _conversationsSub = null;
    loadError = null;
    isLoading = _remoteConversations.isEmpty;
    notifyListeners();
    start();
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
    _messagesSub = null;
    _olderMessages = [];
    _liveMessages = [];
    hasMoreMessages = true;
    isLoadingMore = false;
    if (thread.isCompanyWelcome) {
      activeMessages = ConversationThread.companyWelcome(
        unread: false,
        replies: _welcomeReplies,
      ).messages;
      await _markCompanyWelcomeRead();
      notifyListeners();
      return;
    }
    await _service.ensureRtdbConversation(thread.id);
    _messagesSub = _service.watchMessages(thread.id).listen(
      (items) {
        _liveMessages = items
            .map((item) => ChatMessage.fromRtdb(item, currentUserId: userId))
            .toList();
        // Live tail window came back short of a full page: there's nothing
        // older left to fetch.
        if (_liveMessages.length < MessagingService.pageSize) {
          hasMoreMessages = false;
        }
        final liveIds = _liveMessages.map((m) => m.id).toSet();
        _olderMessages =
            _olderMessages.where((m) => !liveIds.contains(m.id)).toList();
        _recomputeActiveMessages();
        notifyListeners();
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Error loading messages for ${thread.id}: $error');
        debugPrint('$stackTrace');
      },
    );
    await _service.markRead(thread.id);
    notifyListeners();
  }

  void _recomputeActiveMessages() {
    activeMessages = [..._olderMessages, ..._liveMessages];
  }

  /// Fetches the next page of older messages and prepends them. Called when
  /// the user scrolls to the top of the chat.
  Future<void> loadMoreMessages() async {
    final thread = activeConversation;
    if (thread == null || thread.isCompanyWelcome) return;
    if (isLoadingMore || !hasMoreMessages) return;

    final oldestLoaded = activeMessages.isNotEmpty
        ? activeMessages.first.createdAtMillis
        : null;
    if (oldestLoaded == null) return;

    isLoadingMore = true;
    notifyListeners();
    try {
      final older = await _service.fetchOlderMessages(
        thread.id,
        beforeMillis: oldestLoaded,
      );
      final mapped = older
          .map((item) => ChatMessage.fromRtdb(item, currentUserId: userId))
          .toList();
      if (mapped.length < MessagingService.pageSize) {
        hasMoreMessages = false;
      }
      final existingIds = {
        ..._olderMessages.map((m) => m.id),
        ..._liveMessages.map((m) => m.id),
      };
      final newOnes =
          mapped.where((m) => !existingIds.contains(m.id)).toList();
      _olderMessages = [...newOnes, ..._olderMessages];
      _recomputeActiveMessages();
    } catch (error, stackTrace) {
      debugPrint('Error loading older messages for ${thread.id}: $error');
      debugPrint('$stackTrace');
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
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
    final trimmed = text.trim();
    if (thread == null || trimmed.isEmpty || isSending) return;

    if (thread.isCompanyWelcome) {
      await _sendWelcomeReply(trimmed);
      return;
    }

    isSending = true;
    notifyListeners();
    try {
      final otherUserId = _service.otherParticipantId(thread.raw);
      await _service.sendMessage(
        conversationId: thread.id,
        text: trimmed,
        otherUserId: otherUserId,
      );
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  Future<void> _sendWelcomeReply(String text) async {
    isSending = true;
    notifyListeners();
    try {
      _welcomeReplies = [
        ..._welcomeReplies,
        ChatMessage.localNow(text: text, isMine: true),
      ];
      final welcome = ConversationThread.companyWelcome(
        unread: false,
        replies: _welcomeReplies,
      );
      activeConversation = welcome;
      activeMessages = welcome.messages;
      notifyListeners();
      await _persistWelcomeReplies();
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
    _olderMessages = [];
    _liveMessages = [];
    hasMoreMessages = true;
    isLoadingMore = false;
    notifyListeners();
  }

  void reset() {
    _conversationsSub?.cancel();
    _messagesSub?.cancel();
    _conversationsSub = null;
    _messagesSub = null;
    _remoteConversations = [];
    _showCompanyWelcome = false;
    _companyWelcomeRead = true;
    _welcomeReplies = [];
    activeMessages = [];
    _olderMessages = [];
    _liveMessages = [];
    hasMoreMessages = true;
    isLoadingMore = false;
    activeConversation = null;
    pendingConversationId = null;
    isLoading = true;
    isSending = false;
    loadError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _conversationsSub?.cancel();
    _messagesSub?.cancel();
    super.dispose();
  }
}
