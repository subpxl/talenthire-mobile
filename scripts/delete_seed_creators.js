#!/usr/bin/env node
/**
 * Delete documents created by seed_creators.js (Auth + users + profiles).
 *
 *   node delete_seed_creators.js --project telefone-b3feb
 *   node delete_seed_creators.js --project telefone-b3feb --apply
 *
 * Matches (same markers as seed_creators.js):
 *   - IDs listed in data/creators.json (seed-creator-NNN)
 *   - users/profiles with seed_source === 'scripts/seed_creators'
 *   - users with email ending in @example.com (Telefone demo accounts)
 */

import { readFileSync, existsSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { applicationDefault, cert, getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';

const here = dirname(fileURLToPath(import.meta.url));
const creatorsPath = resolve(here, 'data', 'creators.json');
const defaultKeyPath = resolve(here, 'serviceAccountKey.json');
const SEED_SOURCE = 'scripts/seed_creators';

function usage() {
  console.log(`Usage: node delete_seed_creators.js [options]

  --apply           Delete (default: dry-run list only)
  --project <id>    Firebase project ID (default: telefone-b3feb)
  --adc             Use gcloud/Firebase CLI credentials (not serviceAccountKey.json)
  --help            Show help`);
}

function parseArgs(argv) {
  const options = {
    apply: false,
    adc: false,
    project: process.env.FIREBASE_PROJECT_ID || process.env.GCLOUD_PROJECT || '',
  };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === '--apply') options.apply = true;
    else if (arg === '--adc') options.adc = true;
    else if (arg === '--help' || arg === '-h') options.help = true;
    else if (arg === '--project') {
      options.project = argv[++i] || '';
    } else {
      throw new Error(`Unknown option: ${arg}`);
    }
  }
  if (!options.project) options.project = 'telefone-b3feb';
  return options;
}

function loadSeedIds() {
  const raw = readFileSync(creatorsPath, 'utf8');
  const creators = JSON.parse(raw);
  return new Set(creators.map((c) => c.id));
}

function initializeFirebase(projectId, useAdc) {
  if (getApps().length > 0) {
    return { db: getFirestore(), auth: getAuth() };
  }
  if (useAdc) {
    initializeApp({ credential: applicationDefault(), projectId });
    return { db: getFirestore(), auth: getAuth() };
  }
  const keyPath = process.env.GOOGLE_APPLICATION_CREDENTIALS || defaultKeyPath;
  if (!existsSync(keyPath)) {
    throw new Error(`Missing service account: ${keyPath} (or pass --adc after firebase login)`);
  }
  const serviceAccount = JSON.parse(readFileSync(keyPath, 'utf8'));
  if (serviceAccount.project_id && serviceAccount.project_id !== projectId) {
    console.warn(
      `Warning: key project_id=${serviceAccount.project_id} differs from --project ${projectId}. Use --adc for Telefone.`,
    );
  }
  initializeApp({ credential: cert(serviceAccount), projectId });
  return { db: getFirestore(), auth: getAuth() };
}

async function deletePaymentItems(db, uid) {
  const snap = await db.collection('payment_items').where('creator_id', '==', uid).get();
  if (snap.empty) return 0;
  const batch = db.batch();
  for (const doc of snap.docs) batch.delete(doc.ref);
  await batch.commit();
  return snap.size;
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  if (options.help) {
    usage();
    return;
  }

  const seedIdsFromFile = loadSeedIds();
  const { db, auth } = initializeFirebase(options.project, options.adc);

  console.log(`Project: ${options.project}`);
  console.log(`Seed IDs in creators.json: ${seedIdsFromFile.size}`);
  console.log(options.apply ? 'Mode: APPLY' : 'Mode: dry-run');

  const [usersSnap, profilesSnap] = await Promise.all([
    db.collection('users').get(),
    db.collection('profiles').get(),
  ]);

  const toRemove = new Set(seedIdsFromFile);

  for (const doc of usersSnap.docs) {
    const data = doc.data();
    if (data?.seed_source === SEED_SOURCE) toRemove.add(doc.id);
    const email = (data?.email ?? '').toString().trim().toLowerCase();
    if (email.endsWith('@example.com')) toRemove.add(doc.id);
  }
  for (const doc of profilesSnap.docs) {
    if (doc.data()?.seed_source === SEED_SOURCE) toRemove.add(doc.id);
  }

  const ids = [...toRemove].sort();
  if (ids.length === 0) {
    console.log('No seed creators to remove.');
    return;
  }

  for (const uid of ids) {
    const u = usersSnap.docs.find((d) => d.id === uid)?.data();
    const p = profilesSnap.docs.find((d) => d.id === uid)?.data();
    const inFile = seedIdsFromFile.has(uid);
    const tagged = u?.seed_source === SEED_SOURCE || p?.seed_source === SEED_SOURCE;
    console.log(
      `  ${uid}  file=${inFile}  tagged=${tagged}  email=${u?.email ?? '-'}`,
    );
  }

  if (!options.apply) {
    console.log('\nAdd --apply to delete these accounts.');
    return;
  }

  let stats = { users: 0, profiles: 0, items: 0, auth: 0 };

  for (const uid of ids) {
    const userRef = db.collection('users').doc(uid);
    const profileRef = db.collection('profiles').doc(uid);
    const [userDoc, profileDoc] = await Promise.all([userRef.get(), profileRef.get()]);
    if (userDoc.exists) {
      await userRef.delete();
      stats.users += 1;
    }
    if (profileDoc.exists) {
      await profileRef.delete();
      stats.profiles += 1;
    }
    stats.items += await deletePaymentItems(db, uid);
    try {
      await auth.deleteUser(uid);
      stats.auth += 1;
    } catch (e) {
      if (e.code !== 'auth/user-not-found') {
        console.warn(`[auth] ${uid}: ${e.message}`);
      }
    }
  }

  console.log(`\nDeleted: ${JSON.stringify(stats)}`);
}

main().catch((err) => {
  console.error(err.message || err);
  process.exitCode = 1;
});
