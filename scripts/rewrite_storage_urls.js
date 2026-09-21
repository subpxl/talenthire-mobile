#!/usr/bin/env node

import { readFile } from 'node:fs/promises';
import { resolve as resolvePath, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { cert, getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { firebaseObjectPathFromUrl, publicObjectUrl } from './lib/spaces.js';

const here = dirname(fileURLToPath(import.meta.url));

function rewriteValue(value) {
  if (typeof value !== 'string' || !value.includes('firebasestorage.googleapis.com')) {
    return value;
  }
  const objectPath = firebaseObjectPathFromUrl(value);
  if (!objectPath) return value;
  return publicObjectUrl(objectPath);
}

function rewriteDeep(value) {
  if (typeof value === 'string') return rewriteValue(value);
  if (Array.isArray(value)) return value.map(rewriteDeep);
  if (value && typeof value === 'object') {
    const out = {};
    for (const [key, nested] of Object.entries(value)) {
      out[key] = rewriteDeep(nested);
    }
    return out;
  }
  return value;
}

function patchDocument(data) {
  const next = { ...data };
  let changed = false;

  const urlFields = [
    'image_url', 'banner_url', 'bannerUrl', 'profile_image', 'profileImage',
    'imageUrl', 'thumbUrl', 'photo_url', 'photoUrl', 'image_path',
  ];
  for (const field of urlFields) {
    if (typeof next[field] === 'string' && next[field].includes('firebasestorage.googleapis.com')) {
      next[field] = rewriteValue(next[field]);
      changed = true;
    }
  }

  for (const field of ['photos', 'photoThumbs', 'photo_thumbs', 'gallery_photos']) {
    if (Array.isArray(next[field])) {
      const rewritten = next[field].map((item) => rewriteValue(item));
      if (JSON.stringify(rewritten) !== JSON.stringify(next[field])) {
        next[field] = rewritten;
        changed = true;
      }
    }
  }

  if (next.form_data) {
    const rewrittenForm = rewriteDeep(next.form_data);
    if (JSON.stringify(rewrittenForm) !== JSON.stringify(next.form_data)) {
      next.form_data = rewrittenForm;
      changed = true;
    }
  }

  return changed ? next : null;
}

async function initializeFirebase() {
  let credentialsPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  if (!credentialsPath) {
    credentialsPath = resolvePath(here, 'serviceAccountKey.json');
  }
  const serviceAccount = JSON.parse(await readFile(resolvePath(credentialsPath), 'utf8'));
  const app = getApps()[0] || initializeApp({
    credential: cert(serviceAccount),
    projectId: serviceAccount.project_id,
  });
  return getFirestore(app);
}

async function rewriteCollection(db, collectionName, apply) {
  const snap = await db.collection(collectionName).get();
  let scanned = 0;
  let updated = 0;

  for (const doc of snap.docs) {
    scanned += 1;
    const patched = patchDocument(doc.data());
    if (!patched) continue;
    updated += 1;
    if (apply) {
      await doc.ref.set(patched, { merge: true });
    } else {
      console.log(`[dry-run] ${collectionName}/${doc.id}`);
    }
  }

  return { scanned, updated };
}

async function main() {
  const apply = process.argv.includes('--apply');
  const db = await initializeFirebase();
  const collections = ['jobs', 'profiles', 'users', 'agencies', 'conversations', 'banners'];

  let totalUpdated = 0;
  for (const collectionName of collections) {
    const result = await rewriteCollection(db, collectionName, apply);
    console.log(`${collectionName}: scanned=${result.scanned} updated=${result.updated}`);
    totalUpdated += result.updated;
  }

  console.log(`\nTotal documents ${apply ? 'updated' : 'to update'}: ${totalUpdated}`);
  if (!apply) console.log('Re-run with --apply to write Firestore changes.');
}

main().catch((error) => {
  console.error(error.message || error);
  process.exit(1);
});
