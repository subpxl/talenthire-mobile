import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/firebase_options.dart';
import 'package:bombay_casting/providers/app_state.dart';
import 'package:bombay_casting/screens/login_screen.dart';
import 'package:bombay_casting/screens/main_shell.dart';
import 'package:bombay_casting/screens/splash_screen.dart';
import 'package:bombay_casting/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bombay Casting Company',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: Consumer<AppState>(
        builder: (context, appState, _) {
          if (appState.isLoading) {
            return const SplashScreen();
          }
          if (!appState.isAuthenticated) {
            return const LoginScreen();
          }
          return const MainShell();
        },
      ),
    );
  }
}
