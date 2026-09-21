import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Firebase Analytics — screen views, auth, and product events.
class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> initialize() async {
    await _analytics.logAppOpen();
  }

  Future<void> logScreen(String screenName, {String? screenClass}) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass ?? screenName,
    );
  }

  Future<void> setUserContext({
    required String userId,
    String? accountRole,
    String? subscriptionStatus,
    bool? profileCompleted,
    bool? isVerified,
  }) async {
    await _analytics.setUserId(id: userId);
    if (accountRole != null) {
      await _analytics.setUserProperty(name: 'account_role', value: accountRole);
    }
    if (subscriptionStatus != null) {
      await _analytics.setUserProperty(
        name: 'subscription_status',
        value: subscriptionStatus,
      );
    }
    if (profileCompleted != null) {
      await _analytics.setUserProperty(
        name: 'profile_completed',
        value: profileCompleted ? 'true' : 'false',
      );
    }
    if (isVerified != null) {
      await _analytics.setUserProperty(
        name: 'is_verified',
        value: isVerified ? 'true' : 'false',
      );
    }
  }

  Future<void> clearUserContext() async {
    await _analytics.setUserId(id: null);
    await _analytics.setUserProperty(name: 'account_role', value: null);
    await _analytics.setUserProperty(name: 'subscription_status', value: null);
    await _analytics.setUserProperty(name: 'profile_completed', value: null);
    await _analytics.setUserProperty(name: 'is_verified', value: null);
  }

  Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }

  Future<void> logSignUp(String method) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  Future<void> logMainTabSelected(int index) async {
    const tabs = ['home', 'creators', 'jobs', 'messages', 'profile'];
    final tab = index >= 0 && index < tabs.length ? tabs[index] : 'unknown';
    await logScreen('main_$tab');
  }

  Future<void> logViewJob({
    required String jobId,
    String? jobTitle,
  }) async {
    await _analytics.logEvent(
      name: 'view_job',
      parameters: {
        'job_id': _clip(jobId, 100),
        if (jobTitle != null && jobTitle.isNotEmpty)
          'job_title': _clip(jobTitle, 100),
      },
    );
  }

  Future<void> logApplyJob({
    required String jobId,
    bool success = true,
  }) async {
    await _analytics.logEvent(
      name: 'apply_job',
      parameters: {
        'job_id': _clip(jobId, 100),
        'success': success ? 'true' : 'false',
      },
    );
  }

  Future<void> logViewCreator({required String creatorId}) async {
    await _analytics.logEvent(
      name: 'view_creator',
      parameters: {'creator_id': _clip(creatorId, 100)},
    );
  }

  Future<void> logViewAgency({required String agencyId}) async {
    await _analytics.logEvent(
      name: 'view_agency',
      parameters: {'agency_id': _clip(agencyId, 100)},
    );
  }

  Future<void> logSearch({
    required String searchTerm,
    required String context,
  }) async {
    await _analytics.logSearch(
      searchTerm: _clip(searchTerm, 100),
      parameters: {'search_context': _clip(context, 40)},
    );
  }

  Future<void> logShare({
    required String contentType,
    required String itemId,
  }) async {
    await _analytics.logShare(
      contentType: _clip(contentType, 40),
      itemId: _clip(itemId, 100),
      method: 'link',
    );
  }

  Future<void> logPremiumView({String source = 'unknown'}) async {
    await _analytics.logEvent(
      name: 'view_premium',
      parameters: {'source': _clip(source, 40)},
    );
  }

  Future<void> logOnboardingStep(String step) async {
    await _analytics.logEvent(
      name: 'onboarding_step',
      parameters: {'step': _clip(step, 40)},
    );
  }

  String _clip(String value, int maxLen) {
    if (value.length <= maxLen) return value;
    return value.substring(0, maxLen);
  }

  /// Fire-and-forget helper for UI code paths.
  void track(Future<void> Function() action) {
    unawaited(
      action().catchError((Object e, StackTrace st) {
        debugPrint('Analytics error: $e');
      }),
    );
  }
}
