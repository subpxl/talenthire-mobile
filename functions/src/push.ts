import * as admin from 'firebase-admin';

export async function sendPushToUser(opts: {
  userId: string;
  title: string;
  body: string;
  data: Record<string, string>;
  channelId: 'messages' | 'alerts';
}): Promise<void> {
  const db = admin.firestore();
  const userDoc = await db.collection('users').doc(opts.userId).get();
  const fcmTokens: string[] = userDoc.data()?.fcm_tokens || [];
  if (fcmTokens.length === 0) return;

  await Promise.all(
    fcmTokens.map(async (token) => {
      try {
        await admin.messaging().send({
          token,
          notification: {title: opts.title, body: opts.body},
          data: opts.data,
          android: {
            priority: 'high',
            notification: {channelId: opts.channelId},
          },
          apns: {
            payload: {
              aps: {sound: 'default'},
            },
          },
        });
      } catch (error: unknown) {
        const code =
          (error as {code?: string; errorInfo?: {code?: string}})?.code ||
          (error as {errorInfo?: {code?: string}})?.errorInfo?.code;
        if (
          code === 'messaging/invalid-registration-token' ||
          code === 'messaging/registration-token-not-registered'
        ) {
          await db.collection('users').doc(opts.userId).update({
            fcm_tokens: admin.firestore.FieldValue.arrayRemove(token),
          });
        }
        console.error(`Failed to send push to ${opts.userId}:`, error);
      }
    }),
  );
}
