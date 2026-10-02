import 'package:bombay_casting/core/models/models.dart';

/// Free apply window (enforced server-side by `submitJobApplication`):
/// - Days 1–3 from account creation: 1 application per IST calendar day
/// - Day 4+ without mandate: must subscribe (paywall)
/// - Active UPI mandate: 5 applications per IST calendar day
enum ApplyGate { allowed, dailyLimit, trialEnded }

class ApplyQuota {
  ApplyQuota._();

  static const trialDays = 3;
  static const freeAppliesPerDay = 1;
  static const mandateAppliesPerDay = 5;

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
    required bool hasActiveMandate,
    required DateTime? accountCreatedAt,
    required List<Application> applications,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final todayCount = appliesToday(applications, clock);

    if (hasActiveMandate) {
      if (todayCount >= mandateAppliesPerDay) {
        return ApplyGate.dailyLimit;
      }
      return ApplyGate.allowed;
    }

    final createdAt = accountCreatedAt ?? clock;
    if (trialDayNumber(createdAt, clock) > trialDays) {
      return ApplyGate.trialEnded;
    }
    if (todayCount >= freeAppliesPerDay) {
      return ApplyGate.dailyLimit;
    }
    return ApplyGate.allowed;
  }
}
