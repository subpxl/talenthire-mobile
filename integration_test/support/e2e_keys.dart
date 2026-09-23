import 'package:flutter/foundation.dart';

/// Widget keys to add in `lib/` as tests are implemented.
///
/// INSTRUCTIONS: When coding a test, add the matching `Key(E2eKeys.xxx)` in the
/// production widget (login already has google sign-in). Prefer keys over
/// `find.text` to survive l10n changes.
@immutable
class E2eKeys {
  const E2eKeys._();

  // --- Auth (login_screen.dart: done for google) ---
  static const googleSignIn = Key('e2e_google_sign_in');
  static const emailSignInToggle = Key('e2e_email_sign_in_toggle');
  static const emailField = Key('e2e_email_field');
  static const passwordField = Key('e2e_password_field');
  static const emailSubmit = Key('e2e_email_submit');

  // --- Bottom nav (app_bottom_nav.dart) ---
  static const navHome = Key('e2e_nav_home');
  static const navCreators = Key('e2e_nav_creators');
  static const navJobs = Key('e2e_nav_jobs');
  static const navMessages = Key('e2e_nav_messages');
  static const navProfile = Key('e2e_nav_profile');

  // --- Jobs ---
  static const jobCardFirst = Key('e2e_job_card_first');
  static const jobDetailApply = Key('e2e_job_detail_apply');
  static const applySheetSubmit = Key('e2e_apply_sheet_submit');
  static const jobSave = Key('e2e_job_save');

  // --- Creators ---
  static const creatorCardFirst = Key('e2e_creator_card_first');

  // --- Messages ---
  static const messageThreadFirst = Key('e2e_message_thread_first');
  static const messageComposer = Key('e2e_message_composer');
  static const messageSend = Key('e2e_message_send');

  // --- Profile / settings ---
  static const profileSettings = Key('e2e_profile_settings');
  static const settingsPayment = Key('e2e_settings_payment');
  static const settingsLogout = Key('e2e_settings_logout');

  // --- Premium / payment ---
  static const premiumCta = Key('e2e_premium_cta');
  static const premiumPay = Key('e2e_premium_pay');

  // --- Onboarding ---
  static const onboardingContinue = Key('e2e_onboarding_continue');
  static const onboardingSkip = Key('e2e_onboarding_skip');
  static const onboardingMobileField = Key('e2e_onboarding_mobile');
}
