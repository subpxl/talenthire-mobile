import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/navigation/app_navigation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Shows the premium checkout modal for signed-in non-premium users.
class PremiumPaywallGate {
  PremiumPaywallGate._();

  static DateTime? _lastShownAt;
  static const _debounce = Duration(seconds: 1);

  /// Resets when the app process starts (fresh open).
  static final Set<String> _shownThisSession = {};

  /// Main shell tab indices: 1 Creators, 2 Jobs, 3 Messages.
  static const _navTabSources = <int, String>{
    1: 'nav_creators',
    2: 'nav_jobs',
    3: 'nav_messages',
  };

  /// Once per Creators / Jobs / Messages tab per app session (bottom nav tap).
  static void maybeShowOnMainTab(BuildContext context, int tabIndex) {
    final source = _navTabSources[tabIndex];
    if (source == null) return;
    if (!context.mounted) return;

    final state = context.read<AppState>();
    if (state.isLoading || !state.isAuthenticated || state.isPremiumUser) {
      return;
    }

    if (_shownThisSession.contains(source)) return;

    final now = DateTime.now();
    if (_lastShownAt != null && now.difference(_lastShownAt!) < _debounce) {
      return;
    }
    _lastShownAt = now;
    _shownThisSession.add(source);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      if (context.read<AppState>().isPremiumUser) return;
      AppNavigation.openPremiumScreen(context, source: source);
    });
  }
}
