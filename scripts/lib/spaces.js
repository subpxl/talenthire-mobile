import { readFileSync, existsSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  S3Client,
  PutObjectCommand,
  ListObjectsV2Command,
  DeleteObjectsCommand,
  PutBucketCorsCommand,
  HeadBucketCommand,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

const here = dirname(fileURLToPath(import.meta.url));

function loadLocalEnv() {
  const envPath = resolve(here, '..', 'local', 'spaces.env');
  if (!existsSync(envPath)) return;
  for (const line of readFileSync(envPath, 'utf8').split('\n')) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const eq = trimmed.indexOf('=');
    if (eq === -1) continue;
    const key = trimmed.slice(0, eq).trim();
    const value = trimmed.slice(eq + 1).trim();
    if (!process.env[key]) process.env[key] = value;
  }
}

loadLocalEnv();

export const SPACES_BUCKET = process.env.DO_SPACES_BUCKET || 'talenthire-media';
export const SPACES_REGION = process.env.DO_SPACES_REGION || 'sgp1';
export const SPACES_ENDPOINT = process.env.DO_SPACES_ENDPOINT
  || `https://${SPACES_REGION}.digitaloceanspaces.com`;
export const SPACES_CDN_BASE = process.env.DO_SPACES_CDN_BASE
  || `https://${SPACES_BUCKET}.${SPACES_REGION}.cdn.digitaloceanspaces.com`;

export function spacesConfig() {
  const accessKeyId = process.env.DO_SPACES_KEY || '';
  const secretAccessKey = process.env.DO_SPACES_SECRET || '';
  if (!accessKeyId || !secretAccessKey) {
    throw new Error(
      'Set DO_SPACES_KEY and DO_SPACES_SECRET in scripts/local/spaces.env or the environment',
    );
  }
  return { accessKeyId, secretAccessKey, bucket: SPACES_BUCKET, region: SPACES_REGION };
}

export function createSpacesClient() {
  const { accessKeyId, secretAccessKey, region } = spacesConfig();
  return new S3Client({
    region,
    endpoint: SPACES_ENDPOINT,
    forcePathStyle: false,
    credentials: { accessKeyId, secretAccessKey },
  });
}

export function publicObjectUrl(objectPath) {
  const normalized = objectPath.replace(/^\/+/, '');
  return `${SPACES_CDN_BASE}/${normalized.split('/').map(encodeURIComponent).join('/')}`;
}

export function firebaseObjectPathFromUrl(url) {
  if (!url || typeof url !== 'string') return null;
  if (url.startsWith(SPACES_CDN_BASE) || url.startsWith(`https://${SPACES_BUCKET}.`)) {
    try {
      const parsed = new URL(url);
      return decodeURIComponent(parsed.pathname.replace(/^\/+/, ''));
    } catch {
      return null;
    }
  }
  if (!url.includes('firebasestorage.googleapis.com')) return null;
  const marker = '/o/';
  const start = url.indexOf(marker);
  if (start === -1) return null;
  let encoded = url.substring(start + marker.length);
  const query = encoded.indexOf('?');
  if (query !== -1) encoded = encoded.substring(0, query);
  const decoded = decodeURIComponent(encoded);
  return decoded || null;
}

export async function verifyBucket(client = createSpacesClient()) {
  await client.send(new HeadBucketCommand({ Bucket: SPACES_BUCKET }));
}

export async function applyBucketCors(client = createSpacesClient()) {
  await client.send(new PutBucketCorsCommand({
    Bucket: SPACES_BUCKET,
    CORSConfiguration: {
      CORSRules: [{
        AllowedOrigins: ['*'],
        AllowedMethods: ['GET', 'PUT', 'HEAD', 'DELETE'],
        AllowedHeaders: ['*'],
        MaxAgeSeconds: 3000,
      }],
    },
  }));
}

export async function uploadFile(client, localPath, objectPath, contentType = 'image/jpeg') {
  const { readFile } = await import('node:fs/promises');
  const body = await readFile(localPath);
  await client.send(new PutObjectCommand({
    Bucket: SPACES_BUCKET,
    Key: objectPath,
    Body: body,
    ContentType: contentType,
    ACL: 'public-read',
    CacheControl: 'public,max-age=31536000,immutable',
  }));
  return publicObjectUrl(objectPath);
}

export async function uploadBuffer(client, buffer, objectPath, contentType = 'image/jpeg') {
  await client.send(new PutObjectCommand({
    Bucket: SPACES_BUCKET,
    Key: objectPath,
    Body: buffer,
    ContentType: contentType,
    ACL: 'public-read',
    CacheControl: 'public,max-age=31536000,immutable',
  }));
  return publicObjectUrl(objectPath);
}

export async function listAllObjects(client, prefix = '') {
  const keys = [];
  let token;
  do {
    const page = await client.send(new ListObjectsV2Command({
      Bucket: SPACES_BUCKET,
      Prefix: prefix,
      ContinuationToken: token,
    }));
    for (const item of page.Contents ?? []) {
      if (item.Key) keys.push(item.Key);
    }
    token = page.IsTruncated ? page.NextContinuationToken : undefined;
  } while (token);
  return keys;
}

export async function createPresignedUploadUrl(objectPath, contentType = 'image/jpeg') {
  const client = createSpacesClient();
  const normalized = objectPath.replace(/^\/+/, '');
  const command = new PutObjectCommand({
    Bucket: SPACES_BUCKET,
    Key: normalized,
    ContentType: contentType,
    ACL: 'public-read',
    CacheControl: 'public,max-age=31536000,immutable',
  });
  const uploadUrl = await getSignedUrl(client, command, { expiresIn: 900 });
  return {
    uploadUrl,
    publicUrl: publicObjectUrl(normalized),
    objectPath: normalized,
  };
}

export async function deletePrefix(client, prefix) {
  const keys = await listAllObjects(client, prefix);
  if (keys.length === 0) return 0;
  let deleted = 0;
  for (let i = 0; i < keys.length; i += 1000) {
    const chunk = keys.slice(i, i + 1000);
    await client.send(new DeleteObjectsCommand({
      Bucket: SPACES_BUCKET,
      Delete: { Objects: chunk.map((Key) => ({ Key })), Quiet: true },
    }));
    deleted += chunk.length;
  }
  return deleted;
}
