// Reset or create the TalentHire admin account.
const admin = require('firebase-admin');
const { resolve } = require('path');

const serviceAccountPath = resolve(__dirname, '../scripts/serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(require(serviceAccountPath)),
  projectId: 'talenthire-d86a1',
});

const EMAIL = 'admin@talenthire.com';
const PASSWORD = 'Admin@123456';
const NAME = 'TalentHire Admin';

async function main() {
  const auth = admin.auth();
  const db = admin.firestore();

  let uid;
  try {
    const existing = await auth.getUserByEmail(EMAIL);
    uid = existing.uid;
    console.log(`Found admin auth user: ${uid} — resetting password...`);
    await auth.updateUser(uid, {
      password: PASSWORD,
      displayName: NAME,
      emailVerified: true,
      disabled: false,
    });
  } catch (e) {
    if (e.code === 'auth/user-not-found') {
      console.log('No admin user found — creating...');
      const created = await auth.createUser({
        email: EMAIL,
        password: PASSWORD,
        displayName: NAME,
        emailVerified: true,
      });
      uid = created.uid;
    } else {
      throw e;
    }
  }

  const now = new Date().toISOString();
  await db.collection('users').doc(uid).set(
    {
      id: uid,
      name: NAME,
      email: EMAIL,
      role: 'admin',
      isActive: true,
      updated_at: now,
      created_at: now,
    },
    { merge: true },
  );

  console.log('\nAdmin ready:');
  console.log(`  Email:    ${EMAIL}`);
  console.log(`  Password: ${PASSWORD}`);
  console.log(`  UID:      ${uid}`);
  console.log(`  Firestore users/${uid} role=admin`);
  process.exit(0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
