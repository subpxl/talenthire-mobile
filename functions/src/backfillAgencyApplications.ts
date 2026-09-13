import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import {callable} from './callable';

function db(): admin.firestore.Firestore {
  return admin.firestore();
}

/**
 * Ensures every application for this agency's jobs has `agency_id` set so
 * the webapp can query applications with security-rule-friendly filters.
 */
export const backfillAgencyApplications = callable().https.onCall(
  async (_data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Sign in to continue.',
      );
    }

    const agencyId = context.auth.uid;
    const userDoc = await db().collection('users').doc(agencyId).get();
    if (!userDoc.exists || userDoc.data()?.role !== 'agency') {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Agency account required.',
      );
    }

    const [byAgencyId, byCreatedBy] = await Promise.all([
      db().collection('jobs').where('agencyId', '==', agencyId).get(),
      db().collection('jobs').where('created_by', '==', agencyId).get(),
    ]);

    const jobIds = new Set<string>();
    for (const doc of [...byAgencyId.docs, ...byCreatedBy.docs]) {
      jobIds.add(doc.id);
    }

    let updated = 0;

    for (const jobId of jobIds) {
      const [bySnake, byCamel] = await Promise.all([
        db().collection('applications').where('job_id', '==', jobId).get(),
        db().collection('applications').where('jobId', '==', jobId).get(),
      ]);

      const seen = new Set<string>();
      for (const appDoc of [...bySnake.docs, ...byCamel.docs]) {
        if (seen.has(appDoc.id)) continue;
        seen.add(appDoc.id);
        const current = String(appDoc.data().agency_id ?? '');
        if (current === agencyId) continue;
        await appDoc.ref.update({agency_id: agencyId});
        updated += 1;
      }
    }

    return {updated, jobs: jobIds.size};
  },
);
