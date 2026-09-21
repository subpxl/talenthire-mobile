#!/usr/bin/env node

import { readFile, stat } from 'node:fs/promises';
import { resolve, dirname, basename } from 'node:path';
import { fileURLToPath } from 'node:url';
import { cert, getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { createSpacesClient, publicObjectUrl, uploadBuffer } from './lib/spaces.js';

const here = dirname(fileURLToPath(import.meta.url));
const dataPath = resolve(here, 'data', 'jobs.json');
const imageRoot = resolve(here, 'job-posters');
const defaultSpacesBucket = 'talenthire-media';
const requiredFields = [
  'id', 'title', 'summary', 'description', 'company', 'location_type',
  'location', 'status', 'posted_at', 'application_deadline', 'created_by',
  'agencyId', 'salary', 'tags', 'applied', 'views', 'level', 'urgent',
  'requirements', 'is_audition', 'isAudition', 'image_url', 'image_path',
  'banner_url', 'bannerUrl', 'category', 'artist_type', 'artistType',
  'platforms', 'collaboration_type', 'compensation', 'deliverables',
  'is_verified', 'source_image', 'pay_min', 'pay_max', 'min_followers',
  'gender', 'gender_required', 'age', 'age_min', 'age_max',
  'job_youtube_link', 'jobYoutubeLink', 'interview_video_link',
  'audition_script', 'auditionScript', 'projectId', 'projectName',
  'projectTag', 'initials',
];
const stringFields = requiredFields.filter((field) => ![
  'tags', 'platforms', 'deliverables', 'applied', 'views', 'urgent',
  'is_audition', 'isAudition', 'is_verified', 'pay_min', 'pay_max',
  'min_followers', 'age_min', 'age_max', 'gender_required',
  'job_youtube_link', 'jobYoutubeLink', 'interview_video_link',
  'audition_script', 'auditionScript',
].includes(field));
const booleanFields = ['urgent', 'is_audition', 'isAudition', 'is_verified'];
const integerFields = ['applied', 'views', 'pay_min', 'pay_max', 'min_followers'];
const nullableIntegerFields = ['age_min', 'age_max'];
const nullableStringFields = [
  'gender_required', 'job_youtube_link', 'jobYoutubeLink',
  'interview_video_link', 'audition_script', 'auditionScript',
];
const arrayFields = ['tags', 'platforms', 'deliverables'];

function usage() {
  return `Usage: node seed_jobs.js [options]

Dry-run validation is the default and does not contact Firebase.

  --apply             Upload images and write Firestore documents
  --overwrite         Replace existing job documents (requires --apply)
  --project <id>      Expected Firebase project ID
  --bucket <name>     DigitalOcean Spaces bucket name
  --help              Show this help

Apply mode requires GOOGLE_APPLICATION_CREDENTIALS. Project and bucket may be supplied through
GCLOUD_PROJECT/FIREBASE_PROJECT_ID and DO_SPACES_BUCKET.`;
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
  options.bucket ||= process.env.DO_SPACES_BUCKET || defaultSpacesBucket;
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
  let jobs;
  try {
    jobs = JSON.parse(await readFile(dataPath, 'utf8'));
  } catch (error) {
    throw new Error(`Unable to read ${dataPath}: ${error.message}`);
  }
  assert(Array.isArray(jobs), 'jobs.json must contain an array', errors);
  if (!Array.isArray(jobs)) throw new Error(errors.join('\n'));
  assert(jobs.length === 66, `jobs.json must contain exactly 66 entries; found ${jobs.length}`, errors);

  const ids = new Set();
  const images = new Set();
  const validated = [];
  for (const [index, job] of jobs.entries()) {
    const label = `entry ${index + 1}`;
    assert(job && typeof job === 'object' && !Array.isArray(job), `${label} must be an object`, errors);
    if (!job || typeof job !== 'object' || Array.isArray(job)) continue;
    for (const field of requiredFields) {
      assert(Object.hasOwn(job, field), `${label} is missing ${field}`, errors);
    }
    const extras = Object.keys(job).filter((key) => !requiredFields.includes(key));
    assert(extras.length === 0, `${label} has unsupported fields: ${extras.join(', ')}`, errors);
    for (const field of stringFields) {
      assert(typeof job[field] === 'string', `${label}.${field} must be a string`, errors);
    }
    for (const field of booleanFields) {
      assert(typeof job[field] === 'boolean', `${label}.${field} must be a boolean`, errors);
    }
    for (const field of integerFields) {
      assert(Number.isInteger(job[field]) && job[field] >= 0, `${label}.${field} must be a non-negative integer`, errors);
    }
    for (const field of nullableIntegerFields) {
      assert(
        job[field] === null || (Number.isInteger(job[field]) && job[field] >= 0),
        `${label}.${field} must be null or a non-negative integer`,
        errors,
      );
    }
    for (const field of nullableStringFields) {
      assert(
        job[field] === null || typeof job[field] === 'string',
        `${label}.${field} must be null or a string`,
        errors,
      );
    }
    assert(job.is_audition === job.isAudition, `${label}.is_audition must match isAudition`, errors);
    assert(job.artist_type === job.artistType, `${label}.artist_type must match artistType`, errors);
    assert(job.category === job.artist_type, `${label}.category must match artist_type`, errors);
    assert(job.banner_url === job.bannerUrl, `${label}.banner_url must match bannerUrl`, errors);
    assert(job.audition_script === job.auditionScript, `${label}.audition_script must match auditionScript`, errors);
    assert(job.job_youtube_link === job.jobYoutubeLink, `${label}.job_youtube_link must match jobYoutubeLink`, errors);
    for (const field of arrayFields) {
      assert(Array.isArray(job[field]) && job[field].every((item) => typeof item === 'string' && item.length > 0),
        `${label}.${field} must be an array of non-empty strings`, errors);
    }
    assert(/^seed-job-\d{3}$/.test(job.id), `${label}.id must match seed-job-NNN`, errors);
    assert(!ids.has(job.id), `${label}.id is duplicated: ${job.id}`, errors);
    ids.add(job.id);
    assert(/^job \(\d+\)\.jpeg$/.test(job.source_image), `${label}.source_image has an invalid name`, errors);
    assert(!images.has(job.source_image), `${label}.source_image is duplicated: ${job.source_image}`, errors);
    images.add(job.source_image);
    assert(job.image_path === `job-images/${job.id}/poster.jpeg`,
      `${label}.image_path must be job-images/${job.id}/poster.jpeg`, errors);
    assert(job.image_url === '', `${label}.image_url must be empty before upload`, errors);
    assert(job.created_by === '', `${label}.created_by must be empty for ownerless seed data`, errors);
    assert(job.agencyId === '', `${label}.agencyId must be empty for ownerless seed data`, errors);
    assert(job.projectId === '', `${label}.projectId must be empty for ownerless seed data`, errors);
    assert(['remote', 'online', 'onsite'].includes(job.location_type), `${label}.location_type is invalid`, errors);
    assert(['draft', 'published', 'closed', 'cancelled'].includes(job.status), `${label}.status is invalid`, errors);
    assert(typeof job.level === 'string', `${label}.level must be a string`, errors);
    assert(typeof job.initials === 'string', `${label}.initials must be a string`, errors);
    assert(typeof job.projectName === 'string', `${label}.projectName must be a string`, errors);
    assert(typeof job.projectTag === 'string', `${label}.projectTag must be a string`, errors);
    assert(typeof job.age === 'string', `${label}.age must be a string`, errors);
    assert(typeof job.gender === 'string', `${label}.gender must be a string`, errors);
    assert(job.banner_url === '', `${label}.banner_url must be empty before upload`, errors);
    assert(job.bannerUrl === '', `${label}.bannerUrl must be empty before upload`, errors);
    assert(job.title?.trim().length >= 5, `${label}.title is too short`, errors);
    assert(job.summary?.trim().length >= 10, `${label}.summary is too short`, errors);
    assert(job.description?.trim().length >= 20, `${label}.description is too short`, errors);
    assert(job.company?.trim().length >= 2, `${label}.company is too short`, errors);
    assert(job.requirements?.trim().length >= 10, `${label}.requirements is too short`, errors);
    const posted = Date.parse(job.posted_at);
    const deadline = Date.parse(job.application_deadline);
    assert(Number.isFinite(posted), `${label}.posted_at is not an ISO date`, errors);
    assert(Number.isFinite(deadline), `${label}.application_deadline is not an ISO date`, errors);
    assert(!Number.isFinite(posted) || !Number.isFinite(deadline) || deadline > posted,
      `${label}.application_deadline must be after posted_at`, errors);

    const expectedNumber = index + 1;
    assert(job.id === `seed-job-${String(expectedNumber).padStart(3, '0')}`,
      `${label}.id must be deterministic for its position`, errors);
    assert(job.source_image === `job (${expectedNumber}).jpeg`,
      `${label}.source_image must match its position`, errors);

    const imagePath = resolve(imageRoot, job.source_image);
    try {
      const info = await stat(imagePath);
      assert(info.isFile() && info.size > 1024, `${label} image is missing or too small`, errors);
      const image = await readFile(imagePath);
      const dimensions = parseJpegDimensions(image);
      assert(dimensions.width >= 500 && dimensions.height >= 500,
        `${label} image dimensions are unexpectedly small (${dimensions.width}x${dimensions.height})`, errors);
      validated.push({ ...job, localImagePath: imagePath, imageBytes: info.size, dimensions });
    } catch (error) {
      errors.push(`${label} image ${job.source_image}: ${error.message}`);
    }
  }
  for (let number = 1; number <= 66; number += 1) {
    assert(images.has(`job (${number}).jpeg`), `dataset does not map job (${number}).jpeg`, errors);
  }
  if (errors.length) throw new Error(`Validation failed (${errors.length} errors):\n- ${errors.join('\n- ')}`);
  return validated;
}

function firestoreData(job, url) {
  const { localImagePath, imageBytes, dimensions, source_image: sourceImage, ...data } = job;
  return {
    ...data,
    image_url: url,
    banner_url: url,
    bannerUrl: url,
    posted_at: Timestamp.fromDate(new Date(data.posted_at)),
    application_deadline: Timestamp.fromDate(new Date(data.application_deadline)),
    seed_source: 'scripts/seed_jobs',
    source_image: sourceImage,
  };
}

async function initializeFirebase(options) {
  const credentialsPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  if (!credentialsPath) {
    throw new Error('GOOGLE_APPLICATION_CREDENTIALS is required with --apply');
  }
  const absoluteCredentialsPath = resolve(credentialsPath);
  let serviceAccount;
  try {
    serviceAccount = JSON.parse(await readFile(absoluteCredentialsPath, 'utf8'));
  } catch (error) {
    throw new Error(`Unable to read GOOGLE_APPLICATION_CREDENTIALS: ${error.message}`);
  }
  if (!serviceAccount.project_id) throw new Error('Credential JSON has no project_id');
  const projectId = options.project || serviceAccount.project_id;
  if (projectId !== serviceAccount.project_id) {
    throw new Error(`Project mismatch: --project is ${projectId}, credentials are for ${serviceAccount.project_id}`);
  }
  if (!options.bucket) {
    throw new Error('Spaces bucket is required via --bucket or DO_SPACES_BUCKET');
  }
  if (!/^[a-z0-9][a-z0-9._-]+$/i.test(options.bucket)) throw new Error(`Invalid bucket name: ${options.bucket}`);
  const app = getApps()[0] || initializeApp({
    credential: cert(serviceAccount),
    projectId,
  });
  const accessToken = await app.options.credential.getAccessToken();
  if (!accessToken?.access_token) throw new Error('Could not obtain a Google access token');
  const projectResponse = await fetch(
    `https://cloudresourcemanager.googleapis.com/v1/projects/${encodeURIComponent(projectId)}`,
    { headers: { Authorization: `Bearer ${accessToken.access_token}` } },
  );
  if (!projectResponse.ok) {
    throw new Error(`Could not verify Firebase project ${projectId}: HTTP ${projectResponse.status}`);
  }
  const projectMetadata = await projectResponse.json();
  if (projectMetadata.projectId !== projectId || !projectMetadata.projectNumber) {
    throw new Error(`Google Cloud returned inconsistent metadata for project ${projectId}`);
  }
  const spacesClient = createSpacesClient();
  return { projectId, bucket: options.bucket, spacesClient, db: getFirestore(app) };
}

async function applySeed(jobs, options) {
  const { projectId, bucket, spacesClient, db } = await initializeFirebase(options);
  const refs = jobs.map((job) => db.collection('jobs').doc(job.id));
  const snapshots = await db.getAll(...refs);
  const existingIds = new Set(snapshots.filter((snapshot) => snapshot.exists).map((snapshot) => snapshot.id));
  const selected = options.overwrite ? jobs : jobs.filter((job) => !existingIds.has(job.id));
  const skipped = jobs.length - selected.length;
  console.log(`Target project: ${projectId}`);
  console.log(`Target bucket: ${bucket} (DO Spaces)`);
  console.log(`Existing documents: ${existingIds.size}; selected: ${selected.length}; skipped: ${skipped}`);

  const prepared = [];
  const errors = [];
  for (const [index, job] of selected.entries()) {
    try {
      const imageBytes = await readFile(job.localImagePath);
      const url = await uploadBuffer(spacesClient, imageBytes, job.image_path, 'image/jpeg');
      prepared.push({ job, data: firestoreData(job, url) });
      console.log(`[${index + 1}/${selected.length}] uploaded ${job.image_path}`);
    } catch (error) {
      errors.push({ id: job.id, phase: 'upload', message: error.message });
      console.error(`[upload:error] ${job.id}: ${error.message}`);
    }
  }

  let written = 0;
  for (let offset = 0; offset < prepared.length; offset += 400) {
    const chunk = prepared.slice(offset, offset + 400);
    try {
      const batch = db.batch();
      for (const item of chunk) {
        batch.set(db.collection('jobs').doc(item.job.id), item.data, { merge: false });
      }
      await batch.commit();
      written += chunk.length;
    } catch (error) {
      for (const item of chunk) errors.push({ id: item.job.id, phase: 'firestore', message: error.message });
      console.error(`[firestore:error] batch at ${offset}: ${error.message}`);
    }
  }
  return { projectId, bucket, total: jobs.length, selected: selected.length, skipped, uploaded: prepared.length, written, errors };
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  if (options.help) {
    console.log(usage());
    return;
  }
  const jobs = await loadAndValidate();
  const totalBytes = jobs.reduce((sum, job) => sum + job.imageBytes, 0);
  console.log(`Validated ${jobs.length} jobs and ${jobs.length} JPEGs (${(totalBytes / 1024 / 1024).toFixed(2)} MiB).`);
  if (!options.apply) {
    console.log('Dry run complete. No Firebase calls or writes were made.');
    console.log('Run with --apply --project <id> --bucket <name> to seed.');
    return;
  }
  const summary = await applySeed(jobs, options);
  console.log(`Summary: ${JSON.stringify(summary, null, 2)}`);
  if (summary.errors.length) process.exitCode = 1;
}

main().catch((error) => {
  console.error(`ERROR: ${error.message}`);
  process.exitCode = 1;
});
