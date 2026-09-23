import 'package:bombay_casting/features/creators/screens/creator_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../pump_helpers.dart';
import '../support/app_launch.dart';
import '../support/auth_flow.dart';
import '../support/e2e_keys.dart';
import '../support/navigation.dart';
import '../support/test_config.dart';

/// Core test #7: Creators tab → creator profile.
void main() {
  E2eAppLaunch.ensureBinding();

  testWidgets('open creator profile from feed', (WidgetTester tester) async {
    await E2eAppLaunch.coldStart(tester);
    await E2eAuthFlow.signInIfNeeded(tester);
    await E2eNavigation.tapCreators(tester);

    final found = await waitFor(
      tester,
      find.byKey(E2eKeys.creatorCardFirst),
      timeout: E2eTestConfig.feedLoadTimeout,
    );
    if (!found) {
      fail('No creators in staging feed — seed at least one creator.');
    }

    await tester.tap(find.byKey(E2eKeys.creatorCardFirst));
    await pumpFor(tester, const Duration(seconds: 3));

    expect(find.byType(CreatorProfileScreen), findsOneWidget);
  }, timeout: Timeout(E2eTestConfig.defaultTestTimeout));
}
