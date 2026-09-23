import 'package:bombay_casting/features/creators/screens/creators_screen.dart';
import 'package:bombay_casting/features/jobs/screens/home_screen.dart';
import 'package:bombay_casting/features/jobs/screens/jobs_screen.dart';
import 'package:bombay_casting/features/messaging/screens/message_list_screen.dart';
import 'package:bombay_casting/features/profile/screens/user_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/app_launch.dart';
import '../support/auth_flow.dart';
import '../support/navigation.dart';
import '../support/test_config.dart';

/// Core test #3: MainShell — all five tabs load without crash.
void main() {
  E2eAppLaunch.ensureBinding();

  testWidgets('all main tabs load', (WidgetTester tester) async {
    await E2eAppLaunch.coldStart(tester);
    await E2eAuthFlow.signInIfNeeded(tester);

    await E2eNavigation.tapHome(tester);
    expect(find.byType(HomeScreen), findsOneWidget);

    await E2eNavigation.tapCreators(tester);
    expect(find.byType(CreatorsScreen), findsOneWidget);

    await E2eNavigation.tapJobs(tester);
    expect(find.byType(JobsScreen), findsOneWidget);

    await E2eNavigation.tapMessages(tester);
    expect(find.byType(MessageListScreen), findsOneWidget);

    await E2eNavigation.tapProfile(tester);
    expect(find.byType(UserProfileScreen), findsOneWidget);

    expect(find.byType(MaterialApp), findsWidgets);
  }, timeout: Timeout(E2eTestConfig.defaultTestTimeout));
}
