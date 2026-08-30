#!/usr/bin/env node

import { createHash } from 'node:crypto';
import { readFile, readdir, stat } from 'node:fs/promises';
import { resolve, dirname, basename } from 'node:path';
import { fileURLToPath } from 'node:url';
import { cert, getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, '..');
const dataPath = resolve(here, 'data', 'creators.json');
const imageRoot = resolve(repoRoot, 'demophotos_model');
const defaultStorageBucket = 'talenthire-d86a1.firebasestorage.app';
const defaultPassword = 'DemoCreator@2026';
const maxPhotos = 4;

function usage() {
  return `Usage: node seed_creators.js [options]

Dry-run validation is the default and does not contact Firebase.

  --apply             Upload photos and write Auth + Firestore documents
  --overwrite         Replace existing seed creators (requires --apply)
  --project <id>      Expected Firebase project ID
  --bucket <name>     Firebase Storage bucket name
  --help              Show this help

Apply mode uses GOOGLE_APPLICATION_CREDENTIALS, or scripts/serviceAccountKey.json
if that file is present. Project and bucket may be supplied through
FIREBASE_PROJECT_ID / GCLOUD_PROJECT and FIREBASE_STORAGE_BUCKET.`;
}

function parseArgs(argv) {
  const options = { apply: false, overwrite: false, project: '', bucket: '' };
  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === '--apply') options.apply = true;
    else if (arg === '--overwrite') options.overwrite = true;
    else if (arg === '--help' || arg === '-h') options.help = true;
    else if (arg === '--project' || arg === '--bucket') {
      const value = argv[index + 1];
      if (!value || value.startsWith('--')) throw new Error(`${arg} requires a value`);
      options[arg.slice(2)] = value;
      index += 1;
    } else {
      throw new Error(`Unknown option: ${arg}`);
    }
  }
  if (options.overwrite && !options.apply) {
    throw new Error('--overwrite is only valid together with --apply');
  }
  options.project ||= process.env.FIREBASE_PROJECT_ID || process.env.GCLOUD_PROJECT || '';
  options.bucket ||= process.env.FIREBASE_STORAGE_BUCKET || defaultStorageBucket;
  return options;
}

function assert(condition, message, errors) {
  if (!condition) errors.push(message);
}

function parseJpegDimensions(buffer) {
  if (buffer.length < 4 || buffer[0] !== 0xff || buffer[1] !== 0xd8) {
    throw new Error('not a JPEG (missing SOI marker)');
  }
  let offset = 2;
  while (offset + 3 < buffer.length) {
    if (buffer[offset] !== 0xff) {
      offset += 1;
      continue;
    }
    const marker = buffer[offset + 1];
    offset += 2;
    if (marker === 0xd9 || marker === 0xda) break;
    if (marker === 0x00 || marker === 0xd8 || (marker >= 0xd0 && marker <= 0xd7)) continue;
    const segmentLength = buffer.readUInt16BE(offset);
    if (segmentLength < 2 || offset + segmentLength > buffer.length) {
      throw new Error('contains an invalid JPEG segment');
    }
    if ([0xc0, 0xc1, 0xc2, 0xc3, 0xc5, 0xc6, 0xc7, 0xc9, 0xca, 0xcb, 0xcd, 0xce, 0xcf].includes(marker)) {
      return {
        height: buffer.readUInt16BE(offset + 3),
        width: buffer.readUInt16BE(offset + 5),
      };
    }
    offset += segmentLength;
  }
  throw new Error('has no readable JPEG dimensions');
}

async function loadAndValidate() {
  const errors = [];
  let creators;
  try {
    creators = JSON.parse(await readFile(dataPath, 'utf8'));
  } catch (error) {
    throw new Error(`Unable to read ${dataPath}: ${error.message}`);
  }
  assert(Array.isArray(creators), 'creators.json must contain an array', errors);
  if (!Array.isArray(creators)) throw new Error(errors.join('\n'));

  const available = new Set(
    (await readdir(imageRoot)).filter((name) => name.toLowerCase().endsWith('.jpeg')),
  );
  const usedPhotos = new Set();
  const ids = new Set();
  const emails = new Set();
  const validated = [];

  for (const [index, creator] of creators.entries()) {
    const label = `entry ${index + 1}`;
    assert(creator && typeof creator === 'object' && !Array.isArray(creator), `${label} must be an object`, errors);
    if (!creator || typeof creator !== 'object' || Array.isArray(creator)) continue;
    assert(/^seed-creator-\d{3}$/.test(creator.id), `${label}.id must match seed-creator-NNN`, errors);
    assert(!ids.has(creator.id), `${label}.id is duplicated: ${creator.id}`, errors);
    ids.add(creator.id);
    assert(creator.id === `seed-creator-${String(index + 1).padStart(3, '0')}`,
      `${label}.id must be deterministic for its position`, errors);
    for (const field of ['name', 'email', 'city', 'state', 'talent', 'gender', 'bio']) {
      assert(typeof creator[field] === 'string' && creator[field].trim().length > 0,
        `${label}.${field} must be a non-empty string`, errors);
    }
    assert(Number.isInteger(creator.age) && creator.age >= 18 && creator.age <= 80,
      `${label}.age must be an integer from 18 to 80`, errors);
    assert(Array.isArray(creator.photos) && creator.photos.length > 0 && creator.photos.length <= maxPhotos,
      `${label}.photos must contain 1 to ${maxPhotos} file names`, errors);
    assert(!emails.has(creator.email), `${label}.email is duplicated: ${creator.email}`, errors);
    emails.add(creator.email);

    const localPhotos = [];
    for (const [photoIndex, fileName] of (creator.photos || []).entries()) {
      assert(typeof fileName === 'string' && /^model1 \(\d+\)\.jpeg$/.test(fileName),
        `${label}.photos[${photoIndex}] has an invalid name`, errors);
      assert(!usedPhotos.has(fileName), `${label}.photos[${photoIndex}] is duplicated: ${fileName}`, errors);
      usedPhotos.add(fileName);
      const imagePath = resolve(imageRoot, fileName);
      try {
        const info = await stat(imagePath);
        assert(info.isFile() && info.size > 1024, `${label} image is missing or too small`, errors);
        const image = await readFile(imagePath);
        const dimensions = parseJpegDimensions(image);
        assert(dimensions.width >= 200 && dimensions.height >= 200,
          `${label} image dimensions are unexpectedly small (${dimensions.width}x${dimensions.height})`, errors);
        localPhotos.push({
          fileName,
          localImagePath: imagePath,
          imageBytes: info.size,
          dimensions,
        });
      } catch (error) {
        errors.push(`${label} image ${fileName}: ${error.message}`);
      }
    }
    validated.push({ ...creator, localPhotos });
  }

  for (const fileName of available) {
    if (!usedPhotos.has(fileName)) {
      errors.push(`unused photo in demophotos_model: ${fileName}`);
    }
  }
  if (errors.length) throw new Error(`Validation failed (${errors.length} errors):\n- ${errors.join('\n- ')}`);
  return validated;
}

function deterministicToken(projectId, objectPath) {
  const hex = createHash('sha256').update(`${projectId}:${objectPath}`).digest('hex').slice(0, 32);
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-4${hex.slice(13, 16)}-a${hex.slice(17, 20)}-${hex.slice(20)}`;
}

function downloadUrl(bucket, objectPath, token) {
  return `https://firebasestorage.googleapis.com/v0/b/${encodeURIComponent(bucket)}/o/${encodeURIComponent(objectPath)}?alt=media&token=${token}`;
}

async function resolveCredentialsPath() {
  if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    return resolve(process.env.GOOGLE_APPLICATION_CREDENTIALS);
  }
  const localKey = resolve(here, 'serviceAccountKey.json');
  try {
    const info = await stat(localKey);
    if (info.isFile()) return localKey;
  } catch {
    // Fall through to a clearer apply-mode error.
  }
  throw new Error('GOOGLE_APPLICATION_CREDENTIALS is required with --apply, or place serviceAccountKey.json in scripts/');
}

async function initializeFirebase(options) {
  const credentialsPath = await resolveCredentialsPath();
  let serviceAccount;
  try {
    serviceAccount = JSON.parse(await readFile(credentialsPath, 'utf8'));
  } catch (error) {
    throw new Error(`Unable to read service account credentials: ${error.message}`);
  }
  if (!serviceAccount.project_id) throw new Error('Credential JSON has no project_id');
  const projectId = options.project || serviceAccount.project_id;
  if (projectId !== serviceAccount.project_id) {
    throw new Error(`Project mismatch: --project is ${projectId}, credentials are for ${serviceAccount.project_id}`);
  }
  if (!options.bucket) {
    throw new Error('Storage bucket is required via --bucket or FIREBASE_STORAGE_BUCKET');
  }
  const app = getApps()[0] || initializeApp({
    credential: cert(serviceAccount),
    projectId,
    storageBucket: options.bucket,
  });
  const bucket = getStorage(app).bucket(options.bucket);
  const [exists] = await bucket.exists();
  if (!exists) throw new Error(`Storage bucket does not exist or is inaccessible: ${options.bucket}`);
  return { projectId, bucket, db: getFirestore(app), auth: getAuth(app) };
}

function userDoc(creator, createdAt) {
  return {
    id: creator.id,
    name: creator.name,
    email: creator.email,
    mobile: '',
    role: 'influencer',
    is_active: true,
    birth_year: new Date().getFullYear() - creator.age,
    created_at: createdAt,
    updated_at: createdAt,
    seed_source: 'scripts/seed_creators',
  };
}

function profileDoc(creator, photoUrls) {
  return {
    user_id: creator.id,
    profile_image: photoUrls[0] || '',
    photos: photoUrls,
    is_verified: false,
    talent: creator.talent,
    bio: creator.bio,
    contact: '',
    city: creator.city,
    state: creator.state,
    age: creator.age,
    gender: creator.gender,
    languages: ['English', 'Hindi'],
    niches: [],
    platform_metrics: [],
    form_data: {
      personal: {
        about: creator.bio,
        gender: creator.gender,
        age: String(creator.age),
        location: `${creator.city}, ${creator.state}`,
        language: 'Hindi',
      },
      work: {
        role: 'UGC Creator',
        experience: 'Growing (1-3 yrs)',
      },
    },
    profile_completed: true,
    subscription_status: 'free',
    account_status: 'active',
    free_job_applications_used: 0,
    seed_source: 'scripts/seed_creators',
  };
}

async function applySeed(creators, options) {
  const { projectId, bucket, db, auth } = await initializeFirebase(options);
  const refs = creators.flatMap((creator) => [
    db.collection('users').doc(creator.id),
    db.collection('profiles').doc(creator.id),
  ]);
  const snapshots = await db.getAll(...refs);
  const existingIds = new Set();
  for (const snapshot of snapshots) {
    if (snapshot.exists) existingIds.add(snapshot.ref.id);
  }
  const selected = options.overwrite
    ? creators
    : creators.filter((creator) => !existingIds.has(creator.id));
  const skipped = creators.length - selected.length;
  console.log(`Target project: ${projectId}`);
  console.log(`Target bucket: gs://${bucket.name}`);
  console.log(`Existing seed docs: ${existingIds.size}; selected: ${selected.length}; skipped: ${skipped}`);

  const errors = [];
  let uploaded = 0;
  let written = 0;
  let authCreated = 0;

  for (const [index, creator] of selected.entries()) {
    try {
      const photoUrls = [];
      for (const [photoIndex, photo] of creator.localPhotos.entries()) {
        const objectPath = `users/${creator.id}/profile/photo-${photoIndex + 1}.jpeg`;
        const token = deterministicToken(projectId, objectPath);
        await bucket.upload(photo.localImagePath, {
          destination: objectPath,
          resumable: false,
          validation: 'crc32c',
          metadata: {
            contentType: 'image/jpeg',
            cacheControl: 'public,max-age=31536000,immutable',
            metadata: {
              firebaseStorageDownloadTokens: token,
              seedCreatorId: creator.id,
              sourceImage: basename(photo.localImagePath),
            },
          },
        });
        photoUrls.push(downloadUrl(bucket.name, objectPath, token));
        uploaded += 1;
      }

      const createdAt = new Date(Date.now() - index * 60_000).toISOString();
      try {
        await auth.createUser({
          uid: creator.id,
          email: creator.email,
          password: defaultPassword,
          displayName: creator.name,
          emailVerified: true,
        });
        authCreated += 1;
      } catch (error) {
        if (error.code === 'auth/uid-already-exists' || error.code === 'auth/email-already-exists') {
          if (options.overwrite) {
            await auth.updateUser(creator.id, {
              email: creator.email,
              password: defaultPassword,
              displayName: creator.name,
              emailVerified: true,
            });
          }
        } else {
          throw error;
        }
      }

      const batch = db.batch();
      batch.set(db.collection('users').doc(creator.id), userDoc(creator, createdAt), { merge: false });
      batch.set(db.collection('profiles').doc(creator.id), profileDoc(creator, photoUrls), { merge: false });
      await batch.commit();
      written += 1;
      console.log(`[${index + 1}/${selected.length}] ${creator.id} ${creator.name} (${photoUrls.length} photos)`);
    } catch (error) {
      errors.push({ id: creator.id, message: error.message });
      console.error(`[seed:error] ${creator.id}: ${error.message}`);
    }
  }

  return {
    projectId,
    bucket: bucket.name,
    total: creators.length,
    selected: selected.length,
    skipped,
    uploaded,
    written,
    authCreated,
    errors,
  };
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  if (options.help) {
    console.log(usage());
    return;
  }
  const creators = await loadAndValidate();
  const totalBytes = creators.reduce(
    (sum, creator) => sum + creator.localPhotos.reduce((inner, photo) => inner + photo.imageBytes, 0),
    0,
  );
  const photoCount = creators.reduce((sum, creator) => sum + creator.localPhotos.length, 0);
  console.log(`Validated ${creators.length} creators and ${photoCount} JPEGs (${(totalBytes / 1024 / 1024).toFixed(2)} MiB).`);
  if (!options.apply) {
    console.log('Dry run complete. No Firebase calls or writes were made.');
    console.log('Run with --apply --project talenthire-d86a1 to seed.');
    return;
  }
  const summary = await applySeed(creators, options);
  console.log(`Summary: ${JSON.stringify(summary, null, 2)}`);
  if (summary.errors.length) process.exitCode = 1;
}

main().catch((error) => {
  console.error(`ERROR: ${error.message}`);
  process.exitCode = 1;
});
