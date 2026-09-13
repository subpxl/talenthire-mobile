import 'package:firebase_analytics/firebase_analytics.dart';

/// Minimal Firebase Analytics wrapper — auto app-open only.
class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> initialize() async {
    await _analytics.logAppOpen();
  }
}
