import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../pump_helpers.dart';
import 'e2e_keys.dart';

/// Main shell bottom navigation.
///
/// INSTRUCTIONS: Add [E2eKeys.navHome] … [E2eKeys.navProfile] on each
/// [InkWell] in `lib/core/widgets/app_bottom_nav.dart`, then switch
/// implementations below from icon/label finders to `find.byKey`.
class E2eNavigation {
  E2eNavigation._();

  static Future<void> tapHome(WidgetTester tester) =>
      _tapTab(tester, E2eKeys.navHome, Icons.home_outlined, 'Home');

  static Future<void> tapCreators(WidgetTester tester) =>
      _tapTab(tester, E2eKeys.navCreators, Icons.people_outline, 'Creators');

  static Future<void> tapJobs(WidgetTester tester) =>
      _tapTab(tester, E2eKeys.navJobs, null, 'Jobs');

  static Future<void> tapMessages(WidgetTester tester) =>
      _tapTab(
        tester,
        E2eKeys.navMessages,
        Icons.chat_bubble_outline,
        'Messages',
      );

  static Future<void> tapProfile(WidgetTester tester) =>
      _tapTab(tester, E2eKeys.navProfile, Icons.person_outline, 'Profile');

  static Future<void> _tapTab(
    WidgetTester tester,
    Key key,
    IconData? fallbackIcon,
    String fallbackLabel,
  ) async {
    final byKey = find.byKey(key);
    if (tester.any(byKey)) {
      await tester.tap(byKey);
    } else if (fallbackIcon != null) {
      await tester.tap(find.byIcon(fallbackIcon));
    } else {
      await tester.tap(find.text(fallbackLabel));
    }
    await pumpFor(tester, const Duration(seconds: 2));
  }
}
