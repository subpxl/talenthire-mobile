# First-Time Registration Performance Review

**App:** Bombay Casting Company (Flutter)  
**Date:** August 24, 2026  
**Scope:** Why first-time user registration feels slow; network call inventory; bottlenecks; optimization proposals (no code changes in this review).

---

## Executive Summary

First-time registration is slow because the app **blocks the login spinner until the entire post-auth bootstrap completes**. That bootstrap includes:

- Firebase Auth (1–3 round trips for email signup)
- Firestore user + profile document creation (2–4 reads/writes)
- Empty-data fetches for applications and saved jobs (2 queries that always return nothing for new users)
- **Full job feed load** (1–2 Firestore queries for up to 40 jobs, plus disk cache I/O)

There is **no Cloud Function involved in registration today**. All user/profile provisioning happens client-side from `AppState`. The only deployed function (`onNewMessage`) handles chat push notifications.

**Estimated network round trips before the user sees the home screen (new user, cold cache):**

| Path | Auth | Firestore | Total blocking calls |
|------|------|-----------|----------------------|
| Email register | 3 | 7–9 | **10–12** |
| Google sign-in | 2 | 7–9 | **9–11** |

On a typical mobile connection (200–500 ms RTT per Firebase call), that is **~2–6 seconds of pure network wait**, before JSON parsing and UI work.

---

## Current Registration Flow

```
LoginScreen (spinner ON)
  │
  ├─ Email: registerWithEmailPassword()
  │     └─ createUserWithEmailAndPassword
  │     └─ updateDisplayName
  │     └─ reload
  │
  └─ Google: signInWithGoogle()
        └─ GoogleSignIn.authenticate
        └─ signInWithCredential
  │
  ▼
_createOrFetchUser()
  └─ GET  users/{uid}
  └─ SET  users/{uid}          (new user only)
  └─ _loadUserData(uid)
        └─ GET  users/{uid}    ← duplicate read
        └─ Future.wait([
              GET  profiles/{uid} → SET profiles/{uid} (new)
              GET  applications (user_id == uid)      ← always empty for new user
              GET  users/{uid}/saved_jobs               ← always empty for new user
              jobFeed.hydrateAndLoad()
                 └─ disk cache read
                 └─ GET jobs (12 docs)
                 └─ GET jobs (28 more docs, sequential)
           ])
  └─ SET profiles/{uid} merge  (Google photo, conditional)
  │
  ▼
isAuthenticated = true → MainShell (spinner OFF)
```

**Key files:**

| File | Role |
|------|------|
| `lib/screens/login_screen.dart` | UI; spinner tied to full `registerWithEmail` / `loginWithGoogle` |
| `lib/services/auth_service.dart` | Firebase Auth calls |
| `lib/providers/app_state.dart` | Orchestrates create/fetch user, profile, and all app data |
| `lib/providers/job_feed.dart` | Job feed fetch (largest post-auth cost) |
| `lib/services/job_cache_service.dart` | Local disk cache (empty on first install) |
| `functions/src/index.ts` | Only `onNewMessage` — not used in registration |

There is **no onboarding screen** and **no `profile_completed` routing gate** — new users land directly on the job feed once bootstrap finishes.

---

## Network Call Inventory (First-Time Register)

### Phase 1 — Firebase Authentication

#### Email registration (`auth_service.dart:151–181`)

| # | Call | Blocking? | Notes |
|---|------|-----------|-------|
| 1 | `createUserWithEmailAndPassword` | Yes | Creates Auth user |
| 2 | `updateDisplayName` | Yes | Separate round trip; Auth doesn't set name on email signup |
| 3 | `reload` | Yes | Refreshes local user object after display name update |

These three calls are **sequential**. They could be reduced (see proposals).

#### Google sign-in (`auth_service.dart:25–75`)

| # | Call | Blocking? | Notes |
|---|------|-----------|-------|
| 1 | `GoogleSignIn.authenticate` | Yes | Native account picker + token exchange |
| 2 | `signInWithCredential` | Yes | Firebase Auth |

Google path is inherently 2 calls; display name and photo come from the credential.

---

### Phase 2 — Firestore User Document (`app_state.dart:147–174`)

| # | Call | Op | Blocking? | Notes |
|---|------|----|-----------|-------|
| 4 | `users/{uid}` | GET | Yes | Check if user doc exists |
| 5 | `users/{uid}` | SET | Yes (new) | Client creates user with defaults |

Default user fields: `role: influencer`, `is_active: true`, empty `mobile`.

---

### Phase 3 — Full App Data Load (`app_state.dart:176–197`)

| # | Call | Op | Blocking? | Notes |
|---|------|----|-----------|-------|
| 6 | `users/{uid}` | GET | Yes | **Redundant** — same doc just read/written in Phase 2 |
| 7 | `profiles/{uid}` | GET | Yes | Check profile |
| 8 | `profiles/{uid}` | SET | Yes (new) | Client creates default profile |
| 9 | `applications` where `user_id == uid` | GET | Yes | **Always empty** for brand-new user |
| 10 | `users/{uid}/saved_jobs` | GET | Yes | **Always empty** for brand-new user |
| 11 | `jobs` where `status == published` orderBy `posted_at` | GET (limit 12) | Yes | First paint chunk |
| 12 | `jobs` (continuation) | GET (limit 28) | Yes | **Sequential** after #11 completes |

Steps 7–12 run in `Future.wait`, but **job feed internally does two sequential Firestore queries** (`job_feed.dart:108–132`).

#### Phase 3b — Google photo sync (conditional)

| # | Call | Op | Blocking? | Notes |
|---|------|----|-----------|-------|
| 13 | `profiles/{uid}` | SET merge | Yes | Runs **after** all of Phase 3 |

---

### Not Called During Registration (but relevant)

| Service | Status |
|---------|--------|
| Cloud Functions (`httpsCallable`) | Not used anywhere |
| Auth trigger (`onCreate` user) | Not deployed |
| Firebase Storage | Post-registration only (profile photos) |
| Realtime Database | Post-registration only (messages) |
| FCM token registration | `firebase_messaging` in pubspec but **no client code** writes `fcm_tokens` |
| Phone OTP | Implemented in `auth_service.dart` but **not wired to UI** |

---

## Problems Found

### P1 — Critical: Job feed blocks registration completion

**Where:** `app_state.dart:185–190` — `jobFeed.hydrateAndLoad()` is inside `Future.wait` during `_loadUserData`, which runs before `isAuthenticated = true` and before leaving the login spinner.

**Impact:** New users wait for up to **40 job documents** (2 sequential queries) before seeing the app. On first install the disk cache is empty, so Firestore is always hit.

**Why it's unnecessary for registration:** Registration only needs Auth + user/profile docs. Jobs are public data and can load after `MainShell` is visible.

---

### P2 — Critical: Duplicate `users/{uid}` read

**Where:**
- `_createOrFetchUser` → GET `users/{uid}` (`app_state.dart:154`)
- `_loadUserData` → GET `users/{uid}` again (`app_state.dart:178`)

**Impact:** One extra Firestore round trip on every login/register (~200–500 ms).

**Fix complexity:** Low — pass the in-memory `User` from `_createOrFetchUser` into `_loadUserData` or skip the second GET when user is already loaded.

---

### P3 — High: Sequential Firebase Auth calls on email signup

**Where:** `auth_service.dart:158–169`

```
createUserWithEmailAndPassword  →  updateDisplayName  →  reload
```

**Impact:** 3 sequential Auth API calls before any Firestore work starts (~600–1500 ms on mobile).

**Note:** `updateDisplayName` + `reload` exist because Firebase Auth doesn't set display name on email/password signup. The app already stores `name` in Firestore — the Auth display name is secondary for this flow.

---

### P4 — High: Empty collections fetched for every new user

**Where:** `_loadApplications` and `_loadSavedJobs` in `_loadUserData`'s `Future.wait`

**Impact:** 2 Firestore queries that **guaranteed return zero documents** for first-time users. Still pay query latency + rules evaluation.

**Mitigation:** Skip these on known-new-user path, or defer until user opens Saved/Applications tabs.

---

### P5 — Medium: Two separate Firestore writes for user bootstrap (client-side)

**Where:** `_createOrFetchUser` SET `users/{uid}`, then `_loadProfile` SET `profiles/{uid}`

**Impact:** Two writes with separate round trips. Could be one batched write or one server-side atomic create.

**Security rules note:** `firestore.rules` requires clients to create their own docs with specific fields — a Cloud Function using Admin SDK can still enforce the same defaults server-side.

---

### P6 — Medium: Google photo sync is a post-load extra write

**Where:** `app_state.dart:164–169` — runs after `_loadUserData` completes

**Impact:** Additional Firestore write + latency before UI fully settles. Could be included in initial profile SET for Google users.

---

### P7 — Medium: Login spinner covers entire bootstrap

**Where:** `login_screen.dart:44–57` — `_isLoading` stays true until `registerWithEmail` / `loginWithGoogle` return

**Impact:** User perception of slowness is amplified because there is no progressive UI (no "Creating account…" vs "Loading jobs…" vs early navigation).

---

### P8 — Low: No auth state listener

**Where:** `app_state.dart:58–71` — one-shot `currentUser` check at startup

**Impact:** Not a registration bottleneck, but token expiry / session changes aren't handled reactively.

---

### P9 — Low: Dead code surface

- Phone OTP (`sendOtp`, `verifyOtp`) — implemented, never used in UI
- `profile_completed` field — set to `false`, never checked for routing
- FCM — dependency present, no token registration despite Cloud Function expecting `fcm_tokens`

---

### P10 — Infrastructure (verify in Firebase Console)

| Item | Status in repo | Risk |
|------|----------------|------|
| Composite index `jobs: status + posted_at` | Defined in `firestore.indexes.json` | If not deployed, query may fail or fall back to slower path |
| Firestore region vs Auth region | Not visible in client code | Cross-region adds latency |

---

## Proposed Solutions

### Tier 1 — Quick wins (client-only, high impact, low risk)

#### S1 — Navigate to home before job feed finishes

**Change:** Split `_loadUserData` into:
- **Critical path (blocking):** user doc + profile doc only
- **Deferred (background):** applications, saved jobs, job feed

**Expected savings:** 1–3 seconds (job queries + cache I/O removed from registration critical path)

**UX:** Show `MainShell` with a skeleton/loader on Home tab while jobs load (HomeScreen already handles `isLoadingJobs && jobs.isEmpty`).

```
registerWithEmail()
  └─ Auth
  └─ create user + profile (critical)
  └─ isAuthenticated = true  ← user sees app HERE
  └─ unawaited: load applications, saved jobs, jobs
```

---

#### S2 — Eliminate duplicate user doc read

**Change:** After `_createOrFetchUser` sets `user` in memory, call `_loadUserData(uid, skipUserFetch: true)` or pass the `User` object.

**Expected savings:** ~200–500 ms per registration.

---

#### S3 — Skip empty fetches for new users

**Change:** When `_createOrFetchUser` creates a new user doc, set `applications = []`, `savedJobs = []` without querying Firestore. Load lazily when user opens relevant tabs.

**Expected savings:** ~400–1000 ms (2 queries removed from critical path).

---

#### S4 — Remove or defer `reload()` on email signup

**Change:** Drop `user.reload()` if display name is only needed in Firestore (already written client-side). Optionally keep `updateDisplayName` but don't block on `reload`.

**Expected savings:** ~200–500 ms.

**Trade-off:** `firebaseUser.displayName` may be stale in Auth until next token refresh — acceptable if Firestore `name` is source of truth.

---

#### S5 — Include Google photo in initial profile SET

**Change:** When creating profile for Google user, set `profile_image` from `photoURL` in the first SET instead of a second merge write after `_loadUserData`.

**Expected savings:** ~200–500 ms for Google registrations.

---

### Tier 2 — Cloud Function approach (recommended for atomic, fast client UX)

#### S6 — `onAuthUserCreated` Cloud Function (Firebase Auth trigger)

Deploy a function triggered when a new Firebase Auth user is created:

```typescript
// Conceptual — not implemented
export const onAuthUserCreated = functions.auth.user().onCreate(async (user) => {
  const { uid, email, displayName, photoURL } = user;
  const batch = db.batch();
  batch.set(db.doc(`users/${uid}`), { /* defaults */ });
  batch.set(db.doc(`profiles/${uid}`), { /* defaults, photoURL if present */ });
  await batch.commit();
});
```

**Client changes:**
- Remove client-side SET for new user/profile (or keep as idempotent fallback)
- After Auth succeeds, only **GET** user + profile (or trust defaults and fetch in background)

**Benefits:**
| Benefit | Detail |
|---------|--------|
| Atomic create | User + profile created in one server batch |
| Faster client | Client does Auth + 1–2 reads instead of Auth + 2 writes + reads |
| Consistent defaults | Server owns default shape; no client drift |
| Security | Admin SDK bypasses rules but you control logic in function |
| Extensibility | Welcome email, analytics, FCM topic subscribe, etc. |

**Considerations:**
- Eventual consistency: client may GET before function finishes → use retry/backoff or optimistic UI with defaults
- Google vs email: function receives `displayName` / `photoURL` from Auth when available
- Must handle idempotency if client also writes (pick one source of truth)

---

#### S7 — Callable `bootstrapUser` Cloud Function (alternative to trigger)

Client calls `httpsCallable('bootstrapUser')` immediately after Auth. Function creates user + profile if missing, returns both docs.

**Benefits:** Synchronous — client gets data back in one call.  
**Drawbacks:** Extra callable latency; client must invoke; not automatic for all auth paths unless every path calls it.

**Best for:** When you need returned data immediately and want explicit client control.

---

#### S8 — Move FCM token registration to post-auth background task

Not registration-critical, but completes the push pipeline:

1. After `MainShell` visible, request notification permission
2. Get FCM token
3. Merge into `users/{uid}.fcm_tokens`

Cloud Function `onNewMessage` already reads `fcm_tokens` — today pushes silently fail for all users.

---

### Tier 3 — Architecture / UX improvements

#### S9 — Progressive registration UX

Replace single spinner with staged feedback:

1. "Creating your account…" (Auth + Firestore user/profile)
2. Navigate to MainShell
3. Home shows skeleton while jobs load

Perceived performance improves even if total work is similar.

---

#### S10 — Optional lightweight onboarding

`profile_completed` exists but is unused. A 1-screen "Add city & niche" step could:
- Run **after** MainShell is visible
- Not block registration
- Improve data quality without affecting time-to-first-screen

---

#### S11 — Job feed: don't double-fetch on cold start for new users

Even when deferring job load, consider:
- First query only (`firstPaintSize = 12`) before showing content
- Load remaining 28 in background (`isLoadingMore`)
- Today both chunks block `hydrateAndLoad()` completion when called from `_loadUserData`

---

## Recommended Implementation Order

| Priority | Solution | Effort | Impact | Type |
|----------|----------|--------|--------|------|
| 1 | S1 — Defer job feed + empty queries | Small | **Very high** | Client |
| 2 | S2 — Remove duplicate user GET | Small | Medium | Client |
| 3 | S3 — Skip empty app/saved queries for new users | Small | Medium | Client |
| 4 | S4 — Drop Auth `reload()` | Trivial | Medium | Client |
| 5 | S5 — Google photo in initial profile SET | Small | Low–Medium | Client |
| 6 | S6 — Auth trigger Cloud Function | Medium | High (long-term) | Backend |
| 7 | S8 — FCM token registration | Small | N/A for reg speed; fixes push | Client |
| 8 | S9 — Progressive UX copy/states | Small | Perceived perf | UX |

**Fastest path to noticeably faster registration:** Implement **S1 + S2 + S3** (all client-side, no new infrastructure). Expected reduction: **~50–70%** of current wait time.

**Best long-term architecture:** **S6** (Auth trigger) + **S1** (defer non-critical loads). Client does Auth → navigate → background hydrate.

---

## Target State (After Optimization)

```
LoginScreen
  │
  ├─ Auth (1–2 calls email, 2 calls Google)
  │
  ▼
Critical bootstrap (~300–800 ms)
  ├─ GET or create user + profile (or Cloud Function already created them)
  └─ isAuthenticated = true → MainShell visible
  │
  ▼
Background (non-blocking)
  ├─ Job feed (12 docs first, rest lazy)
  ├─ Applications (when needed)
  ├─ Saved jobs (when needed)
  ├─ FCM token
  └─ Creators (already lazy — only on tab visit ✓)
```

**Target blocking calls:** 2–4 (down from 10–12)

---

## Appendix: Default Documents Created Today

### `users/{uid}`

```json
{
  "id": "<uid>",
  "name": "<from form or Google>",
  "email": "<email>",
  "mobile": "",
  "role": "influencer",
  "is_active": true,
  "created_at": "<ISO8601>",
  "updated_at": "<ISO8601>"
}
```

### `profiles/{uid}`

```json
{
  "user_id": "<uid>",
  "profile_image": "",
  "photos": [],
  "is_verified": false,
  "talent": "influencer",
  "bio": "", "contact": "", "city": "", "state": "",
  "languages": [], "niches": [], "platform_metrics": [],
  "form_data": {},
  "profile_completed": false,
  "subscription_status": "free",
  "account_status": "active",
  "free_job_applications_used": 0
}
```

---

## Appendix: Code References

| Issue | Location |
|-------|----------|
| Registration entry | `lib/providers/app_state.dart:119–145` |
| User create/fetch | `lib/providers/app_state.dart:147–174` |
| Full data load (blocking) | `lib/providers/app_state.dart:176–197` |
| Sequential Auth calls | `lib/services/auth_service.dart:158–169` |
| Job double-fetch | `lib/providers/job_feed.dart:108–132` |
| Login spinner scope | `lib/screens/login_screen.dart:44–57` |
| Firestore user/profile rules | `firestore.rules:54–118` |
| Only Cloud Function | `functions/src/index.ts` (`onNewMessage`) |

---

*This document is analysis-only. No application code was modified.*
