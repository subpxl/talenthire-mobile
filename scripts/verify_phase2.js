#!/usr/bin/env node

import { readFile } from 'node:fs/promises';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { cert, getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { createSpacesClient, listAllObjects, publicObjectUrl } from './lib/spaces.js';

const here = dirname(fileURLToPath(import.meta.url));
const cdnHost = 'talenthire-media.sgp1.cdn.digitaloceanspaces.com';

async function initFirestore() {
  const credPath = process.env.GOOGLE_APPLICATION_CREDENTIALS
    || resolve(here, 'serviceAccountKey.json');
  const serviceAccount = JSON.parse(await readFile(credPath, 'utf8'));
  const app = getApps()[0] || initializeApp({
    credential: cert(serviceAccount),
    projectId: serviceAccount.project_id,
  });
  return getFirestore(app);
}

async function main() {
  const client = createSpacesClient();
  const keys = await listAllObjects(client);
  console.log(`DO objects: ${keys.length}`);

  const sample = keys.find((k) => k.startsWith('job-images/')) || keys[0];
  const sampleRes = await fetch(publicObjectUrl(sample));
  console.log(`CDN sample (${sample}): HTTP ${sampleRes.status}`);

  const db = await initFirestore();
  const jobs = await db.collection('jobs').limit(5).get();
  let cdnJobs = 0;
  let legacyJobs = 0;
  for (const doc of jobs.docs) {
    const url = String(doc.data().image_url || '');
    if (url.includes(cdnHost)) cdnJobs += 1;
    if (url.includes('firebasestorage.googleapis.com')) legacyJobs += 1;
  }

  const profiles = await db.collection('profiles').limit(20).get();
  let cdnProfiles = 0;
  let legacyProfiles = 0;
  for (const doc of profiles.docs) {
    for (const url of [doc.data().profile_image, ...(doc.data().photos || [])]) {
      const s = String(url || '');
      if (s.includes(cdnHost)) cdnProfiles += 1;
      if (s.includes('firebasestorage.googleapis.com')) legacyProfiles += 1;
    }
  }

  console.log(`Jobs sample: ${cdnJobs} CDN, ${legacyJobs} legacy Firebase URLs`);
  console.log(`Profiles sample: ${cdnProfiles} CDN, ${legacyProfiles} legacy Firebase URLs`);

  const ok = sampleRes.ok && cdnJobs > 0 && legacyJobs === 0;
  console.log(`\nPhase 2: ${ok ? 'COMPLETE' : 'NEEDS ATTENTION'}`);
  process.exitCode = ok ? 0 : 1;
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
