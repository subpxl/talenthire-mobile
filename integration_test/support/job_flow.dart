import 'package:bombay_casting/features/jobs/screens/job_detail_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../pump_helpers.dart';
import 'e2e_keys.dart';
import 'navigation.dart';
import 'test_config.dart';

/// Jobs tab → first listing → detail screen.
class E2eJobFlow {
  E2eJobFlow._();

  static Future<void> openFirstJobDetail(WidgetTester tester) async {
    await E2eNavigation.tapJobs(tester);

    final found = await waitFor(
      tester,
      find.byKey(E2eKeys.jobCardFirst),
      timeout: E2eTestConfig.feedLoadTimeout,
    );
    if (!found) {
      fail('No jobs in staging feed — seed at least one published job.');
    }

    await tester.tap(find.byKey(E2eKeys.jobCardFirst));
    await pumpFor(tester, const Duration(seconds: 3));

    await waitForOrFail(
      tester,
      find.byType(JobDetailScreen),
      timeout: const Duration(seconds: 15),
      message: 'Job detail screen did not open',
    );
  }
}
