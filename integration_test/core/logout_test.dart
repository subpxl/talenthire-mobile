import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../pump_helpers.dart';
import '../support/app_launch.dart';
import '../support/auth_flow.dart';
import '../support/e2e_keys.dart';
import '../support/settings_flow.dart';
import '../support/test_config.dart';

/// Core test #10: Sign out → login screen.
///
/// Run last in a suite — clears device session.
void main() {
  E2eAppLaunch.ensureBinding();

  testWidgets('logout returns to login', (WidgetTester tester) async {
    await E2eAppLaunch.coldStart(tester);
    await E2eAuthFlow.signInIfNeeded(tester);
    await E2eSettingsFlow.openAccountSettings(tester);
    await E2eSettingsFlow.logoutFromAccountSettings(tester);

    await waitForOrFail(
      tester,
      find.byKey(E2eKeys.googleSignIn),
      timeout: const Duration(seconds: 45),
      message: 'Expected login screen after logout',
    );
  }, timeout: Timeout(E2eTestConfig.defaultTestTimeout));
}
