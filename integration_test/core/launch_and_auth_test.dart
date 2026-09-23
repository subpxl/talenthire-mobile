import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/app_launch.dart';
import '../support/auth_flow.dart';
import '../support/test_config.dart';

/// Core test #1–2: cold start, version gate, sign-in.
///
/// Persona: any (logged out → Google; logged in → skip tap).
/// Pass: MaterialApp visible; not stuck on login with Google button still showing.
void main() {
  final binding = E2eAppLaunch.ensureBinding();

  testWidgets('launch and sign in if needed', (WidgetTester tester) async {
    await E2eAppLaunch.coldStart(tester);
    await E2eAuthFlow.signInIfNeeded(tester, binding: binding);
    expect(find.byType(MaterialApp), findsWidgets);
  }, timeout: Timeout(E2eTestConfig.defaultTestTimeout));
}
