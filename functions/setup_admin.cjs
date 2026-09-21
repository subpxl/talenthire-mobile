// Reset or create the TalentHire admin account.
const admin = require('firebase-admin');
const { resolve } = require('path');

const serviceAccountPath = resolve(__dirname, '../scripts/serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(require(serviceAccountPath)),
  projectId: 'talenthire-d86a1',
});

const EMAIL = process.env.ADMIN_EMAIL || 'admin@talenthire.com';
const PASSWORD = process.env.ADMIN_PASSWORD;
const NAME = process.env.ADMIN_NAME || 'TalentHire Admin';

async function main() {
  if (!PASSWORD || PASSWORD.length < 8) {
    console.error(
      'Set ADMIN_PASSWORD (min 8 characters), e.g. PowerShell:\n' +
        '  $env:ADMIN_PASSWORD="YourNewSecurePassword"; node create_admin.cjs',
    );
    process.exit(1);
  }

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
  console.log(`  Password: (value from ADMIN_PASSWORD)`);
  console.log(`  UID:      ${uid}`);
  console.log(`  Firestore users/${uid} role=admin`);
  process.exit(0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
