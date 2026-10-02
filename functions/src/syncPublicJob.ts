import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions/v1';

function str(value: unknown, fallback = ''): string {
  if (value == null) return fallback;
  return String(value).trim();
}

function citySlugFromLocation(location: string): string {
  const first = location.split(',')[0]?.trim() || location.trim() || 'india';
  return first
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '') || 'india';
}

function payLabel(raw: FirebaseFirestore.DocumentData): string {
  const min = Number(raw.pay_min ?? raw.payMin ?? 0) || 0;
  const max = Number(raw.pay_max ?? raw.payMax ?? 0) || 0;
  if (min > 0 && max > 0 && max >= min) return `₹${min.toLocaleString('en-IN')}–₹${max.toLocaleString('en-IN')}`;
  if (min > 0) return `From ₹${min.toLocaleString('en-IN')}`;
  if (max > 0) return `Up to ₹${max.toLocaleString('en-IN')}`;
  const comp = str(raw.compensation ?? raw.salary);
  if (comp) return comp;
  return 'Undisclosed';
}

function ageLabel(raw: FirebaseFirestore.DocumentData): string {
  const age = str(raw.age);
  if (age) return age;
  const min = raw.age_min ?? raw.ageMin;
  const max = raw.age_max ?? raw.ageMax;
  const ageMin = min != null && min !== '' ? Number(min) : null;
  const ageMax = max != null && max !== '' ? Number(max) : null;
  if (ageMin != null && ageMax != null) return `${ageMin}–${ageMax}`;
  if (ageMin != null) return `${ageMin}+`;
  if (ageMax != null) return `Up to ${ageMax}`;
  return '';
}

function publicWebEnabled(raw: FirebaseFirestore.DocumentData): boolean {
  return raw.public_on_web === true || raw.publicOnWeb === true;
}

function buildPublicJobDoc(
  jobId: string,
  raw: FirebaseFirestore.DocumentData,
): Record<string, unknown> {
  const title = str(raw.title, 'Casting call');
  const description = str(raw.description).slice(0, 8000);
  const location = str(raw.location, 'Remote');
  const postedAt = str(raw.posted_at ?? raw.postedAt, new Date().toISOString());
  const gender = str(raw.gender ?? raw.gender_required ?? raw.genderRequired);

  return {
    jobId,
    title,
    summary: str(raw.summary, description.slice(0, 160)),
    description,
    location,
    citySlug: citySlugFromLocation(location),
    locationType: str(raw.location_type ?? raw.locationType, 'remote'),
    artistType: str(raw.artist_type ?? raw.artistType ?? raw.category),
    company: str(raw.company),
    compensation: str(raw.compensation),
    payLabel: payLabel(raw),
    ageLabel: ageLabel(raw),
    gender,
    applicationDeadline: str(raw.application_deadline ?? raw.applicationDeadline) || null,
    postedAt,
    bannerUrl: str(raw.banner_url ?? raw.bannerUrl ?? raw.image_url) || null,
    deepLinkPath: `/j/${jobId}`,
    publicPath: `/casting-calls/${jobId}/`,
    listingStatus: 'open',
    closedAt: null,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}

/**
 * Mirrors opted-in published jobs to `public_jobs/{jobId}` for anonymous web reads.
 * Does not touch private `jobs` documents or agency fields.
 */
export function registerSyncPublicJob(
  db: FirebaseFirestore.Firestore,
  region: string,
) {
  return functions.region(region).firestore.document('jobs/{jobId}').onWrite(async (change) => {
    const jobId = change.after.exists ? change.after.id : change.before.id;
    const publicRef = db.collection('public_jobs').doc(jobId);

    if (!change.after.exists) {
      await publicRef.delete().catch(() => undefined);
      return null;
    }

    const after = change.after.data();
    if (!after) return null;

    const published = str(after.status) === 'published';
    const showOnWeb = publicWebEnabled(after);

    if (!showOnWeb) {
      await publicRef.delete().catch(() => undefined);
      return null;
    }

    if (!published) {
      const existing = await publicRef.get();
      if (!existing.exists) {
        return null;
      }
      await publicRef.set(
        {
          ...buildPublicJobDoc(jobId, after),
          listingStatus: 'closed',
          closedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        {merge: false},
      );
      functions.logger.info(`syncPublicJob: closed public_jobs/${jobId}`);
      return null;
    }

    await publicRef.set(buildPublicJobDoc(jobId, after), {merge: false});
    functions.logger.info(`syncPublicJob: updated public_jobs/${jobId}`);
    return null;
  });
}
