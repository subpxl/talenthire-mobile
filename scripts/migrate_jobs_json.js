#!/usr/bin/env node

/**
 * One-time migration: align jobs.json with the current JobPostForm / jobToFirestore schema.
 * Keeps existing titles, images, and poster mappings unchanged.
 */

import { readFile, writeFile } from 'node:fs/promises';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const dataPath = resolve(here, 'data', 'jobs.json');

const ARTIST_TYPES = new Set([
  'Actor', 'Singer', 'Dancer', 'Model', 'Influencer', 'Voice Artist',
  'Anchor / Host', 'Musician', 'Comedian', 'Stunt Performer', 'Other',
]);

function rupeeAmounts(text) {
  return [...`${text}`.matchAll(/₹\s*([\d,]+)/g)]
    .map((match) => Number.parseInt(match[1].replaceAll(',', ''), 10))
    .filter((value) => value > 0);
}

function payRange(job) {
  const parsed = rupeeAmounts(`${job.compensation} ${job.salary}`);
  if (parsed.length >= 2) return [parsed[0], parsed[parsed.length - 1]];
  if (parsed.length === 1) return [parsed[0], parsed[0]];
  if (job.collaboration_type === 'paid') return [15000, 40000];
  return [0, 0];
}

function minFollowers(category) {
  switch (category.trim().toLowerCase()) {
    case 'influencer': return 10000;
    case 'model': return 5000;
    default: return 0;
  }
}

function inferGender(title, description) {
  const text = `${title} ${description}`.toLowerCase();
  const hasFemale = /\bfemale\b|\bwomen\b|\bgirl\b|\blady\b|\bactress\b/.test(text);
  const hasMale = /\bmale\b|\bmen\b|\bboy\b|\bactor\b(?!ess)/.test(text);
  if (hasFemale && !hasMale) return 'female';
  if (hasMale && !hasFemale) return 'male';
  return '';
}

function inferAgeRange(title, description) {
  const text = `${title} ${description}`.toLowerCase();
  if (/kids|children|child|youth|teen/.test(text)) return [5, 18];
  if (/senior|elderly|60\+/.test(text)) return [55, 70];
  if (/young adult|18-/.test(text)) return [18, 30];
  return [null, null];
}

function normalizeArtistType(category) {
  const trimmed = `${category}`.trim();
  if (ARTIST_TYPES.has(trimmed)) return trimmed;
  const lower = trimmed.toLowerCase();
  for (const type of ARTIST_TYPES) {
    if (type.toLowerCase() === lower) return type;
  }
  if (/voice/i.test(trimmed)) return 'Voice Artist';
  if (/host|anchor/i.test(trimmed)) return 'Anchor / Host';
  if (/influenc/i.test(trimmed)) return 'Influencer';
  if (/model/i.test(trimmed)) return 'Model';
  if (/danc/i.test(trimmed)) return 'Dancer';
  if (/sing/i.test(trimmed)) return 'Singer';
  if (/actor|actress|cast/i.test(trimmed)) return 'Actor';
  return trimmed || 'Other';
}

function auditionScript(job) {
  if (!job.is_audition) return null;
  return [
    `Introduce yourself in 10 seconds.`,
    `Perform a short scene relevant to "${job.title}".`,
    `Show your best side to camera and state your location.`,
  ].join(' ');
}

function migrateJob(job) {
  const artistType = normalizeArtistType(job.category);
  const [payMin, payMax] = payRange(job);
  const [ageMin, ageMax] = inferAgeRange(job.title, job.description);
  const gender = inferGender(job.title, job.description);
  const age =
    ageMin != null && ageMax != null ? `${ageMin}-${ageMax}`
      : ageMin != null ? `${ageMin}+`
        : ageMax != null ? `Up to ${ageMax}` : '';

  return {
    id: job.id,
    title: job.title,
    summary: job.summary,
    description: job.description,
    company: job.company,
    location_type: job.location_type,
    location: job.location,
    status: job.status,
    posted_at: job.posted_at,
    application_deadline: job.application_deadline,
    created_by: '',
    agencyId: '',
    salary: job.salary,
    tags: job.tags,
    applied: job.applied ?? 0,
    views: job.views ?? 0,
    urgent: job.urgent ?? false,
    requirements: job.requirements,
    is_audition: job.is_audition,
    isAudition: job.is_audition,
    image_url: '',
    image_path: job.image_path,
    banner_url: '',
    bannerUrl: '',
    category: artistType,
    artist_type: artistType,
    artistType,
    platforms: job.platforms,
    collaboration_type: job.collaboration_type,
    compensation: job.compensation,
    deliverables: job.deliverables,
    is_verified: job.is_verified ?? false,
    source_image: job.source_image,
    pay_min: payMin,
    pay_max: payMax,
    min_followers: minFollowers(artistType),
    gender,
    gender_required: gender || null,
    age,
    age_min: ageMin,
    age_max: ageMax,
    job_youtube_link: null,
    jobYoutubeLink: null,
    interview_video_link: null,
    audition_script: auditionScript(job),
    auditionScript: auditionScript(job),
    projectId: '',
    projectName: '',
    projectTag: '',
    level: '',
    initials: '',
  };
}

async function main() {
  const jobs = JSON.parse(await readFile(dataPath, 'utf8'));
  if (!Array.isArray(jobs)) throw new Error('jobs.json must be an array');
  const migrated = jobs.map(migrateJob);
  await writeFile(dataPath, `${JSON.stringify(migrated, null, 2)}\n`, 'utf8');
  console.log(`Migrated ${migrated.length} jobs in ${dataPath}`);
}

main().catch((error) => {
  console.error(`ERROR: ${error.message}`);
  process.exitCode = 1;
});
