// Delete old auth user and recreate with correct password
const admin = require('firebase-admin');

admin.initializeApp({ projectId: 'talenthire-d86a1' });

const EMAIL = 'bcc.playreview@gmail.com';
const PASSWORD = 'BccReview@2026';

async function main() {
  const auth = admin.auth();
  const db = admin.firestore();

  try {
    const existing = await auth.getUserByEmail(EMAIL);
    console.log(`Found existing user: ${existing.uid} — deleting...`);
    await auth.deleteUser(existing.uid);
    console.log('Old auth user deleted');
  } catch (e) {
    if (e.code === 'auth/user-not-found') {
      console.log('No existing user, creating fresh...');
    } else {
      console.error('Lookup error:', e.message);
    }
  }

  const newUser = await auth.createUser({
    email: EMAIL,
    password: PASSWORD,
    displayName: 'BCC Reviewer',
    emailVerified: true,
  });
  const uid = newUser.uid;
  console.log(`New user created — UID: ${uid}`);

  const now = new Date().toISOString();
  await db.collection('users').doc(uid).set({
    id: uid, name: 'BCC Reviewer', email: EMAIL, mobile: '',
    role: 'influencer', is_active: true,
    birth_day: 1, birth_month: 1, birth_year: 1990,
    created_at: now, updated_at: now,
  });
  console.log('User doc created');

  await db.collection('profiles').doc(uid).set({
    user_id: uid, profile_image: '', photos: [],
    is_verified: false, talent: 'actor',
    bio: 'Demo reviewer account for Play Store testing.',
    social_links: [], contact: '', address: '',
    city: 'Mumbai', state: 'Maharashtra', pincode: '',
    video_interview_link: '', achievements_video_link: '',
    short_intro_video_link: '', previous_works_video_link: '',
    account_status: 'active', subscription_status: 'free',
    gender: 'male', experience_level: 'fresher',
    languages: ['English', 'Hindi'],
    profile_completed: false, free_job_applications_used: 0,
  });
  console.log('Profile doc created');

  console.log(`\nDone! Email: ${EMAIL} | Password: ${PASSWORD} | UID: ${uid}`);
  process.exit(0);
}

main().catch(e => { console.error(e); process.exit(1); });
