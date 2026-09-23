import 'package:bombay_casting/features/profile/screens/account_settings_screen.dart';
import 'package:bombay_casting/features/profile/screens/user_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../pump_helpers.dart';
import '../support/app_launch.dart';
import '../support/auth_flow.dart';
import '../support/settings_flow.dart';
import '../support/test_config.dart';

/// Core test #9: Profile → account settings smoke.
void main() {
  E2eAppLaunch.ensureBinding();

  testWidgets('profile and settings screens open', (WidgetTester tester) async {
    await E2eAppLaunch.coldStart(tester);
    await E2eAuthFlow.signInIfNeeded(tester);
    await E2eSettingsFlow.openAccountSettings(tester);

    expect(find.byType(AccountSettingsScreen), findsOneWidget);
    expect(find.text('Profile & Account'), findsOneWidget);

    await tester.pageBack();
    await pumpFor(tester, const Duration(seconds: 2));
    expect(find.byType(UserProfileScreen), findsOneWidget);
  }, timeout: Timeout(E2eTestConfig.defaultTestTimeout));
}
