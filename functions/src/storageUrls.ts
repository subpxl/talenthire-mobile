import * as functions from 'firebase-functions/v1';
import {callable} from './callable';
import {
  assertStorageAccess,
  createPresignedUploadUrl,
  deleteObject,
  isSpacesConfigured,
  objectExistsOnSpaces,
  publicObjectUrl,
} from './spaces';

interface UploadUrlRequest {
  objectPath?: string;
  contentType?: string;
  contentLength?: number;
}

interface DeleteObjectRequest {
  objectPath?: string;
}

interface PublicUrlRequest {
  objectPath?: string;
}

export const getStorageUploadUrl = callable().https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Sign in to upload files.',
    );
  }

  const payload = (data ?? {}) as UploadUrlRequest;
  const objectPath = String(payload.objectPath ?? '').trim();
  const contentType = String(payload.contentType ?? 'image/jpeg').trim();
  const contentLength = Number(payload.contentLength ?? 0);

  if (!objectPath) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'objectPath is required.',
    );
  }
  if (!contentType) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'contentType is required.',
    );
  }

  await assertStorageAccess(context.auth.uid, objectPath, contentType, contentLength);

  if (!isSpacesConfigured()) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Photo storage is not configured on the server.',
    );
  }

  try {
    return await createPresignedUploadUrl({objectPath, contentType});
  } catch (error) {
    functions.logger.error('getStorageUploadUrl: Spaces presign failed', {
      objectPath,
      error,
    });
    throw new functions.https.HttpsError(
      'unavailable',
      'Could not prepare upload. Try again in a moment.',
    );
  }
});

/** Returns the public CDN URL after a client upload to Spaces. */
export const getStoragePublicUrl = callable().https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Sign in to resolve upload URLs.',
    );
  }

  const payload = (data ?? {}) as PublicUrlRequest;
  const objectPath = String(payload.objectPath ?? '').trim();
  if (!objectPath) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'objectPath is required.',
    );
  }

  await assertStorageAccess(context.auth.uid, objectPath);

  if (await objectExistsOnSpaces(objectPath)) {
    return {publicUrl: publicObjectUrl(objectPath), storage: 'spaces'};
  }

  throw new functions.https.HttpsError(
    'not-found',
    'Uploaded file was not found on storage. Try uploading again.',
  );
});

export const deleteStorageObject = callable().https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Sign in to delete files.',
    );
  }

  const payload = (data ?? {}) as DeleteObjectRequest;
  const objectPath = String(payload.objectPath ?? '').trim();
  if (!objectPath) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'objectPath is required.',
    );
  }

  await assertStorageAccess(context.auth.uid, objectPath);
  await deleteObject(objectPath);
  return {deleted: true, objectPath};
});

/** Converts a legacy Firebase Storage URL to the CDN URL when possible. */
export function firebaseUrlToCdnUrl(url: string): string | null {
  if (!url.includes('firebasestorage.googleapis.com')) return null;
  const marker = '/o/';
  const start = url.indexOf(marker);
  if (start === -1) return null;
  let encoded = url.substring(start + marker.length);
  const query = encoded.indexOf('?');
  if (query !== -1) encoded = encoded.substring(0, query);
  const objectPath = decodeURIComponent(encoded);
  if (!objectPath) return null;
  return publicObjectUrl(objectPath);
}
