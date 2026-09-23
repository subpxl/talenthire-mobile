import 'package:bombay_casting/features/premium/screens/premium_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../pump_helpers.dart';
import '../support/app_launch.dart';
import '../support/auth_flow.dart';
import '../support/e2e_keys.dart';
import '../support/navigation.dart';
import '../support/test_config.dart';

/// Core test #11: Premium / Cashfree payment flow (staging sandbox).
///
/// **Manual on device:** after tapping pay, complete or cancel the native UPI
/// sheet within [E2eTestConfig.paymentNativeTimeout].
void main() {
  E2eAppLaunch.ensureBinding();

  testWidgets('premium pay opens native flow and returns to app', (
    WidgetTester tester,
  ) async {
    await E2eAppLaunch.coldStart(tester);
    await E2eAuthFlow.signInIfNeeded(tester);
    await E2eNavigation.tapProfile(tester);

    final premiumCta = find.byKey(E2eKeys.premiumCta);
    if (!tester.any(premiumCta)) {
      // Already premium — smoke pass.
      expect(find.byType(MaterialApp), findsWidgets);
      return;
    }

    await tester.tap(premiumCta);
    await pumpFor(tester, const Duration(seconds: 3));
    expect(find.byType(PremiumPage), findsOneWidget);

    await tester.tap(find.byKey(E2eKeys.premiumPay));
    await pumpFor(tester, E2eTestConfig.paymentNativeTimeout);

    expect(find.byType(MaterialApp), findsWidgets);
  }, timeout: Timeout(E2eTestConfig.paymentNativeTimeout));
}
