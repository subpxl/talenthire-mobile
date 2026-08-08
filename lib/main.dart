import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';
import 'providers/app_state.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'screens/dob_verification_screen.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  if (message.data['type'] == 'new_message') {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    
    await flutterLocalNotificationsPlugin.initialize(initSettings);
    
    const androidDetails = AndroidNotificationDetails(
      'messages',
      'Messages',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());
    
    final title = message.notification?.title ?? message.data['senderName'] ?? 'New message';
    final body = message.notification?.body ?? message.data['body'] ?? 'You have a new message';
    final conversationId = message.data['conversationId'] ?? '';
    
    await flutterLocalNotificationsPlugin.show(
      conversationId.hashCode,
      title,
      body,
      details,
      payload: jsonEncode({'conversationId': conversationId}),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Keep more decoded images in memory to avoid re-fetching on scroll.
  PaintingBinding.instance.imageCache.maximumSize = 250;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 100 << 20; // 100 MB

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Show UI immediately — defer heavy service init until after first frame.
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AppState()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initServices());
  }

  Future<void> _initServices() async {
    await AuthService().initializeGoogleSignIn();
    await NotificationService().initialize(navigatorKey);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'FSAP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Consumer<AppState>(
        builder: (context, appState, child) {
          if (appState.isLoading) {
            return const SplashScreen();
          }
          if (!appState.isAuthenticated) {
            return const LoginScreen();
          }
          if (appState.needsDobVerification) {
            return const DobVerificationScreen();
          }
          return MainScreen(key: MainScreen.mainKey);
        },
      ),
    );
  }
}
