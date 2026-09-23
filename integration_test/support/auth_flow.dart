import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../pump_helpers.dart';
import 'e2e_keys.dart';
import 'test_config.dart';

/// Sign-in helpers for device E2E.
///
/// INSTRUCTIONS (future):
/// - If [E2eTestConfig.email] / password set → email login via [E2eKeys].
/// - If [E2eTestConfig.bypassAuth] → only when app exposes debug hook (not yet).
class E2eAuthFlow {
  E2eAuthFlow._();

  /// Ensures user is past login (home tab or onboarding). Taps Google if needed.
  ///
  /// Native Google account picker: operator must choose account on device.
  static Future<void> signInIfNeeded(
    WidgetTester tester, {
    IntegrationTestWidgetsFlutterBinding? binding,
  }) async {
    binding?.reportData ??= <String, String>{};

    final googleButton = find.byKey(E2eKeys.googleSignIn);
    final homeNav = find.byIcon(Icons.home_outlined);

    if (tester.any(homeNav) && !tester.any(googleButton)) {
      binding?.reportData?['e2e_auth'] = 'already_signed_in';
      return;
    }

    // TODO: email/password path when keys + AppState login exist in test.
    if (E2eTestConfig.email != null && E2eTestConfig.password != null) {
      binding?.reportData?['e2e_auth'] = 'email_login_not_implemented';
    }

    final onLogin = await waitFor(
      tester,
      googleButton,
      timeout: E2eTestConfig.loginScreenTimeout,
    );

    if (!onLogin) {
      if (tester.any(homeNav) || !tester.any(googleButton)) {
        binding?.reportData?['e2e_auth'] = 'past_login_no_google_button';
        return;
      }
      fail('Login screen not found within ${E2eTestConfig.loginScreenTimeout}');
    }

    await tester.ensureVisible(googleButton);
    await tester.tap(googleButton);
    await tester.pump();
    binding?.reportData?['e2e_auth'] = 'waiting_for_google_sign_in';

    final deadline = DateTime.now().add(E2eTestConfig.googleSignInTimeout);
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 250));
      if (tester.any(homeNav) || !tester.any(googleButton)) {
        binding?.reportData?['e2e_auth'] = tester.any(homeNav)
            ? 'signed_in_home'
            : 'signed_in_post_login';
        return;
      }
    }

    fail(
      'Still on login after tapping Google. Pick your account on the device '
      'within ${E2eTestConfig.googleSignInTimeout.inMinutes} minutes.',
    );
  }
}
