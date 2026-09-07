import 'package:bombay_casting/core/models/models.dart';

/// Free apply window (enforced server-side by `submitJobApplication`):
/// - Days 1–3 from account creation: 3 applications per calendar day
/// - 4th apply on the same day: daily-limit popup (tomorrow or pay ₹1)
/// - Day 4+: must subscribe (₹1 modal)
/// - Premium: unlimited
enum ApplyGate { allowed, dailyLimit, trialEnded }

class ApplyQuota {
  ApplyQuota._();

  static const trialDays = 3;
  static const freeAppliesPerDay = 3;

  static DateTime dateOnly(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static int trialDayNumber(DateTime createdAt, [DateTime? now]) {
    final start = dateOnly(createdAt);
    final today = dateOnly(now ?? DateTime.now());
    final day = today.difference(start).inDays + 1;
    return day < 1 ? 1 : day;
  }

  static int appliesToday(List<Application> applications, [DateTime? now]) {
    final today = dateOnly(now ?? DateTime.now());
    return applications.where((item) {
      return dateOnly(item.appliedAt) == today;
    }).length;
  }

  static ApplyGate evaluate({
    required bool isPremium,
    required DateTime? accountCreatedAt,
    required List<Application> applications,
    DateTime? now,
  }) {
    if (isPremium) return ApplyGate.allowed;
    final createdAt = accountCreatedAt ?? DateTime.now();
    if (trialDayNumber(createdAt, now) > trialDays) {
      return ApplyGate.trialEnded;
    }
    if (appliesToday(applications, now) >= freeAppliesPerDay) {
      return ApplyGate.dailyLimit;
    }
    return ApplyGate.allowed;
  }
}
