import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import axios from 'axios';
import * as crypto from 'crypto';

admin.initializeApp();
const db = admin.firestore();

// Cashfree Sandbox Credentials
const CLIENT_ID = process.env.CASHFREE_CLIENT_ID || '';
const CLIENT_SECRET = process.env.CASHFREE_CLIENT_SECRET || '';
const ENVIRONMENT = 'sandbox'; // change to 'production' later
const BASE_URL =
  ENVIRONMENT === 'sandbox'
    ? 'https://sandbox.cashfree.com/pg'
    : 'https://api.cashfree.com/pg';

const PLATFORM_USER_ID = 'platform';
const SUBSCRIPTION_DAYS = 30;

/**
 * Sanitize a value to be a safe Cashfree customer_id:
 * alphanumeric + underscore only, max 36 chars.
 */
function sanitizeCustomerId(id: string): string {
  return id.replace(/[^a-zA-Z0-9_]/g, '_').substring(0, 36);
}

/**
 * Creates a Cashfree order and returns the payment_session_id.
 * Gen 1 onCall function (preserved to avoid Gen 1 → Gen 2 migration error).
 */
export const createCashfreeOrder = functions.https.onCall(async (data, _context) => {
  const userId: string = data.userId;
  const amount: number = data.amount;
  const purpose: string = data.purpose;

  if (!userId || !amount || !purpose) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Missing required parameters: userId, amount, purpose'
    );
  }

  // Cashfree customer_id must be alphanumeric/underscore, max 36 chars
  const customerId = sanitizeCustomerId(userId);
  // Cashfree order_id max length is 50 chars
  const orderId = `ord_${Date.now()}_${customerId.substring(0, 20)}`;

  try {
    // 1. Create a pending payment record in Firestore
    const now = new Date().toISOString();
    await db.collection('payments').doc(orderId).set({
      id: orderId,
      userId,
      amount,
      purpose,
      status: 'pending',
      currency: 'INR',
      gateway: 'cashfree',
      cashfreeOrderId: orderId,
      created_at: now,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Pending transaction visible to the payer
    await db.collection('transactions').doc(orderId).set({
      id: orderId,
      type: purpose === 'premium_upgrade' || purpose === 'agency_premium' ? 'subscription' : 'payment',
      userId,
      fromUserId: userId,
      toUserId: PLATFORM_USER_ID,
      amount,
      currency: 'INR',
      status: 'pending',
      purpose,
      paymentId: orderId,
      cashfreeOrderId: orderId,
      gateway: 'cashfree',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      created_at: now,
    });

    // 2. Call Cashfree API to create an order
    const requestBody = {
      order_id: orderId,
      order_amount: amount,
      order_currency: 'INR',
      customer_details: {
        customer_id: customerId,
        customer_phone: '9999999999', // Replace with real user phone if available
        customer_email: `${customerId}@example.com`,
        customer_name: customerId,
      },
      order_meta: {
        notify_url:
          'https://us-central1-talenthire-d86a1.cloudfunctions.net/cashfreeWebhook',
      },
    };

    const response = await axios.post(`${BASE_URL}/orders`, requestBody, {
      headers: {
        'x-client-id': CLIENT_ID,
        'x-client-secret': CLIENT_SECRET,
        'x-api-version': '2023-08-01',
        'Content-Type': 'application/json',
      },
    });

    const paymentSessionId = response.data.payment_session_id;

    if (!paymentSessionId) {
      console.error('Cashfree did not return payment_session_id:', response.data);
      throw new functions.https.HttpsError(
        'internal',
        'Cashfree did not return a payment session ID'
      );
    }

    console.log(`Order created: ${orderId}, session: ${paymentSessionId}`);

    return {
      success: true,
      orderId: orderId,
      paymentSessionId: paymentSessionId,
      environment: ENVIRONMENT,
    };
  } catch (error: any) {
    if (error instanceof functions.https.HttpsError) throw error;
    const cashfreeError = error?.response?.data;
    console.error(
      'Error creating Cashfree order:',
      JSON.stringify(cashfreeError || error?.message)
    );
    throw new functions.https.HttpsError(
      'internal',
      `Failed to create Cashfree order: ${cashfreeError?.message || error?.message || 'Unknown error'}`
    );
  }
});

/**
 * Webhook to receive Cashfree payment status updates.
 * Gen 1 onRequest — rawBody is available as Buffer in Firebase Functions Gen 1.
 */
export const cashfreeWebhook = functions.https.onRequest(async (req, res) => {
  try {
    // In Firebase Functions Gen 1, rawBody is populated as a Buffer by the framework
    const rawBody: Buffer | undefined = (req as any).rawBody;

    if (!rawBody) {
      console.error('rawBody is missing from webhook request');
      res.status(400).send('Bad Request: rawBody missing');
      return;
    }

    const signature = req.headers['x-webhook-signature'] as string;
    const timestamp = req.headers['x-webhook-timestamp'] as string;

    if (!signature || !timestamp) {
      console.warn('Missing webhook signature or timestamp headers');
      res.status(401).send('Missing signature headers');
      return;
    }

    // Validate: HMAC-SHA256(timestamp + rawBody, CLIENT_SECRET) in base64
    const signatureData = timestamp + rawBody.toString();
    const expectedSignature = crypto
      .createHmac('sha256', CLIENT_SECRET)
      .update(signatureData)
      .digest('base64');

    if (signature !== expectedSignature) {
      console.warn('Invalid webhook signature received');
      res.status(401).send('Invalid signature');
      return;
    }

    const body = req.body as { data: any; type: string };
    const { data: eventData, type } = body;

    console.log(`Webhook event received: ${type}`);

    if (type === 'PAYMENT_SUCCESS_WEBHOOK' || type === 'PAYMENT_FAILED_WEBHOOK') {
      const orderId: string = eventData?.order?.order_id;
      const paymentInfo = eventData?.payment ?? {};
      const isSuccess = type === 'PAYMENT_SUCCESS_WEBHOOK';

      if (!orderId) {
        res.status(400).send('Missing order_id in webhook payload');
        return;
      }

      const paymentRef = db.collection('payments').doc(orderId);
      const paymentDoc = await paymentRef.get();

      if (!paymentDoc.exists) {
        console.warn(`Payment not found: ${orderId}`);
        res.status(404).send('Payment not found');
        return;
      }

      const paymentData = paymentDoc.data()!;
      if (paymentData.status === 'completed' && isSuccess) {
        res.status(200).send('Already processed');
        return;
      }

      const now = new Date().toISOString();
      const paidAtRaw = paymentInfo.payment_time ?? now;
      const paidAtDate = new Date(paidAtRaw);
      const cfPaymentId = paymentInfo.cf_payment_id?.toString() ?? '';
      const gatewayResponse = {
        payment_status: paymentInfo.payment_status ?? null,
        payment_method: paymentInfo.payment_method ?? null,
        payment_amount: paymentInfo.payment_amount ?? null,
        payment_currency: paymentInfo.payment_currency ?? null,
        bank_reference: paymentInfo.bank_reference ?? null,
        auth_id: paymentInfo.auth_id ?? null,
        payment_message: paymentInfo.payment_message ?? null,
      };

      const userId: string = paymentData.userId;
      const purpose: string = paymentData.purpose;
      const amount: number = paymentData.amount;
      const finalStatus = isSuccess ? 'completed' : 'failed';

      await paymentRef.update({
        status: finalStatus,
        updated_at: now,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        paidAt: paidAtDate.toISOString(),
        cashfreePaymentId: cfPaymentId,
        gatewayResponse,
      });

      const txnRef = db.collection('transactions').doc(orderId);
      const txnUpdate: Record<string, unknown> = {
        status: finalStatus,
        cashfreePaymentId: cfPaymentId,
        gatewayResponse,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: now,
      };

      if (isSuccess) {
        txnUpdate.paidAt = admin.firestore.Timestamp.fromDate(paidAtDate);

        let subscriptionId: string | null = null;
        let expiresAt: Date | null = null;

        if (purpose === 'premium_upgrade' || purpose === 'agency_premium') {
          expiresAt = new Date();
          expiresAt.setDate(expiresAt.getDate() + SUBSCRIPTION_DAYS);
          subscriptionId = `sub_${orderId}`;

          await db.collection('subscriptions').doc(subscriptionId).set({
            id: subscriptionId,
            userId,
            plan: purpose === 'agency_premium' ? 'agency_premium' : 'influencer_premium',
            amount,
            status: 'completed',
            paymentId: orderId,
            cashfreeOrderId: orderId,
            cashfreePaymentId: cfPaymentId,
            created_at: now,
            updated_at: now,
            expires_at: expiresAt.toISOString(),
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
          });

          if (purpose === 'premium_upgrade') {
            await db.collection('profiles').doc(userId).update({
              subscription_status: 'premium',
              is_verified: true,
              subscription_expires_at: expiresAt.toISOString(),
            });
          } else {
            await db.collection('users').doc(userId).update({
              subscription_status: 'premium',
              subscription_expires_at: expiresAt.toISOString(),
            });
          }
        }

        txnUpdate.subscriptionId = subscriptionId;
        if (expiresAt) {
          txnUpdate.expiresAt = admin.firestore.Timestamp.fromDate(expiresAt);
          txnUpdate.expires_at = expiresAt.toISOString();
        }

        await txnRef.set(
          {
            id: orderId,
            type:
              purpose === 'premium_upgrade' || purpose === 'agency_premium'
                ? 'subscription'
                : 'payment',
            userId,
            fromUserId: userId,
            toUserId: PLATFORM_USER_ID,
            amount,
            currency: paymentData.currency ?? 'INR',
            purpose,
            paymentId: orderId,
            cashfreeOrderId: orderId,
            gateway: 'cashfree',
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            ...txnUpdate,
          },
          { merge: true }
        );
      } else {
        await txnRef.set(txnUpdate, { merge: true });
      }

      console.log(
        `Payment ${orderId} ${finalStatus} for user ${userId}, purpose: ${purpose}`
      );
    }

    res.status(200).send('Webhook processed successfully');
  } catch (error) {
    console.error('Webhook error:', error);
    res.status(500).send('Internal Server Error');
  }
});

const RTDB_INSTANCE = 'talenthire-d86a1-default-rtdb';

/**
 * Sends a push notification to the message recipient when a new chat message is created.
 */
export const onNewMessage = functions
  .database.instance(RTDB_INSTANCE)
  .ref('/messages/{conversationId}/{messageId}')
  .onCreate(async (snapshot, context) => {
    const message = snapshot.val();
    if (!message) return null;

    const { conversationId } = context.params;
    const senderId: string = message.sender_id;
    const text: string = message.text || 'New message';

    if (!senderId) return null;

    const convDoc = await db.collection('conversations').doc(conversationId).get();
    if (!convDoc.exists) return null;

    const conv = convDoc.data()!;
    const participants: string[] = conv.participants || [];
    const recipientId = participants.find((p) => p !== senderId);
    if (!recipientId) return null;

    const participantNames: Record<string, string> = conv.participant_names || {};
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
            notification: {
              title: senderName,
              body,
            },
            data: {
              type: 'new_message',
              conversationId,
              senderId,
              senderName,
              body,
            },
            android: {
              priority: 'high',
              notification: {
                channelId: 'messages',
              },
            },
            apns: {
              payload: {
                aps: {
                  sound: 'default',
                },
              },
            },
          });
        } catch (err: any) {
          const code = err?.code || err?.errorInfo?.code;
          if (
            code === 'messaging/invalid-registration-token' ||
            code === 'messaging/registration-token-not-registered'
          ) {
            await db.collection('users').doc(recipientId).update({
              fcm_tokens: admin.firestore.FieldValue.arrayRemove(token),
            });
          }
          console.error(`Failed to send push to ${recipientId}:`, err);
        }
      })
    );

    return null;
  });
