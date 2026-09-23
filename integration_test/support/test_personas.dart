/// Firebase / staging test accounts (document only — do not commit secrets).
///
/// INSTRUCTIONS:
/// 1. Create users in Firebase Auth + Firestore to match these personas.
/// 2. Use Google accounts or email/password per persona.
/// 3. Reset onboarding via script or Firestore before "fresh" runs.
library;

enum E2ePersona {
  /// Onboarding complete; lands on MainShell. Default for most core tests.
  complete,

  /// Stops at FirstLoginStep.mobile — for onboarding_happy_path_test.
  freshOnboarding,

  /// Has at least one conversation document — for messages_smoke_test.
  withConversation,

  /// UserRole.admin — optional admin smoke (not in core suite).
  admin,
}

class E2ePersonas {
  E2ePersonas._();

  /// Which Google account or email to use on device (manual mapping).
  static String description(E2ePersona persona) => switch (persona) {
        E2ePersona.complete =>
          'Firestore: onboarding done. Use dedicated test Google account.',
        E2ePersona.freshOnboarding =>
          'New user or reset firstLoginStep to mobile.',
        E2ePersona.withConversation =>
          'Seed messages/{id} linked to test uid.',
        E2ePersona.admin =>
          'user.role == admin in Firestore.',
      };
}
