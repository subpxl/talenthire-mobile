import 'package:bombay_casting/features/messaging/screens/message_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../pump_helpers.dart';
import '../support/app_launch.dart';
import '../support/auth_flow.dart';
import '../support/e2e_keys.dart';
import '../support/navigation.dart';
import '../support/test_config.dart';

/// Core test #8: Messages list + thread open.
void main() {
  E2eAppLaunch.ensureBinding();

  testWidgets('messages list and thread open', (WidgetTester tester) async {
    await E2eAppLaunch.coldStart(tester);
    await E2eAuthFlow.signInIfNeeded(tester);
    await E2eNavigation.tapMessages(tester);
    await pumpFor(tester, const Duration(seconds: 3));

    final hasThread = await waitFor(
      tester,
      find.byKey(E2eKeys.messageThreadFirst),
      timeout: E2eTestConfig.feedLoadTimeout,
    );
    if (!hasThread) {
      fail(
        'No seeded conversation — sign in as a user with messages or seed Firestore.',
      );
    }

    await tester.tap(find.byKey(E2eKeys.messageThreadFirst));
    await pumpFor(tester, const Duration(seconds: 3));
    expect(find.byType(MessageDetailScreen), findsOneWidget);
    expect(find.byKey(E2eKeys.messageComposer), findsOneWidget);
  }, timeout: Timeout(E2eTestConfig.defaultTestTimeout));
}
