import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import {
  buildPremiumSubscriptionPayload,
  cancelCashfreeSubscription,
  cashfreeRequest,
  CashfreeSubscriptionResponse,
  extractUserIdFromWebhook,
  getCashfreeConfig,
  getWebhookVerificationSecret,
  isPendingSubscriptionStatus,
  isPremiumActivationWebhook,
  isPremiumDeactivationWebhook,
  isTerminalSubscriptionStatus,
  normalizeIndianPhone,
  readWebhookRawBody,
  verifyWebhookSignature,
  type CashfreeWebhookPayload,
} from './cashfree';

admin.initializeApp();
const db = admin.firestore();
const RTDB_INSTANCE = 'talenthire-d86a1-default-rtdb';

const PREMIUM_TRIAL_DAYS = 3;

function addDaysIso(days: number): string {
  const date = new Date();
  date.setDate(date.getDate() + days);
  return date.toISOString();
}

async function setUserSubscriptionStatus(
  userId: string,
  status: 'premium' | 'expired' | 'free',
): Promise<void> {
  await db.collection('profiles').doc(userId).set(
    {
      subscription_status: status,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    },
    {merge: true},
  );
}

async function loadCustomerDetails(userId: string): Promise<{
  name: string;
  email: string;
  phone: string;
}> {
  const userDoc = await db.collection('users').doc(userId).get();
  const user = userDoc.data() ?? {};
  const profileDoc = await db.collection('profiles').doc(userId).get();
  const profile = profileDoc.data() ?? {};

  const name = (user.name as string | undefined)?.trim() || 'Premium User';
  const email = (user.email as string | undefined)?.trim() || '';
  const phone =
    normalizeIndianPhone((user.mobile as string | undefined) ?? '') ||
    normalizeIndianPhone((profile.contact as string | undefined) ?? '') ||
    '9999999999';

  if (!email) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Add an email to your account before subscribing.',
    );
  }

  return {name, email, phone};
}

interface CashfreeSubscriptionDetails {
  subscription_status?: string;
  subscription_session_id?: string;
  authorisation_details?: {authorization_status?: string};
}

async function fetchCashfreeSubscription(
  config: ReturnType<typeof getCashfreeConfig>,
  subscriptionId: string,
): Promise<CashfreeSubscriptionDetails> {
  return cashfreeRequest<CashfreeSubscriptionDetails>({
    config,
    method: 'GET',
    path: `/subscriptions/${encodeURIComponent(subscriptionId)}`,
  });
}

function buildSubscriptionSessionResponse({
  config,
  subscriptionId,
  subscriptionSessionId,
  firstChargeAt,
}: {
  config: ReturnType<typeof getCashfreeConfig>;
  subscriptionId: string;
  subscriptionSessionId: string;
  firstChargeAt: string;
}) {
  return {
    subscriptionId,
    subscriptionSessionId,
    environment: config.environment,
    firstChargeAt,
  };
}

/**
 * Reuses an in-progress subscription when the user retries checkout, instead of
 * creating orphan Cashfree subscriptions that can charge without activating premium.
 */
async function resolveExistingSubscriptionSession(
  userId: string,
  config: ReturnType<typeof getCashfreeConfig>,
): Promise<ReturnType<typeof buildSubscriptionSessionResponse> | null> {
  const existingSubDoc = await db.collection('subscriptions').doc(userId).get();
  if (!existingSubDoc.exists) {
    return null;
  }

  const existing = existingSubDoc.data()!;
  const existingSubscriptionId = existing.subscription_id as string | undefined;
  const existingSessionId = existing.subscription_session_id as string | undefined;
  const existingFirstChargeAt = (existing.first_charge_at as string | undefined) ?? '';

  if (
    !existingSubscriptionId ||
    !existingSubscriptionId.startsWith(`premium_${userId}_`)
  ) {
    return null;
  }

  let remoteStatus = (existing.subscription_status as string | undefined) ?? '';
  let remoteSessionId = existingSessionId ?? '';

  try {
    const remote = await fetchCashfreeSubscription(config, existingSubscriptionId);
    remoteStatus = remote.subscription_status ?? remoteStatus;
    remoteSessionId = remote.subscription_session_id ?? remoteSessionId;
  } catch (error) {
    functions.logger.warn('createPremiumSubscription: could not refresh existing subscription', {
      userId,
      subscriptionId: existingSubscriptionId,
      error,
    });
    if (!isPendingSubscriptionStatus(remoteStatus) || !remoteSessionId) {
      return null;
    }
  }

  if (remoteStatus === 'ACTIVE') {
    await setUserSubscriptionStatus(userId, 'premium');
    throw new functions.https.HttpsError(
      'already-exists',
      'You are already a Premium member.',
    );
  }

  if (isPendingSubscriptionStatus(remoteStatus) && remoteSessionId) {
    await db.collection('subscriptions').doc(userId).set(
      {
        subscription_status: remoteStatus,
        subscription_session_id: remoteSessionId,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: true},
    );

    functions.logger.info('createPremiumSubscription: reusing pending subscription', {
      userId,
      subscriptionId: existingSubscriptionId,
      status: remoteStatus,
    });

    return buildSubscriptionSessionResponse({
      config,
      subscriptionId: existingSubscriptionId,
      subscriptionSessionId: remoteSessionId,
      firstChargeAt: existingFirstChargeAt || addDaysIso(PREMIUM_TRIAL_DAYS),
    });
  }

  if (isTerminalSubscriptionStatus(remoteStatus)) {
    return null;
  }

  return null;
}

/**
 * Creates a Cashfree UPI Autopay subscription:
 * - ₹1 authorization now
 * - ₹299/month starting 3 days later
 */
export const createPremiumSubscription = functions.https.onCall(
  async (_data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Sign in to subscribe.',
      );
    }

    const userId = context.auth.uid;

    // Server-side guard: do not create a new subscription if user is already premium.
    // This prevents overwriting a valid subscriptions/{userId} doc and prevents double-billing.
    const existingProfile = await db.collection('profiles').doc(userId).get();
    if (existingProfile.data()?.subscription_status === 'premium') {
      throw new functions.https.HttpsError(
        'already-exists',
        'You are already a Premium member.',
      );
    }

    const config = getCashfreeConfig();

    const reusedSession = await resolveExistingSubscriptionSession(userId, config);
    if (reusedSession) {
      return reusedSession;
    }

    const customer = await loadCustomerDetails(userId);
    const subscriptionId = `premium_${userId}_${Date.now()}`;
    const firstChargeTimeIso = addDaysIso(PREMIUM_TRIAL_DAYS);

    const payload = buildPremiumSubscriptionPayload({
      subscriptionId,
      customerName: customer.name,
      customerEmail: customer.email,
      customerPhone: customer.phone,
      userId,
      firstChargeTimeIso,
    });

    const created = await cashfreeRequest<CashfreeSubscriptionResponse>({
      config,
      method: 'POST',
      path: '/subscriptions',
      body: payload,
    });

    await db.collection('subscriptions').doc(userId).set(
      {
        user_id: userId,
        subscription_id: created.subscription_id,
        cf_subscription_id: created.cf_subscription_id ?? null,
        subscription_session_id: created.subscription_session_id,
        subscription_status: created.subscription_status,
        authorization_amount: 1,
        recurring_amount: 299,
        first_charge_at: firstChargeTimeIso,
        provider: 'cashfree',
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: true},
    );

    return buildSubscriptionSessionResponse({
      config,
      subscriptionId: created.subscription_id,
      subscriptionSessionId: created.subscription_session_id,
      firstChargeAt: firstChargeTimeIso,
    });
  },
);

/**
 * Client-side verification after UPI mandate flow returns.
 * Webhooks remain the source of truth; this helps the UI update faster.
 * Accepts an optional subscriptionId to validate ownership before querying Cashfree.
 */
export const verifyPremiumSubscription = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Sign in to verify subscription.',
      );
    }

    const userId = context.auth.uid;
    const localDoc = await db.collection('subscriptions').doc(userId).get();
    if (!localDoc.exists) {
      return {status: 'missing', isPremium: false};
    }

    const local = localDoc.data()!;
    const subscriptionId = local.subscription_id as string;
    const subscriptionOwnerId = local.user_id as string | undefined;

    // Ownership check 1: stored user_id must match the calling uid.
    if (subscriptionOwnerId && subscriptionOwnerId !== userId) {
      return {status: 'forbidden', isPremium: false};
    }

    // Ownership check 2: subscription_id must be scoped to this uid.
    if (!subscriptionId.startsWith(`premium_${userId}_`)) {
      return {status: 'forbidden', isPremium: false};
    }

    // Ownership check 3: if the caller passed a subscriptionId, it must match.
    const callerSubscriptionId = (data as {subscriptionId?: string})?.subscriptionId;
    if (callerSubscriptionId && callerSubscriptionId !== subscriptionId) {
      functions.logger.warn('verifyPremiumSubscription: subscriptionId mismatch', {
        userId,
        caller: callerSubscriptionId,
        stored: subscriptionId,
      });
      return {status: 'forbidden', isPremium: false};
    }

    const config = getCashfreeConfig();

    const remote = await fetchCashfreeSubscription(config, subscriptionId);

    const subscriptionStatus = remote.subscription_status ?? 'UNKNOWN';
    const authStatus =
      remote.authorisation_details?.authorization_status ?? 'UNKNOWN';

    // Only treat ACTIVE subscription status as premium. Do NOT use authStatus === 'SUCCESS'
    // alone — that only means the mandate was accepted, the subscription could still be cancelled.
    const isActive = subscriptionStatus === 'ACTIVE';

    await db.collection('subscriptions').doc(userId).set(
      {
        subscription_status: subscriptionStatus,
        authorization_status: authStatus,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: true},
    );

    if (isActive) {
      await setUserSubscriptionStatus(userId, 'premium');
    } else if (isTerminalSubscriptionStatus(subscriptionStatus)) {
      const current = await db.collection('profiles').doc(userId).get();
      if (current.data()?.subscription_status === 'premium') {
        await setUserSubscriptionStatus(userId, 'expired');
      }
    }

    const profileDoc = await db.collection('profiles').doc(userId).get();
    const isPremium =
      profileDoc.data()?.subscription_status === 'premium' || isActive;

    return {
      status: subscriptionStatus,
      authorizationStatus: authStatus,
      isPremium,
    };
  },
);

/**
 * Cancels the signed-in user's Cashfree UPI Autopay mandate and ends Premium.
 * Idempotent: already-cancelled subscriptions still expire local premium.
 */
export const cancelPremiumSubscription = functions.https.onCall(
  async (_data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Sign in to cancel your subscription.',
      );
    }

    const userId = context.auth.uid;
    const localDoc = await db.collection('subscriptions').doc(userId).get();
    if (!localDoc.exists) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'No active subscription to cancel.',
      );
    }

    const local = localDoc.data()!;
    const subscriptionId = local.subscription_id as string | undefined;
    const subscriptionOwnerId = local.user_id as string | undefined;

    if (subscriptionOwnerId && subscriptionOwnerId !== userId) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Cannot cancel this subscription.',
      );
    }

    if (!subscriptionId || !subscriptionId.startsWith(`premium_${userId}_`)) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Cannot cancel this subscription.',
      );
    }

    const config = getCashfreeConfig();
    let remoteStatus = (local.subscription_status as string | undefined) ?? '';

    try {
      const remote = await fetchCashfreeSubscription(config, subscriptionId);
      remoteStatus = remote.subscription_status ?? remoteStatus;
    } catch (error) {
      functions.logger.warn('cancelPremiumSubscription: could not fetch status', {
        userId,
        subscriptionId,
        error,
      });
    }

    if (!isTerminalSubscriptionStatus(remoteStatus)) {
      try {
        const cancelled = await cancelCashfreeSubscription(config, subscriptionId);
        remoteStatus = cancelled.subscription_status ?? 'CANCELLED';
      } catch (error) {
        try {
          const remote = await fetchCashfreeSubscription(config, subscriptionId);
          remoteStatus = remote.subscription_status ?? remoteStatus;
        } catch {
          // Keep the pre-cancel status and fail below if still active.
        }

        if (!isTerminalSubscriptionStatus(remoteStatus)) {
          functions.logger.error('cancelPremiumSubscription: Cashfree cancel failed', {
            userId,
            subscriptionId,
            error,
          });
          throw new functions.https.HttpsError(
            'unavailable',
            error instanceof Error
              ? error.message
              : 'Could not cancel subscription. Try again.',
          );
        }
      }
    }

    const finalStatus = isTerminalSubscriptionStatus(remoteStatus)
      ? remoteStatus
      : 'CANCELLED';

    await db.collection('subscriptions').doc(userId).set(
      {
        subscription_status: finalStatus,
        cancelled_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: true},
    );

    const profileDoc = await db.collection('profiles').doc(userId).get();
    if (profileDoc.data()?.subscription_status === 'premium') {
      await setUserSubscriptionStatus(userId, 'expired');
    }

    return {
      status: finalStatus,
      isPremium: false,
    };
  },
);

export const cashfreeSubscriptionWebhook = functions.https.onRequest(
  async (req, res) => {
    // Cashfree dashboard connectivity checks may use GET/HEAD.
    if (req.method === 'GET' || req.method === 'HEAD') {
      res.status(200).send('OK');
      return;
    }

    if (req.method !== 'POST') {
      res.status(405).send('Method not allowed');
      return;
    }

    const config = getCashfreeConfig();
    const rawBody = readWebhookRawBody(req);
    const signature = req.get('x-webhook-signature') ?? '';
    const timestamp = req.get('x-webhook-timestamp') ?? '';

    // Dashboard "Test Webhook Endpoint" often POSTs without signature headers.
    if (!signature || !timestamp) {
      functions.logger.info('Cashfree webhook test/ping received (no signature)');
      res.status(200).send('OK');
      return;
    }

    const verificationSecret = getWebhookVerificationSecret(config);
    const signatureValid = verifyWebhookSignature({
      rawBody,
      signature,
      timestamp,
      secret: verificationSecret,
    });

    if (!signatureValid) {
      functions.logger.warn('Cashfree webhook signature mismatch');
      res.status(401).send('Invalid webhook signature');
      return;
    }

    let payload: CashfreeWebhookPayload;
    try {
      payload = rawBody
        ? (JSON.parse(rawBody) as CashfreeWebhookPayload)
        : (req.body as CashfreeWebhookPayload);
    } catch {
      res.status(400).send('Invalid JSON');
      return;
    }

    functions.logger.info('Cashfree webhook received', {type: payload.type});

    const subscriptionId =
      payload.data?.subscription_details?.subscription_id ?? null;
    let userId = extractUserIdFromWebhook(payload);

    if (!userId && subscriptionId) {
      const match = await db
        .collection('subscriptions')
        .where('subscription_id', '==', subscriptionId)
        .limit(1)
        .get();
      if (!match.empty) {
        userId = match.docs[0].id;
      }
    }

    if (userId) {
      // Ownership validation: verify the resolved userId actually owns this subscriptionId.
      // This prevents spoofed webhooks (if HMAC is somehow bypassed) from granting
      // premium to an arbitrary user.
      if (subscriptionId) {
        const storedDoc = await db.collection('subscriptions').doc(userId).get();
        const storedSubscriptionId = storedDoc.data()?.subscription_id as string | undefined;
        const storedUserId = storedDoc.data()?.user_id as string | undefined;

        const subscriptionIdValid =
          storedSubscriptionId === subscriptionId &&
          storedSubscriptionId.startsWith(`premium_${userId}_`);
        const userIdValid = !storedUserId || storedUserId === userId;

        if (!subscriptionIdValid || !userIdValid) {
          functions.logger.error('Cashfree webhook: ownership validation failed', {
            webhookSubscriptionId: subscriptionId,
            storedSubscriptionId,
            resolvedUserId: userId,
            storedUserId,
          });
          res.status(200).send('OK'); // Return 200 to Cashfree to avoid retries
          return;
        }
      }

      const authDetails =
        payload.data?.authorization_details ??
        payload.data?.authorisation_details;

      await db.collection('subscriptions').doc(userId).set(
        {
          subscription_id: subscriptionId,
          last_webhook_type: payload.type ?? null,
          subscription_status:
            payload.data?.subscription_details?.subscription_status ?? null,
          authorization_status: authDetails?.authorization_status ?? null,
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        },
        {merge: true},
      );

      if (isPremiumActivationWebhook(payload)) {
        await setUserSubscriptionStatus(userId, 'premium');
      } else if (isPremiumDeactivationWebhook(payload)) {
        await setUserSubscriptionStatus(userId, 'expired');
      }
    }

    res.status(200).send('OK');
  },
);

/**
 * Sends a push notification to the recipient when a chat message is created.
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
      }),
    );

    return null;
  });
