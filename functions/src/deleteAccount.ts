import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import {callable} from './callable';

function db(): admin.firestore.Firestore {
  return admin.firestore();
}

/**
 * Soft-deletes the signed-in user (tag only). Same idea as deactivate:
 * data and Auth stay; client logs out. Login clears the tag.
 */
export const deleteAccount = callable().https.onCall(async (_data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Sign in to delete your account.',
    );
  }

  const userId = context.auth.uid;
  const userRef = db().collection('users').doc(userId);
  const userDoc = await userRef.get();
  const role = String(userDoc.data()?.role ?? '');

  if (role === 'admin') {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Admin accounts cannot be deleted from the app.',
    );
  }

  if (!userDoc.exists) {
    throw new functions.https.HttpsError('not-found', 'User record not found.');
  }

  const now = new Date().toISOString();
  await userRef.update({
    account_deleted_at: now,
    updated_at: now,
  });

  functions.logger.info('deleteAccount: soft-deleted', {userId});
  return {deleted: true, soft: true};
});
