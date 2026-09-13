import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/app/version_gate.dart';
import 'package:bombay_casting/core/services/analytics_service.dart';
import 'package:bombay_casting/core/services/push_notification_service.dart';
import 'package:bombay_casting/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AnalyticsService.instance.initialize();
  await PushNotificationService.instance.initialize();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const VersionGate(),
    ),
  );
}
