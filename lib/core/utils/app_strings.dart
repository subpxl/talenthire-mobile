import 'package:flutter/material.dart';
import 'package:bombay_casting/l10n/app_localizations.dart';

extension AppStringsExt on BuildContext {
  AppLocalizations? get _l10n => AppLocalizations.of(this);

  // Auth & Onboarding Strings
  String get appName => _l10n?.bombayCastingCompany ?? 'Bombay Casting Company';
  String get createCreatorAccount => _l10n?.createAnAccount ?? 'Create your creator account';
  String get signInToFindCollabs => 'Sign in to find collaborations';
  String get loginHeadline => 'Find your next collab';
  String get loginSubtitle => 'Sign in to browse jobs and apply to brands';
  String get continueWithGoogle => _l10n?.continueWithGoogle ?? 'Continue with Google';
  String get loginWithGoogle => 'Login with Google';
  String get continueWithEmail => _l10n?.continueWithEmail ?? 'Continue with Email';
  String get loginWithEmailPassword => 'Login with email & password';
  String get loginWithEmail => 'Login with Email';
  String get or => _l10n?.or ?? 'or';
  String get creatorNameLabel => 'Creator name';
  String get enterYourName => 'Enter your name';
  String get emailLabel => 'Email';
  String get enterValidEmail => 'Enter a valid email';
  String get passwordLabel => 'Password';
  String get passwordMinLength => 'Password must be at least 6 characters';
  String get showPassword => 'Show password';
  String get hidePassword => 'Hide password';
  String get creatingAccount => 'Creating account…';
  String get signingIn => 'Signing in…';
  String get createAccountBtn => _l10n?.createAnAccount ?? 'Create account';
  String get signInBtn => _l10n?.logIn ?? 'Sign in';
  String get alreadyHaveAccount => _l10n?.alreadyHaveAnAccount ?? 'Already have an account?';
  String get newHere => _l10n?.newHere ?? 'New here?';
  String get logInAction => _l10n?.logIn ?? 'Log in';
  String get createAccountAction => _l10n?.createAnAccount ?? 'Create an account';

  // Splash Screen Strings
  String get loadingSplash => 'Loading...';

  // General Error / Feedback Strings
  String get genericError => 'An error occurred';
}
