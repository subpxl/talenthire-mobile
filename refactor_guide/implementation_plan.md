# Feature-First Architecture Refactor — Bombay Casting

Refactor the current layer-based architecture (`screens/`, `providers/`, `services/`, `models/`, `data/`, `widgets/`) into a **feature-first** structure where each feature is a self-contained vertical slice with its own models, providers, screens, and widgets. This makes the codebase significantly easier to debug, test, and extend independently.

## User Review Required

> [!IMPORTANT]
> **The app will be running on your device during this refactor.** I'll move files and update imports in a coordinated way, but you'll need to **hot-restart** (press `R` in the terminal) after the refactor is complete — hot reload won't pick up the file-level restructuring.

> [!WARNING]
> **No behavioral changes.** This is a pure structural refactor. Every screen, every provider, every model stays functionally identical. No logic is added, removed, or modified.

## Open Questions

> [!IMPORTANT]
> **Question 1:** The `data/conversations.dart` file defines `ChatMessage` and `ConversationThread` models. Currently messaging is static/mock data. Should I keep messaging as its own feature (`features/messaging/`) anticipating future Firestore integration, or fold it into a simpler `core/` location? **I'm planning to give it its own feature** so it's ready when you add real chat.

> [!IMPORTANT]
> **Question 2:** `screens/message_list_screen.dart` and `screens/messageslistscreen.dart` appear to be two different screens both used in `MainShell` (tabs 3 and 4). Are both intentional (one for job messages, one for chat), or is one legacy? **I'll keep both** and place them under `features/messaging/`.

---

## Current Structure (layer-based)

```
lib/
├── main.dart
├── firebase_options.dart
├── data/               ← mixed models + static data
├── models/             ← 1 giant models.dart (724 lines)
├── navigation/         ← route helpers
├── providers/          ← AppState (god-object, 433 lines) + JobFeed
├── screens/            ← 18 screens + 1 subdirectory
│   └── userprofilepage/ ← 8 profile edit forms
├── services/           ← auth, storage, cache
├── theme/              ← design tokens
├── utils/              ← legal links
└── widgets/            ← 7 shared widgets
```

### Key Problems
- **`AppState` is a 433-line god object** — auth, profile, jobs, applications, creators, photos all in one `ChangeNotifier`
- **`models.dart` is 724 lines** — User, Profile, Job, Application + all helpers in one file
- **Flat screens folder** — 18+ screens with no grouping; unrelated features share a directory
- **Hard to test** — no way to test auth without also constructing job feed, and vice versa
- **Hard to extend** — adding a feature requires touching many unrelated directories

---

## Proposed Structure (feature-first)

```
lib/
├── main.dart                          (simplified bootstrap)
├── firebase_options.dart              (unchanged)
│
├── core/                              ← shared code, used by 2+ features
│   ├── models/
│   │   ├── user_model.dart            (User class, UserRole, extracted from models.dart)
│   │   ├── profile_model.dart         (Profile, SocialPlatformMetric, SubscriptionStatus…)
│   │   └── models.dart                (barrel: exports all core models + shared helpers)
│   ├── services/
│   │   ├── auth_service.dart          (unchanged)
│   │   └── storage_service.dart       (unchanged)
│   ├── navigation/
│   │   ├── app_navigation.dart        (updated imports)
│   │   └── app_page_route.dart        (unchanged)
│   ├── theme/
│   │   └── app_theme.dart             (unchanged)
│   ├── utils/
│   │   └── legal_links.dart           (unchanged)
│   └── widgets/                       ← shared UI components
│       ├── app_bottom_nav.dart
│       ├── app_screen_layout.dart
│       ├── app_tab_bar.dart
│       ├── option_picker.dart
│       ├── placeholder_avatar.dart
│       ├── profile_list_tile.dart
│       └── promo_banner.dart
│
├── features/
│   ├── auth/                          ← login/register/splash
│   │   ├── screens/
│   │   │   ├── login_screen.dart
│   │   │   └── splash_screen.dart
│   │   └── providers/
│   │       └── auth_provider.dart     (auth-only slice of AppState)
│   │
│   ├── jobs/                          ← job feed, detail, filter, saved, apply
│   │   ├── models/
│   │   │   ├── job_model.dart         (Job, enums, helpers — extracted from models.dart)
│   │   │   ├── application_model.dart (Application, ApplicationStatus)
│   │   │   ├── job_listing.dart       (JobListing, HomeJobFilter — from data/job_assets.dart)
│   │   │   └── job_assets.dart        (JobAssets path helper)
│   │   ├── providers/
│   │   │   ├── job_feed_provider.dart (renamed from providers/job_feed.dart)
│   │   │   └── job_state.dart         (jobs/applications/saved slice of AppState)
│   │   ├── screens/
│   │   │   ├── home_screen.dart       (renamed from homepage.dart)
│   │   │   ├── job_detail_screen.dart
│   │   │   ├── shortlisted_screen.dart
│   │   │   └── preference_filter_screen.dart
│   │   └── services/
│   │       └── job_cache_service.dart
│   │
│   ├── creators/                      ← creator discovery + profile viewing
│   │   ├── models/
│   │   │   └── creator_profile.dart   (from data/creator_profiles.dart)
│   │   └── screens/
│   │       ├── creators_screen.dart
│   │       └── creator_profile_screen.dart
│   │
│   ├── messaging/                     ← conversations + chat
│   │   ├── models/
│   │   │   └── conversation.dart      (from data/conversations.dart)
│   │   └── screens/
│   │       ├── messages_list_screen.dart
│   │       └── message_detail_screen.dart
│   │
│   ├── profile/                       ← user's own profile + edit forms
│   │   ├── screens/
│   │   │   ├── user_profile_screen.dart
│   │   │   ├── account_settings_screen.dart
│   │   │   ├── edit_profile_view_screen.dart
│   │   │   ├── edit_personal_details_form.dart
│   │   │   ├── edit_preferences_form.dart
│   │   │   ├── edit_occupation_screen.dart
│   │   │   ├── edit_content_form.dart
│   │   │   ├── edit_rates_form.dart
│   │   │   ├── edit_social_form.dart
│   │   │   └── edit_verification_form.dart
│   │   └── providers/
│   │       └── profile_provider.dart  (profile/photo slice of AppState)
│   │
│   ├── premium/                       ← subscription / paywall
│   │   └── screens/
│   │       ├── premium_screen.dart
│   │       └── payment_in_progress_screen.dart
│   │
│   └── onboarding/                    ← language selection, get help
│       └── screens/
│           ├── select_language_screen.dart
│           └── get_help_screen.dart
│
├── app/                               ← app shell (wires features together)
│   ├── app.dart                       (MyApp widget — MaterialApp + auth gate)
│   ├── main_shell.dart                (tab bar shell — PageView + BottomNav)
│   └── app_state.dart                 (thin facade that composes feature providers)
```

---

## Proposed Changes

### 1. Core — Shared Models (split `models.dart`)

#### [NEW] [`user_model.dart`](file:///c:/Users/shubh/OneDrive/Desktop/fsap/mobile/lib/core/models/user_model.dart)
Extract `User`, `UserRole`, and shared parsing helpers (`_enumFromString`, `parseFlexibleDate`, `_mapFrom`, `_stringList`) from `models.dart`.

#### [NEW] [`profile_model.dart`](file:///c:/Users/shubh/OneDrive/Desktop/fsap/mobile/lib/core/models/profile_model.dart)
Extract `Profile`, `SocialPlatformMetric`, `AccountStatus`, `SubscriptionStatus` from `models.dart`.

#### [NEW] [`models.dart`](file:///c:/Users/shubh/OneDrive/Desktop/fsap/mobile/lib/core/models/models.dart)
Barrel file that re-exports `user_model.dart` + `profile_model.dart` + job/application models so existing `import 'models/models.dart'` paths can be updated to `import 'core/models/models.dart'` with zero breakage.

#### [DELETE] [`models.dart`](file:///c:/Users/shubh/OneDrive/Desktop/fsap/mobile/lib/models/models.dart)
Replaced by the split files above.

---

### 2. Core — Services, Navigation, Theme, Utils, Widgets

#### [MODIFY] All files in `services/`, `navigation/`, `theme/`, `utils/`, `widgets/`
Move to `core/` subdirectories. Update import paths only — no logic changes.

#### [DELETE] Old directories: `services/`, `navigation/`, `theme/`, `utils/`, `widgets/`, `data/`, `models/`

---

### 3. Feature: Auth

#### [MODIFY] [`login_screen.dart`](file:///c:/Users/shubh/OneDrive/Desktop/fsap/mobile/lib/screens/login_screen.dart) → `features/auth/screens/login_screen.dart`
Move + update imports.

#### [MODIFY] [`splash_screen.dart`](file:///c:/Users/shubh/OneDrive/Desktop/fsap/mobile/lib/screens/splash_screen.dart) → `features/auth/screens/splash_screen.dart`
Move + update imports.

#### [NEW] [`auth_provider.dart`](file:///c:/Users/shubh/OneDrive/Desktop/fsap/mobile/lib/features/auth/providers/auth_provider.dart)
Extract auth-specific state from `AppState`: `loginWithGoogle()`, `loginWithEmail()`, `registerWithEmail()`, `logout()`, `lastAuthError`, `isAuthenticated`, `isLoading`. Owns `AuthService`.

---

### 4. Feature: Jobs

#### [NEW] [`job_model.dart`](file:///c:/Users/shubh/OneDrive/Desktop/fsap/mobile/lib/features/jobs/models/job_model.dart)
Extract `Job`, `JobStatus`, `LocationType`, and all job-specific helpers from `models.dart`.

#### [NEW] [`application_model.dart`](file:///c:/Users/shubh/OneDrive/Desktop/fsap/mobile/lib/features/jobs/models/application_model.dart)
Extract `Application`, `ApplicationStatus` from `models.dart`.

#### [MODIFY] [`job_assets.dart`](file:///c:/Users/shubh/OneDrive/Desktop/fsap/mobile/lib/data/job_assets.dart) → `features/jobs/models/job_listing.dart` + `features/jobs/models/job_assets.dart`
Split: `JobAssets` (path helper) into its own file; `JobListing`, `HomeJobFilter`, `listingsForJobs()` into `job_listing.dart`.

#### [NEW] [`job_state.dart`](file:///c:/Users/shubh/OneDrive/Desktop/fsap/mobile/lib/features/jobs/providers/job_state.dart)
Extract jobs/applications/saved-jobs state from `AppState`: `applyToJob()`, `toggleSavedJob()`, `refreshJobs()`, `savedJobs`, `applications`, etc. Owns `JobFeed` and `JobCacheService`.

#### [MODIFY] All job screens → `features/jobs/screens/`
Move `homepage.dart`, `job_detail_screen.dart`, `shortlisted.dart`, `preferencerhomepagefilter.dart`.

---

### 5. Feature: Creators

#### [MODIFY] [`creator_profiles.dart`](file:///c:/Users/shubh/OneDrive/Desktop/fsap/mobile/lib/data/creator_profiles.dart) → `features/creators/models/creator_profile.dart`
Move + update imports.

#### [MODIFY] `creators_screen.dart`, `creator_profile_screen.dart` → `features/creators/screens/`

---

### 6. Feature: Messaging

#### [MODIFY] [`conversations.dart`](file:///c:/Users/shubh/OneDrive/Desktop/fsap/mobile/lib/data/conversations.dart) → `features/messaging/models/conversation.dart`

#### [MODIFY] `message_list_screen.dart`, `messageslistscreen.dart`, `message_detail_screen.dart` → `features/messaging/screens/`

---

### 7. Feature: Profile

#### [MODIFY] All 8 screens in `screens/userprofilepage/` + `userprofile.dart` + `account_settings_screen.dart` → `features/profile/screens/`

#### [NEW] [`profile_provider.dart`](file:///c:/Users/shubh/OneDrive/Desktop/fsap/mobile/lib/features/profile/providers/profile_provider.dart)
Extract profile/photo state from `AppState`: `updateProfile()`, `uploadProfilePhoto()`, `removeProfilePhoto()`, `uploadVerificationDocument()`.

---

### 8. Feature: Premium + Onboarding

#### [MODIFY] `premium_screen.dart`, `paymentinprogress.dart` → `features/premium/screens/`
#### [MODIFY] `selectlanguage.dart`, `gethelpscreen.dart` → `features/onboarding/screens/`

---

### 9. App Shell — Composing Features

#### [NEW] [`app.dart`](file:///c:/Users/shubh/OneDrive/Desktop/fsap/mobile/lib/app/app.dart)
Extract `MyApp` widget from `main.dart`. Uses `MultiProvider` to compose `AuthProvider`, `ProfileProvider`, `JobState`.

#### [MODIFY] [`main_shell.dart`](file:///c:/Users/shubh/OneDrive/Desktop/fsap/mobile/lib/screens/main_shell.dart) → `app/main_shell.dart`
Move + update imports.

#### [NEW] [`app_state.dart`](file:///c:/Users/shubh/OneDrive/Desktop/fsap/mobile/lib/app/app_state.dart)
Thin facade that composes `AuthProvider`, `ProfileProvider`, `JobState` together. This is the **single ChangeNotifier** the widget tree uses (preserving the current Provider setup) but it internally delegates to feature-specific providers. This allows a **zero-breakage migration** — screens still do `context.watch<AppState>()` but the 433-line god object is now split into focused, testable pieces.

#### [MODIFY] [`main.dart`](file:///c:/Users/shubh/OneDrive/Desktop/fsap/mobile/lib/main.dart)
Simplified to just `ChangeNotifierProvider(create: (_) => AppState(), child: App())`.

---

## Migration Strategy (Safe, No Downtime)

The refactor is done in **3 phases**, each leaving the app compilable:

1. **Phase 1 — Create new directories & copy files.** All new files are created alongside old ones. No deletions, no import changes yet.
2. **Phase 2 — Update all imports** across the codebase atomically. Every file's `import` statements are rewritten from old paths to new paths.
3. **Phase 3 — Delete old files** (`data/`, `models/`, `providers/`, `screens/`, `services/`, `navigation/`, `theme/`, `utils/`, `widgets/`).

This ensures the app **compiles at every step**.

---

## Verification Plan

### Automated Tests
```bash
# Run existing model tests (should pass unchanged)
flutter test test/models_test.dart

# Full analysis — ensure no import errors
flutter analyze
```

### Manual Verification
- Hot-restart the running app on device `5eea5c60423`
- Navigate through all 5 bottom tabs
- Open a job detail, save/unsave a job
- Open a creator profile
- Open premium screen
- Open profile edit → change a field → verify it saves
- Logout and re-login

### Structural Verification
- Confirm `lib/data/`, `lib/models/`, `lib/providers/`, `lib/screens/`, `lib/services/`, `lib/navigation/`, `lib/theme/`, `lib/utils/`, `lib/widgets/` directories are fully removed
- Confirm no circular imports between features (feature A should never import from feature B's `providers/`)
