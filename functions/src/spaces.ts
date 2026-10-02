import {
  DeleteObjectsCommand,
  HeadObjectCommand,
  ListObjectsV2Command,
  PutObjectCommand,
  S3Client,
} from '@aws-sdk/client-s3';
import {randomUUID} from 'crypto';
import {getSignedUrl} from '@aws-sdk/s3-request-presigner';
import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions/v1';

export interface SpacesConfig {
  accessKeyId: string;
  secretAccessKey: string;
  bucket: string;
  region: string;
  endpoint: string;
  cdnBase: string;
}

const MAX_USER_IMAGE_BYTES = 10 * 1024 * 1024;
const MAX_ATTACHMENT_BYTES = 5 * 1024 * 1024;

export function isSpacesConfigured(): boolean {
  return Boolean(process.env.DO_SPACES_KEY && process.env.DO_SPACES_SECRET);
}

export function getSpacesConfig(): SpacesConfig {
  const accessKeyId = process.env.DO_SPACES_KEY ?? '';
  const secretAccessKey = process.env.DO_SPACES_SECRET ?? '';
  const bucket = process.env.DO_SPACES_BUCKET ?? 'talenthire-media';
  const region = process.env.DO_SPACES_REGION ?? 'sgp1';
  const endpoint =
    process.env.DO_SPACES_ENDPOINT ?? `https://${region}.digitaloceanspaces.com`;
  const cdnBase =
    process.env.DO_SPACES_CDN_BASE ??
    `https://${bucket}.${region}.cdn.digitaloceanspaces.com`;

  if (!accessKeyId || !secretAccessKey) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'DigitalOcean Spaces is not configured on the server.',
    );
  }

  return {accessKeyId, secretAccessKey, bucket, region, endpoint, cdnBase};
}

export function createSpacesClient(config: SpacesConfig = getSpacesConfig()): S3Client {
  return new S3Client({
    region: config.region,
    endpoint: config.endpoint,
    forcePathStyle: false,
    credentials: {
      accessKeyId: config.accessKeyId,
      secretAccessKey: config.secretAccessKey,
    },
  });
}

export function publicObjectUrl(objectPath: string, config: SpacesConfig = getSpacesConfig()): string {
  const normalized = objectPath.replace(/^\/+/, '');
  return `${config.cdnBase}/${normalized.split('/').map(encodeURIComponent).join('/')}`;
}

function normalizeObjectPath(raw: string): string {
  const trimmed = raw.trim().replace(/^\/+/, '');
  if (!trimmed || trimmed.includes('..')) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid object path.');
  }
  return trimmed;
}

async function userIsAdmin(uid: string): Promise<boolean> {
  const doc = await admin.firestore().collection('users').doc(uid).get();
  return doc.data()?.role === 'admin';
}

export async function assertStorageAccess(
  uid: string,
  objectPath: string,
  contentType?: string,
  contentLength?: number,
): Promise<void> {
  const path = normalizeObjectPath(objectPath);

  if (path.startsWith('banners/')) {
    if (!(await userIsAdmin(uid))) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only admins can manage banners.',
      );
    }
    if (contentType && !contentType.startsWith('image/')) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Only image uploads are allowed.',
      );
    }
    if (contentLength != null && contentLength > MAX_USER_IMAGE_BYTES) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Image exceeds the 10 MB limit.',
      );
    }
    return;
  }

  if (path.startsWith('users/')) {
    const parts = path.split('/');
    const ownerId = parts[1] ?? '';
    if (ownerId !== uid) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'You can only access your own files.',
      );
    }
    if (contentType && !contentType.startsWith('image/')) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Only image uploads are allowed.',
      );
    }
    if (contentLength != null && contentLength > MAX_USER_IMAGE_BYTES) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Image exceeds the 10 MB limit.',
      );
    }
    return;
  }

  if (path.startsWith('agencies/')) {
    const parts = path.split('/');
    const agencyId = parts[1] ?? '';
    if (agencyId !== uid) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'You can only access your agency files.',
      );
    }
    if (contentLength != null && contentLength > MAX_USER_IMAGE_BYTES) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'File exceeds the 10 MB limit.',
      );
    }
    return;
  }

  if (path.startsWith('attachments/')) {
    if (contentLength != null && contentLength > MAX_ATTACHMENT_BYTES) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Attachment exceeds the 5 MB limit.',
      );
    }
    return;
  }

  throw new functions.https.HttpsError(
    'permission-denied',
    'Upload path is not allowed.',
  );
}

export async function createPresignedUploadUrl(opts: {
  objectPath: string;
  contentType: string;
  expiresIn?: number;
}): Promise<{uploadUrl: string; publicUrl: string; objectPath: string}> {
  const config = getSpacesConfig();
  const client = createSpacesClient(config);
  const objectPath = normalizeObjectPath(opts.objectPath);
  const command = new PutObjectCommand({
    Bucket: config.bucket,
    Key: objectPath,
    ContentType: opts.contentType,
    ACL: 'public-read',
    CacheControl: 'public,max-age=31536000,immutable',
  });
  const uploadUrl = await getSignedUrl(client, command, {
    expiresIn: opts.expiresIn ?? 900,
  });
  return {
    uploadUrl,
    publicUrl: publicObjectUrl(objectPath, config),
    objectPath,
  };
}

export async function objectExistsOnSpaces(objectPath: string): Promise<boolean> {
  if (!isSpacesConfigured()) return false;
  const config = getSpacesConfig();
  const client = createSpacesClient(config);
  const path = normalizeObjectPath(objectPath);
  try {
    await client.send(new HeadObjectCommand({
      Bucket: config.bucket,
      Key: path,
    }));
    return true;
  } catch {
    return false;
  }
}

/** Public Firebase download URL with a long-lived token (for legacy uploads). */
export async function firebaseDownloadUrl(objectPath: string): Promise<string | null> {
  const path = normalizeObjectPath(objectPath);
  const bucket = admin.storage().bucket();
  const file = bucket.file(path);
  const [exists] = await file.exists();
  if (!exists) return null;

  const [metadata] = await file.getMetadata();
  const rawToken = metadata.metadata?.firebaseStorageDownloadTokens;
  let token = typeof rawToken === 'string' ? rawToken.split(',')[0]?.trim() : '';
  if (!token) {
    token = randomUUID();
    await file.setMetadata({
      metadata: {firebaseStorageDownloadTokens: token},
    });
  }

  return `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(path)}?alt=media&token=${token}`;
}

export async function deleteObject(objectPath: string): Promise<void> {
  const config = getSpacesConfig();
  const client = createSpacesClient(config);
  const path = normalizeObjectPath(objectPath);
  await client.send(new DeleteObjectsCommand({
    Bucket: config.bucket,
    Delete: {Objects: [{Key: path}], Quiet: true},
  }));
}

export async function deletePrefix(prefix: string): Promise<number> {
  const config = getSpacesConfig();
  const client = createSpacesClient(config);
  const normalized = prefix.replace(/^\/+/, '');
  const keys: string[] = [];
  let token: string | undefined;

  do {
    const page = await client.send(new ListObjectsV2Command({
      Bucket: config.bucket,
      Prefix: normalized,
      ContinuationToken: token,
    }));
    for (const item of page.Contents ?? []) {
      if (item.Key) keys.push(item.Key);
    }
    token = page.IsTruncated ? page.NextContinuationToken : undefined;
  } while (token);

  if (keys.length === 0) return 0;

  for (let i = 0; i < keys.length; i += 1000) {
    const chunk = keys.slice(i, i + 1000);
    await client.send(new DeleteObjectsCommand({
      Bucket: config.bucket,
      Delete: {Objects: chunk.map((Key) => ({Key})), Quiet: true},
    }));
  }
  return keys.length;
}
