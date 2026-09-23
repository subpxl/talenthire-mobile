import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/app_launch.dart';
import '../support/auth_flow.dart';
import '../support/e2e_keys.dart';
import '../support/onboarding_flow.dart';
import '../pump_helpers.dart';

/// Core test #12: Fresh user onboarding → MainShell (long-running).
///
/// Use a **fresh** Google account or reset `firstLoginStep` in Firestore.
/// If the device is already onboarded, the test verifies main shell only.
void main() {
  E2eAppLaunch.ensureBinding();

  testWidgets('complete onboarding to main shell', (WidgetTester tester) async {
    await E2eAppLaunch.coldStart(tester);
    await E2eAuthFlow.signInIfNeeded(tester);
    await E2eOnboardingFlow.completeIfNeeded(tester);
    await pumpFor(tester, const Duration(seconds: 2));

    expect(find.byKey(E2eKeys.navHome), findsOneWidget);
    expect(find.byType(MaterialApp), findsWidgets);
  }, timeout: const Timeout(Duration(minutes: 8)));
}
