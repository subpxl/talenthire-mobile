# Feature-First Architecture Refactor — Tasks

## Phase 1: Create New Directory Structure & Files

### Core Layer
- [ ] Create `core/models/user_model.dart` — extract User, UserRole, shared helpers
- [ ] Create `core/models/profile_model.dart` — extract Profile, SocialPlatformMetric, enums
- [ ] Create `core/models/models.dart` — barrel re-export
- [ ] Move `services/auth_service.dart` → `core/services/auth_service.dart`
- [ ] Move `services/storage_service.dart` → `core/services/storage_service.dart`
- [ ] Move `navigation/app_navigation.dart` → `core/navigation/app_navigation.dart`
- [ ] Move `navigation/app_page_route.dart` → `core/navigation/app_page_route.dart`
- [ ] Move `theme/app_theme.dart` → `core/theme/app_theme.dart`
- [ ] Move `utils/legal_links.dart` → `core/utils/legal_links.dart`
- [ ] Move all `widgets/*.dart` → `core/widgets/*.dart`

### Feature: Auth
- [ ] Move `screens/login_screen.dart` → `features/auth/screens/login_screen.dart`
- [ ] Move `screens/splash_screen.dart` → `features/auth/screens/splash_screen.dart`

### Feature: Jobs
- [ ] Create `features/jobs/models/job_model.dart`
- [ ] Create `features/jobs/models/application_model.dart`
- [ ] Create `features/jobs/models/job_listing.dart`
- [ ] Create `features/jobs/models/job_assets.dart`
- [ ] Move `providers/job_feed.dart` → `features/jobs/providers/job_feed_provider.dart`
- [ ] Move `services/job_cache_service.dart` → `features/jobs/services/job_cache_service.dart`
- [ ] Move `screens/homepage.dart` → `features/jobs/screens/home_screen.dart`
- [ ] Move `screens/job_detail_screen.dart` → `features/jobs/screens/job_detail_screen.dart`
- [ ] Move `screens/shortlisted.dart` → `features/jobs/screens/shortlisted_screen.dart`
- [ ] Move `screens/preferencerhomepagefilter.dart` → `features/jobs/screens/preference_filter_screen.dart`

### Feature: Creators
- [ ] Move `data/creator_profiles.dart` → `features/creators/models/creator_profile.dart`
- [ ] Move `screens/creators_screen.dart` → `features/creators/screens/creators_screen.dart`
- [ ] Move `screens/creator_profile_screen.dart` → `features/creators/screens/creator_profile_screen.dart`

### Feature: Messaging
- [ ] Move `data/conversations.dart` → `features/messaging/models/conversation.dart`
- [ ] Move `screens/message_list_screen.dart` → `features/messaging/screens/message_list_screen.dart`
- [ ] Move `screens/messageslistscreen.dart` → `features/messaging/screens/messages_list_screen.dart`
- [ ] Move `screens/message_detail_screen.dart` → `features/messaging/screens/message_detail_screen.dart`

### Feature: Profile
- [ ] Move `screens/userprofile.dart` → `features/profile/screens/user_profile_screen.dart`
- [ ] Move `screens/account_settings_screen.dart` → `features/profile/screens/account_settings_screen.dart`
- [ ] Move all `screens/userprofilepage/*.dart` → `features/profile/screens/`

### Feature: Premium
- [ ] Move `screens/premium_screen.dart` → `features/premium/screens/premium_screen.dart`
- [ ] Move `screens/paymentinprogress.dart` → `features/premium/screens/payment_in_progress_screen.dart`

### Feature: Onboarding
- [ ] Move `screens/selectlanguage.dart` → `features/onboarding/screens/select_language_screen.dart`
- [ ] Move `screens/gethelpscreen.dart` → `features/onboarding/screens/get_help_screen.dart`

### App Shell
- [ ] Create `app/app.dart` — MyApp widget
- [ ] Move `screens/main_shell.dart` → `app/main_shell.dart`
- [ ] Create `app/app_state.dart` — composed facade

## Phase 2: Update main.dart & All Imports
- [ ] Update `main.dart` to use new paths
- [ ] Update all cross-feature imports

## Phase 3: Delete Old Directories
- [ ] Delete old `data/`, `models/`, `providers/`, `screens/`, `services/`, `navigation/`, `theme/`, `utils/`, `widgets/`

## Verification
- [ ] `flutter analyze` passes
- [ ] `flutter test` passes
- [ ] App runs on device
