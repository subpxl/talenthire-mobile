# Device E2E integration tests

**Complete the stubs:** see **[STUB_COMPLETION_GUIDE.md](./STUB_COMPLETION_GUIDE.md)** (step-by-step, keys, order, per-test specs, progress table).

## Run (connected phone)

From **`mobile/`** (not `flutter_integration_test/`):

```powershell
flutter devices
flutter test integration_test/core/launch_and_auth_test.dart -d <deviceId>
flutter test integration_test/core/ -d <deviceId>
```

First run builds `app-debug.apk` (~2–3 min). Keep the device **unlocked**.

## Layout

| Path | Purpose |
|------|---------|
| `pump_helpers.dart` | Bounded pumping (avoid `pumpAndSettle`) |
| `support/` | Shared launch, auth, navigation, keys, config |
| `core/` | Core feature tests (all coded; validate on device per STUB guide) |

## Environment checklist (before coding tests)

- [ ] Staging Firebase (or isolated test data in prod)
- [ ] Remote Config: `min_android_build` ≤ current debug build
- [ ] Test users: **complete** (onboarded), **fresh** (onboarding), optional **with chat**
- [ ] Cashfree **sandbox** keys for payment tests
- [ ] Add `Key`s from `support/e2e_keys.dart` in app UI as you implement each test

## Auth

- **Google:** test taps `e2e_google_sign_in`; you pick account on native sheet (~2 min window).
- **Email (future):** pass `--dart-define=E2E_EMAIL=...` and `E2E_PASSWORD=...` when implemented in `auth_flow.dart`.

## Payment

Native Cashfree UI cannot be fully automated with stock `integration_test`. Core test = open premium → tap pay → complete or cancel on device → assert app shows success/failure/cancel state without hang.
