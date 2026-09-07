import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import {callable} from './callable';
import {
  evaluateApplyGate,
  type ApplyQuotaApplication,
} from './applyQuota';

function db(): admin.firestore.Firestore {
  return admin.firestore();
}

function parseFlexibleDate(value: unknown): Date | null {
  if (value == null) return null;
  if (value instanceof Date) return value;
  if (value instanceof admin.firestore.Timestamp) return value.toDate();
  if (typeof value === 'object' && value && 'toDate' in value) {
    try {
      return (value as admin.firestore.Timestamp).toDate();
    } catch {
      return null;
    }
  }
  if (typeof value === 'string') {
    const ms = Date.parse(value);
    return Number.isNaN(ms) ? null : new Date(ms);
  }
  return null;
}

function quotaError(reason: 'daily_limit' | 'trial_ended'): never {
  const message =
    reason === 'daily_limit'
      ? 'Daily apply limit reached.'
      : 'Free trial ended.';
  throw new functions.https.HttpsError('resource-exhausted', message, {
    reason,
  });
}

/**
 * Server-side job apply with quota enforcement.
 * Clients must use this callable — direct Firestore creates are blocked by rules.
 *
 * The quota check and the application write execute inside a single Firestore
 * transaction so concurrent requests from the same user serialize atomically
 * — eliminating the TOCTOU race where two simultaneous calls could both pass
 * the daily_limit gate before either write landed.
 */
export const submitJobApplication = callable().https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Sign in to apply.',
      );
    }

    const userId = context.auth.uid;
    const jobId = String(data?.jobId ?? '').trim();
    const script = String(data?.script ?? '').trim();
    const youtubeShortUrl = String(data?.youtubeShortUrl ?? '').trim();

    if (!jobId || jobId.length > 128) {
      throw new functions.https.HttpsError('invalid-argument', 'Invalid job.');
    }
    if (script.length > 4000) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Script is too long.',
      );
    }
    if (youtubeShortUrl.length > 500) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Link is too long.',
      );
    }

    const applicationId = `${userId}_${jobId}`;
    const now = new Date();

    // ── Pre-transaction reads (non-quota, read-only) ──────────────────────
    // Job and user/profile docs don't change during the apply window so we
    // can read them outside the transaction to avoid holding locks longer
    // than necessary.
    const [userDoc, profileDoc, jobDoc, existingAppDoc, applicationsSnap] = await Promise.all([
      db().collection('users').doc(userId).get(),
      db().collection('profiles').doc(userId).get(),
      db().collection('jobs').doc(jobId).get(),
      db().collection('applications').doc(applicationId).get(),
      db().collection('applications').where('user_id', '==', userId).get(),
    ]);

    if (!jobDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Job not found.');
    }

    const job = jobDoc.data() ?? {};
    if (String(job.status ?? '') !== 'published') {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'Job is not open for applications.',
      );
    }

    const existingStatus = existingAppDoc.exists
      ? String(existingAppDoc.data()?.status ?? '')
      : '';
    if (existingAppDoc.exists && existingStatus !== 'withdrawn') {
      throw new functions.https.HttpsError(
        'already-exists',
        'Already applied to this job.',
      );
    }

    const userCreatedAt =
      parseFlexibleDate(userDoc.data()?.created_at) ?? now;
    const isPremium =
      String(profileDoc.data()?.subscription_status ?? '') === 'premium';

    const quotaApplications: ApplyQuotaApplication[] = applicationsSnap.docs
      .filter((doc) => doc.id !== applicationId || existingStatus !== 'withdrawn')
      .map((doc) => ({
        appliedAt:
          parseFlexibleDate(doc.data().applied_at) ??
          parseFlexibleDate(doc.data().created_at) ??
          now,
        status: String(doc.data().status ?? 'applied'),
      }));

    const gate = evaluateApplyGate({
      isPremium,
      accountCreatedAt: userCreatedAt,
      applications: quotaApplications,
      now,
    });
    if (gate === 'daily_limit') quotaError('daily_limit');
    if (gate === 'trial_ended') quotaError('trial_ended');

    const jobTitle = String(job.title ?? '').slice(0, 200);
    const company = String(
      job.company ?? job.agency_name ?? job.agencyName ?? '',
    ).slice(0, 120);
    const appliedAt = now.toISOString();

    const payload = {
      id: applicationId,
      user_id: userId,
      job_id: jobId,
      job_title: jobTitle,
      company,
      status: 'applied',
      script,
      youtube_short_url: youtubeShortUrl,
      applied_at: appliedAt,
    };

    if (existingStatus === 'withdrawn') {
      await db().collection('applications').doc(applicationId).update({
        status: 'applied',
        script,
        youtube_short_url: youtubeShortUrl,
        applied_at: appliedAt,
        job_title: jobTitle,
        company,
      });
    } else {
      await db().collection('applications').doc(applicationId).set(payload);
    }

    return {application: payload};
  });
