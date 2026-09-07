import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';

const db = admin.firestore();

type JsonMap = Record<string, unknown>;

function formSection(profile: JsonMap, section: string): JsonMap {
  const formData = profile.form_data;
  if (!formData || typeof formData !== 'object') return {};
  const sectionData = (formData as JsonMap)[section];
  if (!sectionData || typeof sectionData !== 'object') return {};
  return sectionData as JsonMap;
}

function filled(value: unknown): string {
  const text = String(value ?? '').trim();
  if (!text || text === '-') return '';
  return text;
}

function stringList(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value
    .map((item) => String(item ?? '').trim())
    .filter((item) => item.length > 0);
}

function listFromSections(profile: JsonMap, key: string): string[] {
  const creator = stringList(formSection(profile, 'creator')[key]);
  if (creator.length > 0) return creator;
  return stringList(formSection(profile, 'content')[key]);
}

/** Denormalized creator card fields stored on users/{uid}.feed_card */
export function buildCreatorFeedCard(profile: JsonMap): JsonMap {
  const personal = formSection(profile, 'personal');
  const work = formSection(profile, 'work');
  const videos = formSection(profile, 'videos');

  const gender = filled(profile.gender) || filled(personal.gender);
  const age =
    typeof profile.age === 'number'
      ? profile.age
      : Number.parseInt(String(personal.age ?? ''), 10) || null;

  return {
    city: filled(profile.city),
    state: filled(profile.state),
    profile_image: filled(profile.profile_image),
    photos: stringList(profile.photos),
    photo_thumbs: stringList(profile.photo_thumbs),
    talent: filled(profile.talent) || 'influencer',
    bio: filled(profile.bio) || filled(personal.about),
    gender,
    age: age && age > 0 ? age : null,
    languages:
      stringList(profile.languages).length > 0
        ? stringList(profile.languages)
        : stringList(personal.language ?? personal.languages),
    niches:
      stringList(profile.niches).length > 0
        ? stringList(profile.niches)
        : stringList(formSection(profile, 'content').niches),
    role: filled(work.role),
    looking_for: filled(personal.looking_for),
    collab_types: listFromSections(profile, 'collab_types'),
    content_types: listFromSections(profile, 'content_types'),
    is_verified: profile.is_verified === true,
    subscription_status: filled(profile.subscription_status) || 'free',
    platform_metrics: Array.isArray(profile.platform_metrics)
      ? profile.platform_metrics
      : [],
    video_links: [
      videos.introduction_link,
      videos.previous_experience,
      videos.other_video_link,
    ]
      .map((value) => filled(value))
      .filter((value) => value.length > 0),
    updated_at: new Date().toISOString(),
  };
}

/**
 * Keeps users/{uid}.feed_card in sync whenever profiles/{uid} changes so the
 * creator feed can skip the extra profiles collection query.
 */
export const syncCreatorFeedCard = functions
  .region('asia-south1')
  .firestore.document('profiles/{userId}')
  .onWrite(async (change, context) => {
    const userId = String(context.params.userId || '');
    if (!userId) return null;

    const userRef = db.collection('users').doc(userId);

    if (!change.after.exists) {
      await userRef.set(
        {
          feed_card: admin.firestore.FieldValue.delete(),
          feed_card_updated_at: admin.firestore.FieldValue.delete(),
        },
        {merge: true},
      );
      return null;
    }

    const profile = change.after.data() as JsonMap;
    const feedCard = buildCreatorFeedCard(profile);
    await userRef.set(
      {
        feed_card: feedCard,
        feed_card_updated_at: admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: true},
    );
    return null;
  });
