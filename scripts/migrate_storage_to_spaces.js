#!/usr/bin/env node

import { readFile } from 'node:fs/promises';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { cert, getApps, initializeApp } from 'firebase-admin/app';
import { getStorage } from 'firebase-admin/storage';
import {
  SPACES_BUCKET,
  createSpacesClient,
  listAllObjects,
  publicObjectUrl,
  uploadBuffer,
} from './lib/spaces.js';

const here = dirname(fileURLToPath(import.meta.url));
const GCP_BUCKET = process.env.FIREBASE_STORAGE_BUCKET
  || 'talenthire-d86a1.firebasestorage.app';

async function resolveCredentialsPath() {
  if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    return resolve(process.env.GOOGLE_APPLICATION_CREDENTIALS);
  }
  return resolve(here, 'serviceAccountKey.json');
}

async function initializeGcpBucket() {
  const credentialsPath = await resolveCredentialsPath();
  const serviceAccount = JSON.parse(await readFile(credentialsPath, 'utf8'));
  const app = getApps()[0] || initializeApp({
    credential: cert(serviceAccount),
    projectId: serviceAccount.project_id,
    storageBucket: GCP_BUCKET,
  });
  return getStorage(app).bucket(GCP_BUCKET);
}

async function listGcpObjects(bucket) {
  const [files] = await bucket.getFiles({ autoPaginate: true });
  return files.map((file) => file.name).filter(Boolean);
}

function guessContentType(objectPath) {
  if (objectPath.endsWith('.jpeg') || objectPath.endsWith('.jpg')) return 'image/jpeg';
  if (objectPath.endsWith('.png')) return 'image/png';
  if (objectPath.endsWith('.webp')) return 'image/webp';
  return 'application/octet-stream';
}

async function main() {
  const apply = process.argv.includes('--apply');
  const client = createSpacesClient();
  const existing = new Set(await listAllObjects(client));
  console.log(`DO Spaces bucket: ${SPACES_BUCKET} (${existing.size} existing objects)`);

  const gcpBucket = await initializeGcpBucket();
  const objectPaths = await listGcpObjects(gcpBucket);
  console.log(`Found ${objectPaths.length} objects in gs://${GCP_BUCKET}.`);

  let uploaded = 0;
  let skipped = 0;
  for (const objectPath of objectPaths) {
    if (existing.has(objectPath)) {
      skipped += 1;
      continue;
    }
    const [buffer] = await gcpBucket.file(objectPath).download();
    const contentType = guessContentType(objectPath);
    if (apply) {
      await uploadBuffer(client, buffer, objectPath, contentType);
      uploaded += 1;
      if (uploaded % 10 === 0) {
        console.log(`Uploaded ${uploaded}/${objectPaths.length - skipped}...`);
      }
    } else {
      console.log(`[dry-run] ${objectPath} (${buffer.length} bytes)`);
      uploaded += 1;
    }
  }

  console.log('\nMigration summary');
  console.log(`  uploaded: ${uploaded}`);
  console.log(`  skipped (already in DO): ${skipped}`);
  if (!apply) {
    console.log('\nRe-run with --apply to upload.');
  } else {
    console.log(`\nSample CDN URL: ${publicObjectUrl('job-images/seed-job-001/poster.jpeg')}`);
  }
}

main().catch((error) => {
  console.error(error.message || error);
  process.exit(1);
});
