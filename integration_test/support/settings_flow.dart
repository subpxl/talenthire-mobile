import 'package:bombay_casting/features/profile/screens/account_settings_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../pump_helpers.dart';
import 'e2e_keys.dart';
import 'navigation.dart';

/// Profile → account settings (and optional logout).
class E2eSettingsFlow {
  E2eSettingsFlow._();

  static Future<void> openAccountSettings(WidgetTester tester) async {
    await E2eNavigation.tapProfile(tester);
    await waitForOrFail(
      tester,
      find.byKey(E2eKeys.profileSettings),
      timeout: const Duration(seconds: 20),
      message: 'Profile settings entry not found',
    );
    await tester.tap(find.byKey(E2eKeys.profileSettings));
    await pumpFor(tester, const Duration(seconds: 2));
    await waitForOrFail(
      tester,
      find.byType(AccountSettingsScreen),
      timeout: const Duration(seconds: 15),
      message: 'Account settings screen did not open',
    );
  }

  static Future<void> logoutFromAccountSettings(WidgetTester tester) async {
    await waitForOrFail(
      tester,
      find.byKey(E2eKeys.settingsLogout),
      timeout: const Duration(seconds: 15),
      message: 'Logout button not found in account settings',
    );
    await tester.tap(find.byKey(E2eKeys.settingsLogout));
    await pumpFor(tester, const Duration(seconds: 4));
  }
}
