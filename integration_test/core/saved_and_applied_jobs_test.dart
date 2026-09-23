import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../pump_helpers.dart';
import '../support/app_launch.dart';
import '../support/auth_flow.dart';
import '../support/e2e_keys.dart';
import '../support/navigation.dart';
import '../support/test_config.dart';

/// Core test #6: Save job + verify saved list.
void main() {
  E2eAppLaunch.ensureBinding();

  testWidgets('save job and find in saved list', (WidgetTester tester) async {
    await E2eAppLaunch.coldStart(tester);
    await E2eAuthFlow.signInIfNeeded(tester);
    await E2eNavigation.tapJobs(tester);

    final found = await waitFor(
      tester,
      find.byKey(E2eKeys.jobCardFirst),
      timeout: E2eTestConfig.feedLoadTimeout,
    );
    if (!found) {
      fail('No jobs in staging feed — seed at least one published job.');
    }

    final cardTitle = find.descendant(
      of: find.byKey(E2eKeys.jobCardFirst),
      matching: find.byType(Text),
    );
    expect(cardTitle, findsWidgets);
    final jobTitle = tester.widget<Text>(cardTitle.first).data?.trim() ?? '';
    expect(jobTitle.isNotEmpty, isTrue);

    await tester.tap(find.byKey(E2eKeys.jobCardFirst));
    await pumpFor(tester, const Duration(seconds: 3));

    await tester.tap(find.byKey(E2eKeys.jobSave));
    await pumpFor(tester, const Duration(seconds: 2));

    await E2eNavigation.tapJobs(tester);
    await tester.tap(find.text('Saved'));
    await pumpFor(tester, const Duration(seconds: 3));

    expect(find.textContaining(jobTitle), findsWidgets);
  }, timeout: Timeout(E2eTestConfig.defaultTestTimeout));
}
