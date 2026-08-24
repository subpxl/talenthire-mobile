import 'package:flutter/material.dart';
import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/app/main_shell.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/features/auth/screens/login_screen.dart';
import 'package:bombay_casting/features/auth/screens/splash_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return MaterialApp(
      key: ValueKey(
        'auth_${appState.isLoading}_${appState.isAuthenticated}',
      ),
      title: 'Bombay Casting Company',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: appState.appLocale,
      home: Builder(
        builder: (context) {
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
