import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.messageId}');
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final StreamController<String?> _conversationTapController =
      StreamController<String?>.broadcast();

  Stream<String?> get onConversationTap => _conversationTapController.stream;

  bool _initialized = false;
  String? _currentToken;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final conversationId = response.payload;
        if (conversationId != null && conversationId.isNotEmpty) {
          _conversationTapController.add(conversationId);
        }
      },
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
      if (_currentToken == token) return;
      _currentToken = token;

      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      await userRef.set(
        {
          'id': userId,
          'fcm_tokens': FieldValue.arrayUnion([token]),
          'updated_at': DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );

      _messaging.onTokenRefresh.listen((nextToken) async {
        _currentToken = nextToken;
        await userRef.set(
          {
            'fcm_tokens': FieldValue.arrayUnion([nextToken]),
            'updated_at': DateTime.now().toIso8601String(),
          },
          SetOptions(merge: true),
        );
      });
    } catch (error) {
      debugPrint('FCM token registration failed: $error');
    }
  }

  Future<void> unregisterToken(String userId) async {
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
    final conversationId = message.data['conversationId'];
    if (conversationId != null && conversationId.isNotEmpty) {
      _conversationTapController.add(conversationId);
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;
    final title = notification?.title ?? data['senderName'] ?? 'New message';
    final body = notification?.body ?? data['body'] ?? 'You have a new message';
    final conversationId = data['conversationId'] ?? '';

    const androidDetails = AndroidNotificationDetails(
      'messages',
      'Messages',
      channelDescription: 'Chat message notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    await _localNotifications.show(
      conversationId.hashCode,
      title,
      body,
      const NotificationDetails(android: androidDetails),
      payload: conversationId,
    );
  }
}
