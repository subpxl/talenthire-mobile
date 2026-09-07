import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:bombay_casting/core/services/notification_inbox_service.dart';
import 'package:bombay_casting/features/notifications/models/app_notification.dart';

class NotificationsProvider extends ChangeNotifier {
  NotificationsProvider({
    required this.userId,
    this.onChange,
  }) : _service = NotificationInboxService(userId);

  final String userId;
  final VoidCallback? onChange;
  final NotificationInboxService _service;

  StreamSubscription<List<Map<String, dynamic>>>? _sub;
  List<AppNotification> items = [];
  bool isLoading = true;
  Object? loadError;

  int get unreadCount => items.where((item) => !item.read).length;

  @override
  void notifyListeners() {
    super.notifyListeners();
    onChange?.call();
  }

  void start() {
    if (_sub != null) return;
    _sub = _service.watchNotifications().listen(
      (raw) {
        items = raw
            .map(
              (item) => AppNotification.fromFirestore(
                (item['id'] ?? '').toString(),
                item,
              ),
            )
            .toList();
        loadError = null;
        isLoading = false;
        notifyListeners();
      },
      onError: (error, stackTrace) {
        debugPrint('Error loading notifications: $error');
        loadError = error;
        isLoading = false;
        notifyListeners();
      },
    );
  }

  void retry() {
    _sub?.cancel();
    _sub = null;
    loadError = null;
    isLoading = items.isEmpty;
    notifyListeners();
    start();
  }

  Future<void> markRead(AppNotification notification) async {
    if (notification.read) return;
    items = [
      for (final item in items)
        item.id == notification.id ? item.copyWith(read: true) : item,
    ];
    notifyListeners();
    try {
      await _service.markRead(notification.id);
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    final unreadIds =
        items.where((item) => !item.read).map((item) => item.id).toList();
    if (unreadIds.isEmpty) return;
    items = [for (final item in items) item.copyWith(read: true)];
    notifyListeners();
    try {
      await _service.markAllRead(unreadIds);
    } catch (_) {}
  }

  void reset() {
    _sub?.cancel();
    _sub = null;
    items = [];
    isLoading = true;
    loadError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
