import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();
const db = admin.firestore();
const RTDB_INSTANCE = 'talenthire-d86a1-default-rtdb';

/**
 * Sends a push notification to the recipient when a chat message is created.
 * Payments are intentionally not implemented in this release.
 */
export const onNewMessage = functions
  .database.instance(RTDB_INSTANCE)
  .ref('/messages/{conversationId}/{messageId}')
  .onCreate(async (snapshot, context) => {
    const message = snapshot.val();
    if (!message) return null;

    const {conversationId} = context.params;
    const senderId: string = message.sender_id;
    const text: string = message.text || 'New message';
    if (!senderId) return null;

    const convDoc = await db.collection('conversations').doc(conversationId).get();
    if (!convDoc.exists) return null;

    const conv = convDoc.data()!;
    const participants: string[] = conv.participants || [];
    if (!participants.includes(senderId)) return null;
    const recipientId = participants.find((participant) => participant !== senderId);
    if (!recipientId) return null;

    const participantNames: Record<string, string> =
      conv.participant_names || {};
    const senderName = participantNames[senderId] || 'Someone';
    const userDoc = await db.collection('users').doc(recipientId).get();
    if (!userDoc.exists) return null;

    const fcmTokens: string[] = userDoc.data()?.fcm_tokens || [];
    if (fcmTokens.length === 0) return null;

    const body = text.length > 100 ? `${text.substring(0, 100)}...` : text;
    await Promise.all(
      fcmTokens.map(async (token) => {
        try {
          await admin.messaging().send({
            token,
            notification: {title: senderName, body},
            data: {
              type: 'new_message',
              conversationId,
              senderId,
              senderName,
              body,
            },
            android: {
              priority: 'high',
              notification: {channelId: 'messages'},
            },
            apns: {
              payload: {
                aps: {sound: 'default'},
              },
            },
          });
        } catch (error: any) {
          const code = error?.code || error?.errorInfo?.code;
          if (
            code === 'messaging/invalid-registration-token' ||
            code === 'messaging/registration-token-not-registered'
          ) {
            await db.collection('users').doc(recipientId).update({
              fcm_tokens: admin.firestore.FieldValue.arrayRemove(token),
            });
          }
          console.error(`Failed to send push to ${recipientId}:`, error);
        }
      })
    );

    return null;
  });
