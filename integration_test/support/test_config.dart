/// E2E timeouts and `--dart-define` overrides.
///
/// Run example:
/// ```text
/// flutter test integration_test/core/... -d <deviceId> \
///   --dart-define=E2E_EMAIL=test@example.com \
///   --dart-define=E2E_PASSWORD=secret
/// ```
library;

class E2eTestConfig {
  E2eTestConfig._();

  /// After [main], splash + version gate + Firebase cold start.
  static const coldStartPump = Duration(seconds: 8);

  /// Wait for login screen or home if already signed in.
  static const loginScreenTimeout = Duration(seconds: 45);

  /// After tapping Google, time to complete native account picker.
  static const googleSignInTimeout = Duration(minutes: 2);

  /// Default per-test wall clock (see individual tests).
  static const defaultTestTimeout = Duration(minutes: 4);

  /// Lists / Firestore-backed screens.
  static const feedLoadTimeout = Duration(seconds: 30);

  /// Cashfree native sheet + return to app.
  static const paymentNativeTimeout = Duration(minutes: 3);

  /// Optional email login (not wired yet — set in [auth_flow.dart]).
  static String? get email {
    const v = String.fromEnvironment('E2E_EMAIL');
    return v.isEmpty ? null : v;
  }

  static String? get password {
    const v = String.fromEnvironment('E2E_PASSWORD');
    return v.isEmpty ? null : v;
  }

  /// Future: skip real Firebase auth in debug emulators only.
  static bool get bypassAuth {
    const v = String.fromEnvironment('E2E_BYPASS_AUTH');
    return v == 'true' || v == '1';
  }
}
