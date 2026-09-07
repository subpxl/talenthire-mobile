import 'dart:async';
import 'dart:ui' show Color;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:bombay_casting/firebase_options.dart';

class PushTapTarget {
  const PushTapTarget({
    this.type = '',
    this.conversationId = '',
    this.jobId = '',
    this.notificationId = '',
  });

  final String type;
  final String conversationId;
  final String jobId;
  final String notificationId;

  bool get opensConversation => conversationId.isNotEmpty;
  bool get opensJob => jobId.isNotEmpty;
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Notification payloads are already drawn by Android using the default icon.
  if (message.notification != null) return;
  await PushNotificationService.displayRemoteMessage(message);
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  static const _messagesChannelId = 'messages';
  static const _alertsChannelId = 'alerts';
  static const _smallIcon = '@drawable/ic_stat_notification';
  static const _largeIcon = '@drawable/ic_notification_large';
  static const _brandColor = Color(0xFFDC1C38);

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final StreamController<PushTapTarget> _tapController =
      StreamController<PushTapTarget>.broadcast();

  Stream<PushTapTarget> get onNotificationTap => _tapController.stream;

  bool _initialized = false;
  String? _currentToken;
  StreamSubscription<String>? _tokenRefreshSub;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    const androidInit = AndroidInitializationSettings(_smallIcon);
    const darwinInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
    );
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final target = _targetFromPayload(response.payload ?? '');
        if (target != null) _tapController.add(target);
      },
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _messagesChannelId,
        'Messages',
        description: 'Chat message notifications',
        importance: Importance.high,
      ),
    );
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _alertsChannelId,
        'Alerts',
        description: 'Admin and job alerts',
        importance: Importance.high,
      ),
    );

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _handleOpenedMessage(initial);
    }
  }

  Future<void> registerToken(String userId) async {
    if (userId.isEmpty) return;
    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;
      await _saveToken(userId, token);

      await _tokenRefreshSub?.cancel();
      _tokenRefreshSub = _messaging.onTokenRefresh.listen((nextToken) {
        unawaited(_saveToken(userId, nextToken));
      });
    } catch (error) {
      debugPrint('FCM token registration failed: $error');
    }
  }

  Future<void> _saveToken(String userId, String token) async {
    if (_currentToken == token) return;
    _currentToken = token;
    await FirebaseFirestore.instance.collection('users').doc(userId).set(
      {
        'id': userId,
        'fcm_tokens': FieldValue.arrayUnion([token]),
        'updated_at': DateTime.now().toIso8601String(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> unregisterToken(String userId) async {
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    if (userId.isEmpty || _currentToken == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set(
        {
          'fcm_tokens': FieldValue.arrayRemove([_currentToken]),
          'updated_at': DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );
    } catch (error) {
      debugPrint('FCM token unregister failed: $error');
    } finally {
      _currentToken = null;
    }
  }

  void _handleOpenedMessage(RemoteMessage message) {
    final target = _targetFromData(message.data);
    if (target != null) _tapController.add(target);
  }

  Future<void> _showForegroundNotification(RemoteMessage message) {
    return displayRemoteMessage(message, plugin: _localNotifications);
  }

  static Future<void> displayRemoteMessage(
    RemoteMessage message, {
    FlutterLocalNotificationsPlugin? plugin,
  }) async {
    final local = plugin ?? FlutterLocalNotificationsPlugin();
    if (plugin == null) {
      await local.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings(_smallIcon),
          iOS: DarwinInitializationSettings(),
        ),
      );
    }

    final notification = message.notification;
    final data = message.data;
    final type = (data['type'] ?? '').toString();
    final isChat = type == 'new_message' ||
        (data['conversationId'] ?? '').toString().isNotEmpty;
    final title = notification?.title ??
        data['title'] ??
        data['senderName'] ??
        (isChat ? 'New message' : 'Notification');
    final body = notification?.body ??
        data['body'] ??
        (isChat ? 'You have a new message' : 'You have a new notification');
    final payload = _payloadFromData(data);
    final channelId = isChat ? _messagesChannelId : _alertsChannelId;

    final androidDetails = AndroidNotificationDetails(
      channelId,
      isChat ? 'Messages' : 'Alerts',
      channelDescription: isChat
          ? 'Chat message notifications'
          : 'Admin and job alerts',
      importance: Importance.high,
      priority: Priority.high,
      icon: _smallIcon,
      largeIcon: const DrawableResourceAndroidBitmap(_largeIcon),
      color: _brandColor,
    );

    await local.show(
      (payload.isEmpty ? title : payload).hashCode,
      title.toString(),
      body.toString(),
      NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  static String _payloadFromData(Map<String, dynamic> data) {
    final type = (data['type'] ?? '').toString();
    final conversationId = (data['conversationId'] ?? '').toString();
    final jobId = (data['jobId'] ?? data['job_id'] ?? '').toString();
    final notificationId =
        (data['notificationId'] ?? data['notification_id'] ?? '').toString();
    return [
      type,
      conversationId,
      jobId,
      notificationId,
    ].join('|');
  }

  static PushTapTarget? _targetFromData(Map<String, dynamic> data) {
    final target = PushTapTarget(
      type: (data['type'] ?? '').toString(),
      conversationId: (data['conversationId'] ?? '').toString(),
      jobId: (data['jobId'] ?? data['job_id'] ?? '').toString(),
      notificationId:
          (data['notificationId'] ?? data['notification_id'] ?? '').toString(),
    );
    if (target.type.isEmpty &&
        !target.opensConversation &&
        !target.opensJob &&
        target.notificationId.isEmpty) {
      return const PushTapTarget(type: 'admin');
    }
    return target;
  }

  static PushTapTarget? _targetFromPayload(String payload) {
    if (payload.isEmpty) return const PushTapTarget(type: 'admin');
    // Legacy payloads were a raw conversation id.
    if (!payload.contains('|')) {
      return PushTapTarget(conversationId: payload);
    }
    final parts = payload.split('|');
    return PushTapTarget(
      type: parts.isNotEmpty ? parts[0] : '',
      conversationId: parts.length > 1 ? parts[1] : '',
      jobId: parts.length > 2 ? parts[2] : '',
      notificationId: parts.length > 3 ? parts[3] : '',
    );
  }
}
