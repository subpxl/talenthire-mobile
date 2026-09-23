import 'package:bombay_casting/features/onboarding/screens/enter_mobile_screen.dart';
import 'package:bombay_casting/features/onboarding/screens/onboarding_category_screen.dart';
import 'package:bombay_casting/features/onboarding/screens/onboarding_creator_screen.dart';
import 'package:bombay_casting/features/onboarding/screens/onboarding_photo_screen.dart';
import 'package:bombay_casting/features/onboarding/screens/onboarding_social_screen.dart';
import 'package:bombay_casting/features/onboarding/screens/select_language_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../pump_helpers.dart';
import 'e2e_keys.dart';
import 'test_config.dart';

/// Steps through first-login onboarding when visible; no-op if main shell already shown.
class E2eOnboardingFlow {
  E2eOnboardingFlow._();

  static const _testMobile = '9876543210';

  static Future<void> completeIfNeeded(WidgetTester tester) async {
    final onShell = await waitFor(
      tester,
      find.byKey(E2eKeys.navHome),
      timeout: const Duration(seconds: 8),
    );
    if (onShell) return;

    final deadline = DateTime.now().add(const Duration(minutes: 6));
    while (DateTime.now().isBefore(deadline)) {
      if (tester.any(find.byKey(E2eKeys.navHome))) return;

      if (tester.any(find.byType(EnterMobileScreen))) {
        await _completeMobile(tester);
        continue;
      }
      if (tester.any(find.byType(LanguageScreen))) {
        await _tapContinue(tester);
        continue;
      }
      if (tester.any(find.byType(OnboardingPhotoScreen))) {
        await _tapSkipIfPresent(tester);
        continue;
      }
      if (tester.any(find.byType(OnboardingCategoryScreen))) {
        await _completeCategoryOrSkip(tester);
        continue;
      }
      if (tester.any(find.byType(OnboardingCreatorScreen))) {
        await _tapSkipIfPresent(tester);
        continue;
      }
      if (tester.any(find.byType(OnboardingSocialScreen))) {
        await _completeSocialOrSkip(tester);
        continue;
      }

      await pumpFor(tester, const Duration(milliseconds: 500));
    }

    await waitForOrFail(
      tester,
      find.byKey(E2eKeys.navHome),
      timeout: E2eTestConfig.feedLoadTimeout,
      message:
          'Onboarding did not reach main shell — use a fresh Google account or reset firstLoginStep.',
    );
  }

  static Future<void> _completeMobile(WidgetTester tester) async {
    await waitForOrFail(tester, find.byKey(E2eKeys.onboardingMobileField));
    await tester.enterText(
      find.byKey(E2eKeys.onboardingMobileField),
      _testMobile,
    );
    await _tapContinue(tester);
    await pumpFor(tester, const Duration(seconds: 3));
  }

  static Future<void> _completeCategoryOrSkip(WidgetTester tester) async {
    final actor = find.text('Actor');
    if (tester.any(actor)) {
      await tester.tap(actor);
      await pumpFor(tester, const Duration(milliseconds: 400));
    }
    final selectAge = find.text('Select your age');
    if (tester.any(selectAge)) {
      await tester.tap(selectAge);
      await pumpFor(tester, const Duration(seconds: 1));
      final age18 = find.text('18');
      if (tester.any(age18)) {
        await tester.tap(age18);
        await pumpFor(tester, const Duration(milliseconds: 400));
      }
    }
    if (tester.any(find.byKey(E2eKeys.onboardingContinue))) {
      await _tapContinue(tester);
    } else {
      await _tapSkipIfPresent(tester);
    }
    await pumpFor(tester, const Duration(seconds: 3));
  }

  static Future<void> _completeSocialOrSkip(WidgetTester tester) async {
    final instagram = find.byType(TextField).first;
    if (tester.any(instagram)) {
      await tester.enterText(instagram, 'https://instagram.com/example');
    }
    if (tester.any(find.byKey(E2eKeys.onboardingContinue))) {
      await _tapContinue(tester);
    } else {
      await _tapSkipIfPresent(tester);
    }
    await pumpFor(tester, const Duration(seconds: 4));
  }

  static Future<void> _tapContinue(WidgetTester tester) async {
    await waitForOrFail(tester, find.byKey(E2eKeys.onboardingContinue));
    await tester.tap(find.byKey(E2eKeys.onboardingContinue));
    await pumpFor(tester, const Duration(seconds: 2));
  }

  static Future<void> _tapSkipIfPresent(WidgetTester tester) async {
    final skip = find.byKey(E2eKeys.onboardingSkip);
    if (tester.any(skip)) {
      await tester.tap(skip);
      await pumpFor(tester, const Duration(seconds: 2));
    }
  }
}
