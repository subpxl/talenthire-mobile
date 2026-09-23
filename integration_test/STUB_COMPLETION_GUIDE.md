# E2E stub completion guide

Working document for turning `integration_test/core/*` stubs into real device tests. Update this file when you change flows or add keys.

**Related files:** `README.md` (how to run) · `support/e2e_keys.dart` (key names) · `support/test_personas.dart` (users)

---

## 1. Standard workflow (every stub)

Use this checklist for **each** test file:

| Step | Action |
|------|--------|
| 1 | Read the stub file header (`/// INSTRUCTIONS`). |
| 2 | Prepare **persona** on device (see §3). |
| 3 | Add **`Key(E2eKeys.…)`** in `lib/` (see §4 matrix). Only keys needed for that test. |
| 4 | Implement **TODO** blocks in the stub using `E2eAppLaunch`, `E2eAuthFlow`, `E2eNavigation`, `pump_helpers`. |
| 5 | Add **assertions** (`expect`, `waitFor`, `waitForOrFail`) — prefer keys over English text. |
| 6 | Remove `skip: 'Stub — …'` from `testWidgets`. |
| 7 | Run single file: `flutter test integration_test/core/<file>.dart -d <deviceId>`. |
| 8 | Fix flakiness: increase timeout in `test_config.dart`, avoid `pumpAndSettle`. |
| 9 | Note any **manual step** (Google account, Cashfree) in test comment. |

### Shared patterns (copy when coding)

```dart
// Start of almost every core test:
E2eAppLaunch.ensureBinding();
await E2eAppLaunch.coldStart(tester);
await E2eAuthFlow.signInIfNeeded(tester);
```

```dart
// Wait for Firestore list (never use pumpAndSettle on this app):
await waitFor(tester, find.byKey(E2eKeys.jobCardFirst),
    timeout: E2eTestConfig.feedLoadTimeout);
await pumpFor(tester, const Duration(seconds: 2));
```

```dart
// Optional: extract repeated flows to support/ later, e.g.:
// support/job_flow.dart → openFirstJobDetail(tester)
```

### Definition of done (one test)

- [ ] Passes **3 times in a row** on a physical device (same persona).
- [ ] Fails with a **clear message** when persona/data wrong (not a hang).
- [ ] No `skip:` on the test.
- [ ] Keys documented in §4 table (Status = Done).

---

## 2. Recommended implementation order

| Order | Test file | Why this order |
|-------|-----------|----------------|
| ✅ | `launch_and_auth_test.dart` | Done — base for all tests |
| 1 | `main_tabs_test.dart` | Validates shell + nav; low data dependency |
| 2 | `jobs_discover_and_detail_test.dart` | Core product; needs 1 job in staging |
| 3 | `job_apply_sheet_test.dart` | Builds on job detail |
| 4 | `saved_and_applied_jobs_test.dart` | Builds on job detail + save |
| 5 | `creators_profile_test.dart` | Parallel to jobs; needs creator data |
| 6 | `profile_settings_test.dart` | Settings tree; no logout yet |
| 7 | `messages_smoke_test.dart` | Needs seeded conversation |
| 8 | `premium_payment_flow_test.dart` | Sandbox + manual native step |
| 9 | `logout_test.dart` | **Run last** on device (clears session) |
| 10 | `onboarding_happy_path_test.dart` | Long; fresh user; nightly only |

---

## 3. Environment & personas

### Before any core test (once per project)

| Item | Where | Target |
|------|--------|--------|
| Remote Config | Firebase Console → Remote Config | `min_android_build` ≤ debug `versionCode` (see `pubspec.yaml` +1) |
| Staging data | Firestore | ≥1 **published job**, ≥1 **creator** in feed |
| Cashfree | Staging / sandbox keys | Payment test only |
| Test Google account | Device | Dedicated account, not personal primary |

### Persona → test mapping

| Persona | When to use | How to reset |
|---------|-------------|--------------|
| **Complete** (`E2ePersona.complete`) | Tabs, jobs, creators, profile, payment | Default daily driver account |
| **With conversation** | `messages_smoke_test.dart` | Seed `messages` / threads for uid |
| **Fresh onboarding** | `onboarding_happy_path_test.dart` | New Google user OR reset `firstLoginStep` in Firestore |
| **Non-premium complete** | `premium_payment_flow_test.dart` | User without active subscription |

Document actual emails/uids in your team wiki — **not** in git.

### Optional: email login (automated auth)

When implemented in `support/auth_flow.dart`:

```text
flutter test integration_test/core/... -d <id> \
  --dart-define=E2E_EMAIL=... \
  --dart-define=E2E_PASSWORD=...
```

Requires keys: `emailSignInToggle`, `emailField`, `passwordField`, `emailSubmit` on `login_screen.dart`.

---

## 4. Key matrix (app changes)

Status: **Done** | **TODO** — update as you implement.

| E2eKeys constant | App file (add `key:`) | Used by test |
|------------------|------------------------|--------------|
| `googleSignIn` | `lib/features/auth/screens/login_screen.dart` | ✅ Done |
| `emailSignInToggle` | `login_screen.dart` (email expand) | Auth (future) |
| `emailField` | `login_screen.dart` | Auth (future) |
| `passwordField` | `login_screen.dart` | Auth (future) |
| `emailSubmit` | `login_screen.dart` | Auth (future) |
| `navHome` | `app_bottom_nav.dart` | ✅ Done |
| `navCreators` | `app_bottom_nav.dart` | ✅ Done |
| `navJobs` | `app_bottom_nav.dart` | ✅ Done |
| `navMessages` | `app_bottom_nav.dart` | ✅ Done |
| `navProfile` | `app_bottom_nav.dart` | ✅ Done |
| `jobCardFirst` | `jobs_screen.dart` index 0 | ✅ Done |
| `jobDetailApply` | `job_detail_screen.dart` | ✅ Done |
| `applySheetSubmit` | `apply_job_sheet.dart` | ✅ Done |
| `jobSave` | `job_detail_screen.dart` | ✅ Done |
| `creatorCardFirst` | `creator_masonry_grid.dart` index 0 | ✅ Done |
| `messageThreadFirst` | `message_list_screen.dart` | ✅ Done |
| `messageComposer` | `message_detail_screen.dart` | ✅ Done |
| `messageSend` | `message_detail_screen.dart` | ✅ Done |
| `profileSettings` | `user_profile_screen.dart` | ✅ Done |
| `settingsPayment` | `get_help_screen.dart` | ✅ Done |
| `settingsLogout` | `account_settings_screen.dart` | ✅ Done |
| `premiumCta` | `user_profile_screen.dart` | ✅ Done |
| `premiumPay` | `premium_screen.dart` | ✅ Done |
| `onboardingMobileField` | `enter_mobile_screen.dart` | ✅ Done |
| `onboardingContinue` | `onboarding_step_scaffold.dart` | ✅ Done |
| `onboardingSkip` | `onboarding_step_scaffold.dart` | ✅ Done |

**Tip:** For “first card” keys, set the key in the list builder when `index == 0` to avoid marking every row.

---

## 5. Per-test completion spec

### `main_tabs_test.dart`

**Goal:** Tap Home → Creators → Jobs → Messages → Profile; no crash.

**Persona:** Complete.

**App work:** Nav keys (§4).

**Implement:**

1. After each `E2eNavigation.tap*`, `pumpFor` 2–3s.
2. Assert one of:
   - Home: banner or jobs carousel or empty scaffold (`home_screen.dart`).
   - Creators: grid (`creators_screen.dart`).
   - Jobs: list (`jobs_screen.dart`).
   - Messages: list or empty (`message_list_screen.dart`).
   - Profile: avatar/name (`user_profile_screen.dart`).

**Avoid:** `pumpAndSettle`.

---

### `jobs_discover_and_detail_test.dart`

**Goal:** Jobs tab → first job → detail visible.

**Persona:** Complete. **Data:** ≥1 job in feed.

**App work:** `jobCardFirst`.

**Implement:**

1. `E2eNavigation.tapJobs(tester)`.
2. `waitFor` `jobCardFirst` with `E2eTestConfig.feedLoadTimeout`.
3. If timeout → `fail('No jobs in staging feed')`.
4. Tap card → `pumpFor` 3s.
5. Assert: job title text, or `jobDetailApply` visible (`job_detail_screen.dart`).

**Optional helper:** `support/job_flow.dart` → `Future<void> openFirstJobDetail(WidgetTester tester)`.

---

### `job_apply_sheet_test.dart`

**Goal:** Apply sheet opens; validation + submit behavior.

**Persona:** Complete user who **can apply** (quota not exhausted).

**App work:** `jobDetailApply`, `applySheetSubmit`.

**Implement:**

1. Reuse open first job detail.
2. Tap `jobDetailApply` → sheet visible (`apply_job_sheet.dart`).
3. Tap submit empty → expect validation (`InputValidators` / snack).
4. Fill required fields (inspect sheet — video link, message, etc.).
5. Submit → expect success toast or quota message (`apply_quota.dart`).

**Note:** Do not use production payment-required jobs unless intentional.

---

### `saved_and_applied_jobs_test.dart`

**Goal:** Save job; see it under saved jobs.

**Persona:** Complete.

**App work:** `jobSave`; optional key on saved list first tile.

**Implement:**

1. Open job detail → tap save (`jobSave`).
2. Navigate to saved jobs: from `jobs_screen.dart` / profile — trace UI path in app.
3. Open `saved_jobs_screen.dart` content (`SavedJobsTabContent`).
4. Assert job title substring matches.

**Applied jobs:** `applied_jobs_screen.dart` — optional second `testWidgets` in same file.

---

### `creators_profile_test.dart`

**Goal:** Creators tab → profile screen.

**Persona:** Complete. **Data:** ≥1 creator.

**App work:** `creatorCardFirst`.

**Implement:**

1. `E2eNavigation.tapCreators`.
2. `waitFor` `creatorCardFirst`.
3. Tap → assert `creator_profile_screen.dart` sections (name, portfolio area).

---

### `messages_smoke_test.dart`

**Goal:** Messages tab → open thread.

**Persona:** With conversation.

**App work:** `messageThreadFirst`; optional composer/send.

**Implement:**

1. `E2eNavigation.tapMessages`.
2. If empty → skip with `skip: 'No seeded conversation'` OR fail in CI mode.
3. Tap first thread → `message_detail_screen.dart` loads.
4. Optional: type in composer, send, `pumpFor`, find message text.

---

### `profile_settings_test.dart`

**Goal:** Profile → Account settings → notification prefs (smoke).

**Persona:** Complete.

**App work:** `profileSettings`; trace path to `notification_preferences_screen.dart`.

**Implement:**

1. `E2eNavigation.tapProfile`.
2. Tap settings entry (`profileSettings` or find settings icon — check `user_profile_screen.dart`).
3. `AppNavigation` → `AccountSettingsScreen` (`account_settings_screen.dart`).
4. Open notification preferences row (find in settings tree / `settings_group_screen.dart`).
5. Assert switches/list visible; pop back twice without error.

**Payment smoke (light):** tap row opening `PaymentAndSubscriptionScreen` — full pay flow stays in `premium_payment_flow_test.dart`.

---

### `premium_payment_flow_test.dart`

**Goal:** Start premium payment; app survives native Cashfree UI.

**Persona:** Complete, **non-premium**.

**App work:** `premiumCta`, `premiumPay`.

**Env:** Cashfree **sandbox**; manual step documented.

**Implement:**

1. Profile → premium entry (`AppNavigation.openPremiumScreen` — `premium_screen.dart`).
2. Tap pay (`PaymentService.launchUpiOneTimePayment` path — `payment_service.dart`).
3. `pumpFor(tester, E2eTestConfig.paymentNativeTimeout)` — **on device:** complete sandbox pay or cancel.
4. Assert:
   - Success path: premium UI / toast / `isPremiumUser` reflected in UI, OR
   - Cancel: still in app, no infinite loader (`payment_in_progress_screen.dart`).

**Do not assert** money settled in Firestore automatically unless you add test-only webhook seed.

**CI:** Keep `skip` or tag as manual until Patrol/sandbox automation exists.

---

### `logout_test.dart`

**Goal:** Logout → login screen.

**Persona:** Complete (signed in at start).

**App work:** `settingsLogout` on logout `TextButton` in `account_settings_screen.dart`.

**Implement:**

1. Sign in → Profile → Account settings (same as profile test).
2. Tap logout → confirm dialog if any.
3. `waitForOrFail` `E2eKeys.googleSignIn`.

**Suite order:** Run **after** all other tests or use a dedicated device run — it clears session.

---

### `onboarding_happy_path_test.dart`

**Goal:** New user completes onboarding → main shell.

**Persona:** Fresh (see §3).

**App work:** onboarding keys; skip photo via native picker limitation.

**Implement:**

1. `E2eAuthFlow.signInIfNeeded` with **new** Google account.
2. `enter_mobile_screen.dart` — mobile + continue (`FirstLoginStep.mobile`).
3. `select_language_screen.dart` — pick English, continue.
4. `onboarding_photo_screen.dart` — **skip** if available (image picker is native).
5. `onboarding_category_screen.dart`, `onboarding_creator_screen.dart`, `onboarding_social_screen.dart` — minimal valid input per validators.
6. Assert `navHome` or `Icons.home_outlined`.

**Timeout:** Use `Timeout(Duration(minutes: 8))` on `testWidgets`.

**Schedule:** Nightly / manual — not default PR gate.

---

## 6. Extract shared flows (when 2+ tests duplicate code)

| New support file | Extract from |
|------------------|--------------|
| `support/job_flow.dart` | Open jobs tab, first job, detail |
| `support/settings_flow.dart` | Profile → account settings |
| `support/onboarding_flow.dart` | Step-by-step onboarding |

Keep stubs thin: call support helpers, assert in test file.

---

## 7. Running the suite

```powershell
cd mobile

# Single test (while implementing)
flutter test integration_test/core/jobs_discover_and_detail_test.dart -d <deviceId>

# All core (skipped tests are ignored)
flutter test integration_test/core/ -d <deviceId>

# Legacy alias
flutter test integration_test/app_smoke_test.dart -d <deviceId>
```

**Suggested groups:**

| Group | Files |
|-------|--------|
| Smoke | `launch_and_auth`, `main_tabs` |
| Jobs | `jobs_discover_*`, `job_apply_*`, `saved_and_applied_*` |
| Social | `creators_*`, `messages_*` |
| Account | `profile_settings`, `premium_payment`, `logout` |
| Onboarding | `onboarding_happy_path` (alone) |

---

## 8. Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Hang at test name | `pumpAndSettle` | Use `pumpFor` / `waitFor` only |
| Firebase channel error | Wrong folder / not `integration_test/` | Run from `mobile/` root |
| “Some possible finders at Offset…” | Long wait / touch device during test | Don’t touch; use bounded pump |
| Login never completes | Google sheet not confirmed | Pick account within 2 min |
| Force update screen | Remote Config min build too high | Lower staging RC |
| Empty job/creator feed | No staging data | Seed Firestore |
| Payment test flaky | Native UI | Manual step + long `paymentNativeTimeout` |
| Logout breaks next test | Session cleared | Run logout last |

---

## 9. Progress tracker (edit as you go)

| Test file | Keys done | Test coded | 3× pass on device | Notes |
|-----------|-----------|------------|-------------------|-------|
| `launch_and_auth_test.dart` | google ✅ | ✅ | ☐ | |
| `main_tabs_test.dart` | nav ✅ | ✅ | ☐ | |
| `jobs_discover_and_detail_test.dart` | job ✅ | ✅ | ☐ | needs staging jobs |
| `job_apply_sheet_test.dart` | apply ✅ | ✅ | ☐ | quota / video job |
| `saved_and_applied_jobs_test.dart` | save ✅ | ✅ | ☐ | |
| `creators_profile_test.dart` | creator ✅ | ✅ | ☐ | needs staging creators |
| `messages_smoke_test.dart` | messages ✅ | ✅ | ☐ | seeded conversation |
| `profile_settings_test.dart` | profile ✅ | ✅ | ☐ | |
| `premium_payment_flow_test.dart` | premium ✅ | ✅ | ☐ | manual Cashfree on device |
| `logout_test.dart` | logout ✅ | ✅ | ☐ | run last |
| `onboarding_happy_path_test.dart` | onboarding ✅ | ✅ | ☐ | fresh user or no-op |

---

*Last updated: 2026-09-23 — all core tests coded; device 3× pass pending.*
