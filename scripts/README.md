# Firebase job seed tool

This self-contained Node utility validates and optionally seeds the 66 job
posters in `assets/jobs`. It creates only ownerless `jobs` documents and
Storage objects; it does not create users or agencies.

## Requirements

- Node.js 20 or newer
- A service-account JSON file with access to Firestore and Storage
- An existing Firebase Storage bucket

Keep credentials outside the repository. The tool reads them only through
`GOOGLE_APPLICATION_CREDENTIALS`.

## Install and validate

From `scripts`:

```powershell
npm ci
npm run validate
```

Validation is the default dry run. It checks all 66 JSON records, deterministic
IDs and image mappings, field types and enums, dates, ownerless records, JPEG
signatures, file sizes, and dimensions. It makes no Firebase calls.

## Seed Firebase

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS = "C:\secure\service-account.json"
npm run seed
```

This uses the app's configured `talenthire-d86a1.firebasestorage.app` bucket.
`--apply` verifies that the
credential project matches an explicitly supplied `--project`, obtains an
access token, and verifies bucket access before changing data. Existing job IDs
are skipped, making the default apply operation idempotent.

To deliberately replace existing seeded documents and poster objects:

```powershell
node seed_jobs.js --apply --overwrite
```

`--overwrite` is rejected unless `--apply` is also present.

The project and bucket can alternatively be supplied with
`FIREBASE_PROJECT_ID` (or `GCLOUD_PROJECT`) and `FIREBASE_STORAGE_BUCKET`.

## Data and write behavior

- Dataset: `data/jobs.json`
- Firestore collection: `jobs`
- Deterministic document IDs: `seed-job-001` through `seed-job-066`
- Storage objects: `job-images/{jobId}/poster.jpeg`
- Upload metadata: `image/jpeg`, one-year immutable cache policy, seed source
  image, and a deterministic Firebase download token
- Dates are written as Firestore timestamps
- Firestore writes are committed in batches of at most 400
- Each written job has `created_by: ""`, `is_verified: false`, its durable
  `image_url`, and its Storage `image_path`

The command prints validation progress, upload progress, skipped records, a
machine-readable final summary, and per-record errors. A partial upload failure
is reported and prevents that record from being written to Firestore.

## Seed test creators

`seed_creators.js` creates 12 test creator accounts from `demophotos_model`
(35 JPEGs). It writes Auth users, `users` / `profiles` documents, and Storage
photos so they appear on the Creators page.

```powershell
npm run validate:creators
npm run seed:creators
```

- Deterministic IDs: `seed-creator-001` through `seed-creator-012`
- Storage objects: `users/{id}/profile/photo-N.jpeg`
- Test password: `DemoCreator@2026`
- Existing seed IDs are skipped unless you pass `--overwrite`

```powershell
node seed_creators.js --apply --overwrite --project talenthire-d86a1
```
