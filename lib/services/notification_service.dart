import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../screens/main_screen.dart';
import '../screens/message_detail_screen.dart';

const _channelId = 'messages';
const _channelName = 'Messages';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  GlobalKey<NavigatorState>? _navigatorKey;
  String? _activeConversationId;
  String? _pendingConversationId;
  String? _currentToken;
  String? _registeredUserId;
  StreamSubscription<String>? _tokenRefreshSub;

  void setActiveConversation(String? conversationId) {
    _activeConversationId = conversationId;
  }

  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    _navigatorKey = navigatorKey;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'New message notifications',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _pendingConversationId = initialMessage.data['conversationId'];
    }
  }

  Future<void> registerForUser(String userId) async {
    _registeredUserId = userId;
    _currentToken = await _messaging.getToken();
    if (_currentToken != null) {
      await _saveToken(userId, _currentToken!);
    }

    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = _messaging.onTokenRefresh.listen((token) async {
      if (_registeredUserId == null) return;
      if (_currentToken != null) {
        await _removeToken(_registeredUserId!, _currentToken!);
      }
      _currentToken = token;
      await _saveToken(_registeredUserId!, token);
    });
  }

  Future<void> unregisterForUser(String userId) async {
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    if (_currentToken != null) {
      await _removeToken(userId, _currentToken!);
    }
    _currentToken = null;
    _registeredUserId = null;
  }

  Future<void> _saveToken(String userId, String token) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'fcm_tokens': FieldValue.arrayUnion([token]),
    });
  }

  Future<void> _removeToken(String userId, String token) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'fcm_tokens': FieldValue.arrayRemove([token]),
    });
  }

  void _onForegroundMessage(RemoteMessage message) {
    if (message.data['type'] != 'new_message') return;

    final conversationId = message.data['conversationId'];
    if (conversationId != null && conversationId == _activeConversationId) {
      return;
    }

    final title = message.notification?.title ??
        message.data['senderName'] ??
        'New message';
    final body = message.notification?.body ??
        message.data['body'] ??
        'You have a new message';

    _showLocalNotification(
      title: title,
      body: body,
      conversationId: conversationId ?? '',
    );
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required String conversationId,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      conversationId.hashCode,
      title,
      body,
      details,
      payload: jsonEncode({'conversationId': conversationId}),
    );
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    if (response.payload == null) return;
    final data = jsonDecode(response.payload!) as Map<String, dynamic>;
    _openConversation(data['conversationId'] as String?);
  }

  void _onMessageOpened(RemoteMessage message) {
    _openConversation(message.data['conversationId']);
  }

  Future<void> processPendingNavigation() async {
    if (_pendingConversationId == null) return;
    final id = _pendingConversationId!;
    _pendingConversationId = null;
    await _openConversation(id);
  }

  Future<void> _openConversation(String? conversationId) async {
    final context = _navigatorKey?.currentContext;
    if (context == null) {
      _pendingConversationId = conversationId;
      return;
    }

    MainScreen.switchTab(3);

    if (conversationId == null || conversationId.isEmpty) return;

    final appState = context.read<AppState>();
    final conversation = await appState.getConversationById(conversationId);
    if (conversation == null) return;

    await Future.delayed(const Duration(milliseconds: 150));

    final nav = _navigatorKey?.currentState;
    if (nav == null) return;

    nav.push(
      MaterialPageRoute(
        builder: (_) => MessageDetailScreen(conversation: conversation),
      ),
    );
  }
}
