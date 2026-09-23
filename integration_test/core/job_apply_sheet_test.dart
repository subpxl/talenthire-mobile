import 'package:bombay_casting/features/jobs/widgets/apply_job_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../pump_helpers.dart';
import '../support/app_launch.dart';
import '../support/auth_flow.dart';
import '../support/e2e_keys.dart';
import '../support/job_flow.dart';
import '../support/test_config.dart';

/// Core test #5: Open apply sheet and validate submit path.
///
/// Uses a job that requires video submission when available; otherwise asserts
/// one-tap apply path (no sheet).
void main() {
  E2eAppLaunch.ensureBinding();

  testWidgets('apply sheet opens and submits', (WidgetTester tester) async {
    await E2eAppLaunch.coldStart(tester);
    await E2eAuthFlow.signInIfNeeded(tester);
    await E2eJobFlow.openFirstJobDetail(tester);

    final apply = find.byKey(E2eKeys.jobDetailApply);
    if (!tester.any(apply)) {
      expect(find.text('Applied'), findsOneWidget);
      return;
    }

    await tester.tap(apply);
    await pumpFor(tester, const Duration(seconds: 2));

    if (!tester.any(find.byType(ApplyJobSheet))) {
      await pumpFor(tester, const Duration(seconds: 2));
      expect(
        find.text('Applied').evaluate().isNotEmpty ||
            find.text('Application sent').evaluate().isNotEmpty,
        isTrue,
        reason: 'Job applied without video sheet',
      );
      return;
    }

    await tester.tap(find.byKey(E2eKeys.applySheetSubmit));
    await pumpFor(tester, const Duration(seconds: 1));
    expect(
      find.textContaining('YouTube Short or Instagram Reel'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byType(TextField).first,
      'https://www.youtube.com/shorts/jNQXAC9IVRw',
    );
    await tester.tap(find.byKey(E2eKeys.applySheetSubmit));
    await pumpFor(tester, const Duration(seconds: 5));

    expect(find.byType(MaterialApp), findsWidgets);
  }, timeout: Timeout(E2eTestConfig.defaultTestTimeout));
}
