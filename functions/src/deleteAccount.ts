import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import {callable} from './callable';
import {deletePrefix} from './spaces';
const BATCH_SIZE = 400;

function db(): admin.firestore.Firestore {
  return admin.firestore();
}

async function deleteQueryBatch(
  query: admin.firestore.Query,
): Promise<number> {
  const snap = await query.limit(BATCH_SIZE).get();
  if (snap.empty) return 0;

  const batch = db().batch();
  for (const doc of snap.docs) {
    batch.delete(doc.ref);
  }
  await batch.commit();
  return snap.size;
}

async function deleteAllMatching(
  query: admin.firestore.Query,
): Promise<void> {
  let deleted = BATCH_SIZE;
  while (deleted >= BATCH_SIZE) {
    deleted = await deleteQueryBatch(query);
  }
}

async function deleteUserSubcollection(
  userId: string,
  subcollection: string,
): Promise<void> {
  await deleteAllMatching(
    db().collection('users').doc(userId).collection(subcollection),
  );
}

async function deleteUserStorage(userId: string): Promise<void> {
  try {
    await deletePrefix(`users/${userId}/`);
  } catch (error) {
    functions.logger.warn('deleteAccount: storage cleanup failed', {
      userId,
      error,
    });
  }
}

async function purgeUserData(userId: string): Promise<void> {
  await Promise.all([
    deleteUserSubcollection(userId, 'saved_jobs'),
    deleteUserSubcollection(userId, 'saved_creators'),
    deleteUserSubcollection(userId, 'saved_talent'),
  ]);

  await Promise.all([
    deleteAllMatching(
      db().collection('notifications').where('userId', '==', userId),
    ),
    deleteAllMatching(
      db().collection('applications').where('user_id', '==', userId),
    ),
  ]);

  await Promise.all([
    db().collection('users').doc(userId).delete(),
    db().collection('profiles').doc(userId).delete(),
    db().collection('subscriptions').doc(userId).delete(),
  ]);

  await deleteUserStorage(userId);
}

/**
 * Permanently deletes the signed-in user's Firebase Auth account and app data.
 * Required for Google Play account-deletion policy compliance.
 */
export const deleteAccount = callable().https.onCall(async (_data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Sign in to delete your account.',
      );
    }

    const userId = context.auth.uid;
    const userDoc = await db().collection('users').doc(userId).get();
    const role = String(userDoc.data()?.role ?? '');

    if (role === 'admin') {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Admin accounts cannot be deleted from the app.',
      );
    }

    await purgeUserData(userId);

    try {
      await admin.auth().deleteUser(userId);
    } catch (error) {
      functions.logger.error('deleteAccount: auth delete failed', {
        userId,
        error,
      });
      throw new functions.https.HttpsError(
        'internal',
        'Could not delete account. Please try again.',
      );
    }

    functions.logger.info('deleteAccount: completed', {userId});
    return {deleted: true};
  });
