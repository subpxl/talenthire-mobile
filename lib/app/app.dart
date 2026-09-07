import 'package:flutter/material.dart';
import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/app/main_shell.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/features/auth/screens/login_screen.dart';
import 'package:bombay_casting/features/auth/screens/splash_screen.dart';
import 'package:bombay_casting/features/onboarding/first_login_step.dart';
import 'package:bombay_casting/features/onboarding/screens/enter_mobile_screen.dart';
import 'package:bombay_casting/features/onboarding/screens/onboarding_photo_screen.dart';
import 'package:bombay_casting/features/onboarding/screens/select_language_screen.dart';
import 'package:bombay_casting/features/profile/screens/deactivated_account_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  static Widget _loadingScreen() {
    return const SplashScreen();
  }

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
          if (appState.isLoading || !appState.localeReady) {
            return _loadingScreen();
          }
          if (!appState.isAuthenticated) {
            return const LoginScreen();
          }
          if (appState.isAccountDeactivated) {
            return const DeactivatedAccountScreen();
          }
          switch (appState.firstLoginStep) {
            case FirstLoginStep.mobile:
              return const EnterMobileScreen();
            case FirstLoginStep.language:
              return const LanguageScreen(isOnboarding: true);
            case FirstLoginStep.photo:
              return const OnboardingPhotoScreen();
            case FirstLoginStep.none:
              return const MainShell();
          }
        },
      ),
    );
  }
}
