const admin = require('firebase-admin');

// Initialize Firebase Admin SDK (uses default credentials)
admin.initializeApp({ projectId: 'talenthire-d86a1' });

const db = admin.firestore();
const auth = admin.auth();

// Provide the email you want to completely clean up
const EMAIL_TO_CLEAN = 'bcc.playreview@gmail.com'; 
// You can also change this to 'bccplayreview@gmail.com' if needed

async function main() {
  console.log(`Starting cleanup for: ${EMAIL_TO_CLEAN}`);
  let uid = null;

  // 1. Try to find the user in Firebase Auth
  try {
    const userRecord = await auth.getUserByEmail(EMAIL_TO_CLEAN);
    uid = userRecord.uid;
    console.log(`Found user in Auth. UID: ${uid}`);
    
    // Delete from Auth
    await auth.deleteUser(uid);
    console.log(`✅ Deleted user from Firebase Auth.`);
  } catch (error) {
    if (error.code === 'auth/user-not-found') {
      console.log(`User not found in Firebase Auth.`);
    } else {
      console.error(`Error fetching user from Auth:`, error);
    }
  }

  // If not found in Auth, try to find the UID from the users collection by email
  if (!uid) {
    console.log(`Searching Firestore 'users' collection for email...`);
    const usersSnapshot = await db.collection('users').where('email', '==', EMAIL_TO_CLEAN).get();
    if (!usersSnapshot.empty) {
      uid = usersSnapshot.docs[0].id;
      console.log(`Found user in Firestore 'users'. UID: ${uid}`);
    } else {
      console.log(`No user found in Firestore with email ${EMAIL_TO_CLEAN}.`);
      console.log(`Cleanup finished because UID could not be determined.`);
      process.exit(0);
    }
  }

  console.log(`\n--- Starting Firestore Cleanup for UID: ${uid} ---`);

  // 2. Delete Users Document & its Subcollections (e.g., saved_jobs)
  const userRef = db.collection('users').doc(uid);
  const savedJobsSnapshot = await userRef.collection('saved_jobs').get();
  if (!savedJobsSnapshot.empty) {
    const batch = db.batch();
    savedJobsSnapshot.forEach(doc => {
      batch.delete(doc.ref);
    });
    await batch.commit();
    console.log(`✅ Deleted ${savedJobsSnapshot.size} saved_jobs from users subcollection.`);
  }
  
  await userRef.delete();
  console.log(`✅ Deleted document from 'users' collection.`);

  // 3. Delete Profiles Document
  await db.collection('profiles').doc(uid).delete();
  console.log(`✅ Deleted document from 'profiles' collection.`);

  // 4. Delete Applications
  const appsSnapshot = await db.collection('applications').where('userId', '==', uid).get();
  if (!appsSnapshot.empty) {
    const batch = db.batch();
    appsSnapshot.forEach(doc => batch.delete(doc.ref));
    await batch.commit();
    console.log(`✅ Deleted ${appsSnapshot.size} documents from 'applications' collection.`);
  }

  // 5. Delete Transactions
  const txSnapshot = await db.collection('transactions').where('userId', '==', uid).get();
  if (!txSnapshot.empty) {
    const batch = db.batch();
    txSnapshot.forEach(doc => batch.delete(doc.ref));
    await batch.commit();
    console.log(`✅ Deleted ${txSnapshot.size} documents from 'transactions' collection.`);
  }

  // 6. Remove user from Conversations
  const convSnapshot = await db.collection('conversations').where('participants', 'array-contains', uid).get();
  if (!convSnapshot.empty) {
    const batch = db.batch();
    convSnapshot.forEach(doc => {
      const data = doc.data();
      const newParticipants = (data.participants || []).filter(p => p !== uid);
      // If no participants left, maybe delete the conversation, otherwise update
      if (newParticipants.length === 0) {
        batch.delete(doc.ref);
      } else {
        batch.update(doc.ref, { participants: newParticipants });
      }
    });
    await batch.commit();
    console.log(`✅ Updated/Deleted ${convSnapshot.size} documents in 'conversations' collection.`);
  }

  console.log(`\n🎉 Cleanup complete for ${EMAIL_TO_CLEAN} (UID: ${uid})!`);
  process.exit(0);
}

main().catch(error => {
  console.error("Cleanup script failed:", error);
  process.exit(1);
});
