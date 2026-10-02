import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:play_install_referrer/play_install_referrer.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Captures the Play Install Referrer on first launch and exposes the parsed
/// affiliate code for first-time user registration only.
class ReferralService {
  ReferralService._();

  static const _pendingCodeKey = 'pending_referral_code';
  static const _pendingJobIdKey = 'pending_install_job_id';
  static const _fetchAttemptedKey = 'referral_fetch_attempted';

  /// Parses `ref_code` from the raw Play Install Referrer string.
  /// Handles both encoded (`ref_code%3DABC`) and plain (`ref_code=ABC`) forms.
  @visibleForTesting
  /// Parses `utm_content=job_{id}` (or `download_app_job_{id}`) from Play install referrer.
  @visibleForTesting
  static String? parseDeferredJobId(String? rawReferrer) {
    if (rawReferrer == null || rawReferrer.trim().isEmpty) return null;

    final decoded = Uri.decodeComponent(rawReferrer.trim());
    final match = RegExp(
      r'(?:^|[?&])utm_content=(?:job_|download_app_job_)([^&]+)',
      caseSensitive: false,
    ).firstMatch(decoded);
    if (match == null) return null;

    final jobId = match.group(1)?.trim();
    if (jobId == null || jobId.isEmpty) return null;
    return jobId;
  }

  static String? parseReferralCode(String? rawReferrer) {
    if (rawReferrer == null || rawReferrer.trim().isEmpty) return null;

    final decoded = Uri.decodeComponent(rawReferrer.trim());
    final match = RegExp(r'(?:^|[?&])ref_code=([^&]+)', caseSensitive: false)
        .firstMatch(decoded);
    if (match == null) return null;

    final code = match.group(1)?.trim();
    if (code == null || code.isEmpty) return null;
    return code;
  }

  /// Reads the Play Install Referrer once per install and persists any parsed
  /// affiliate code locally until it is consumed at first registration.
  static Future<void> captureInstallReferrer() async {
    if (!Platform.isAndroid) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_fetchAttemptedKey) == true) return;

    try {
      final details = await PlayInstallReferrer.installReferrer;
      final rawReferrer = details.installReferrer;
      final code = parseReferralCode(rawReferrer);
      if (code != null) {
        await prefs.setString(_pendingCodeKey, code);
      }
      final jobId = parseDeferredJobId(rawReferrer);
      if (jobId != null) {
        await prefs.setString(_pendingJobIdKey, jobId);
      }
    } catch (error) {
      debugPrint('Install referrer capture skipped: $error');
    } finally {
      await prefs.setBool(_fetchAttemptedKey, true);
    }
  }

  /// Returns the locally stored affiliate code, if any. Does not consume it.
  static Future<String?> pendingReferralCode() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_pendingCodeKey);
    if (code == null || code.trim().isEmpty) return null;
    return code.trim();
  }

  /// Clears the stored affiliate code after it has been written to Firestore.
  static Future<void> clearPendingReferralCode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingCodeKey);
  }

  static Future<String?> pendingInstallJobId() async {
    final prefs = await SharedPreferences.getInstance();
    final jobId = prefs.getString(_pendingJobIdKey);
    if (jobId == null || jobId.trim().isEmpty) return null;
    return jobId.trim();
  }

  static Future<void> clearPendingInstallJobId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingJobIdKey);
  }
}
