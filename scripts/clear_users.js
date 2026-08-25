import admin from 'firebase-admin';
import { readFileSync } from 'fs';

// IMPORTANT: Initialize with your Service Account Key
// Download it from Firebase Console -> Project Settings -> Service Accounts -> "Generate new private key"
// Place the downloaded JSON file in the same directory and update the path below:
const serviceAccount = JSON.parse(
  readFileSync(new URL('./serviceAccountKey.json', import.meta.url))
);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

async function clearAllUsers() {
  console.log('Fetching users to delete...');
  let nextPageToken;
  let totalDeleted = 0;

  do {
    // Fetch users in batches of 1000
    const listUsersResult = await admin.auth().listUsers(1000, nextPageToken);
    const uids = listUsersResult.users.map((userRecord) => userRecord.uid);

    if (uids.length > 0) {
      // Delete the batch of users
      const deleteResult = await admin.auth().deleteUsers(uids);
      totalDeleted += deleteResult.successCount;
      console.log(`Deleted ${deleteResult.successCount} users in this batch.`);
      
      if (deleteResult.failureCount > 0) {
        console.error(`Failed to delete ${deleteResult.failureCount} users.`);
        deleteResult.errors.forEach(err => console.error(err.error.toJSON()));
      }
    }

    nextPageToken = listUsersResult.pageToken;
  } while (nextPageToken);

  console.log(`Finished clearing users. Total deleted: ${totalDeleted}`);
}

clearAllUsers();
