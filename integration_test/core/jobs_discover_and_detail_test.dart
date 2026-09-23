import 'package:bombay_casting/features/jobs/screens/job_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/app_launch.dart';
import '../support/auth_flow.dart';
import '../support/e2e_keys.dart';
import '../support/job_flow.dart';
import '../support/test_config.dart';

/// Core test #4: Jobs tab → job detail.
void main() {
  E2eAppLaunch.ensureBinding();

  testWidgets('open job from jobs tab', (WidgetTester tester) async {
    await E2eAppLaunch.coldStart(tester);
    await E2eAuthFlow.signInIfNeeded(tester);
    await E2eJobFlow.openFirstJobDetail(tester);

    expect(find.byType(JobDetailScreen), findsOneWidget);
    final applyOrApplied = find.byKey(E2eKeys.jobDetailApply);
    expect(
      applyOrApplied.evaluate().isNotEmpty ||
          find.text('Applied').evaluate().isNotEmpty,
      isTrue,
      reason: 'Expected Apply CTA or Applied state on job detail',
    );
  }, timeout: Timeout(E2eTestConfig.defaultTestTimeout));
}
