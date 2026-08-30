import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import {
  buildCancellationOrderPayload,
  buildPremiumSubscriptionPayload,
  CANCELLATION_CHARGE_AMOUNT,
  cancelCashfreeSubscription,
  cashfreeRequest,
  CashfreeSubscriptionResponse,
  createCashfreeOrder,
  extractUserIdFromPgWebhook,
  extractUserIdFromWebhook,
  fetchCashfreeOrder,
  getCashfreeConfig,
  getWebhookVerificationSecret,
  isCancellationChargeSuccessWebhook,
  isCancellationOrderIdForUser,
  isAuthorizationSuccessWebhook,
  isPaidOrderStatus,
  isPaymentWebhookType,
  isPendingSubscriptionStatus,
  isPremiumActivationWebhook,
  isPremiumDeactivationWebhook,
  isReusableOrderStatus,
  isTerminalSubscriptionStatus,
  normalizeIndianPhone,
  readWebhookRawBody,
  verifyWebhookSignature,
  type CashfreePgWebhookPayload,
  type CashfreeWebhookPayload,
} from './cashfree';

admin.initializeApp();
const db = admin.firestore();
const RTDB_INSTANCE = 'talenthire-d86a1-default-rtdb';

/** All payment-related functions run in Mumbai for lowest latency to Cashfree India. */
const FUNCTION_REGION = 'asia-south1';

const PREMIUM_TRIAL_DAYS = 1;
const PAY_TO_CANCEL_MESSAGE =
  'Pay ₹299 in PhonePe to cancel your subscription.';

/** How long (ms) a cached Firestore subscription session is considered fresh. */
const SESSION_CACHE_TTL_MS = 5 * 60 * 1000; // 5 minutes

/** Cashfree expects IST timestamps, e.g. 2025-06-01T10:20:12+05:30 */
function formatCashfreeIstIso(date: Date): string {
  const istOffsetMs = 5.5 * 60 * 60 * 1000;
  const ist = new Date(date.getTime() + istOffsetMs);
  const y = ist.getUTCFullYear();
  const mo = String(ist.getUTCMonth() + 1).padStart(2, '0');
  const d = String(ist.getUTCDate()).padStart(2, '0');
  const h = String(ist.getUTCHours()).padStart(2, '0');
  const mi = String(ist.getUTCMinutes()).padStart(2, '0');
  const s = String(ist.getUTCSeconds()).padStart(2, '0');
  return `${y}-${mo}-${d}T${h}:${mi}:${s}+05:30`;
}

function addDaysIso(days: number, from: Date = new Date()): string {
  const result = new Date(from.getTime());
  result.setDate(result.getDate() + days);
  return formatCashfreeIstIso(result);
}

function parseIsoDate(value: string | undefined | null): Date | null {
  if (!value) return null;
  const ms = Date.parse(value);
  return Number.isNaN(ms) ? null : new Date(ms);
}

/**
 * Pending checkout sessions go stale when first_charge_at is too soon or already
 * past — Cashfree would charge ₹299 almost immediately after ₹1 auth instead of
 * waiting PREMIUM_TRIAL_DAYS from authorization.
 */
function isFirstChargeScheduleStale(firstChargeAt: string | undefined): boolean {
  const scheduled = parseIsoDate(firstChargeAt);
  if (!scheduled) return true;
  const minLeadMs = (PREMIUM_TRIAL_DAYS - 1) * 24 * 60 * 60 * 1000;
  return scheduled.getTime() < Date.now() + minLeadMs;
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
  // Fetch both docs in parallel to save ~200-400ms (Option C).
  const [userDoc, profileDoc] = await Promise.all([
    db.collection('users').doc(userId).get(),
    db.collection('profiles').doc(userId).get(),
  ]);
  const user = userDoc.data() ?? {};
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

function pgWebhookNotifyUrl(): string {
  const projectId =
    process.env.GCLOUD_PROJECT ||
    process.env.GCP_PROJECT ||
    'talenthire-d86a1';
  return `https://${FUNCTION_REGION}-${projectId}.cloudfunctions.net/cashfreePgWebhook`;
}

function cancellationOrderId(userId: string): string {
  return `cxl_${userId}_${Date.now()}`;
}

interface LocalSubscriptionRecord {
  subscription_id?: string;
  user_id?: string;
  subscription_status?: string;
  cancellation_order_id?: string;
  cancellation_order_status?: string;
  cancellation_payment_session_id?: string;
}

async function loadOwnedSubscription(
  userId: string,
): Promise<{local: LocalSubscriptionRecord; subscriptionId: string}> {
  const localDoc = await db.collection('subscriptions').doc(userId).get();
  if (!localDoc.exists) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'No active subscription to cancel.',
    );
  }

  const local = (localDoc.data() ?? {}) as LocalSubscriptionRecord;
  const subscriptionId = local.subscription_id;
  const subscriptionOwnerId = local.user_id;

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

  return {local, subscriptionId};
}

async function applySubscriptionCancellation({
  userId,
  subscriptionId,
  remoteStatus,
}: {
  userId: string;
  subscriptionId: string;
  remoteStatus: string;
}): Promise<string> {
  let status = remoteStatus;
  const config = getCashfreeConfig();

  if (!isTerminalSubscriptionStatus(status)) {
    try {
      const cancelled = await cancelCashfreeSubscription(config, subscriptionId);
      status = cancelled.subscription_status ?? 'CANCELLED';
    } catch (error) {
      try {
        const remote = await fetchCashfreeSubscription(config, subscriptionId);
        status = remote.subscription_status ?? status;
      } catch {
        // Keep the pre-cancel status and fail below if still active.
      }

      if (!isTerminalSubscriptionStatus(status)) {
        functions.logger.error('applySubscriptionCancellation: Cashfree cancel failed', {
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

  const finalStatus = isTerminalSubscriptionStatus(status)
    ? status
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

  return finalStatus;
}

async function markCancellationOrderPaid(
  userId: string,
  orderId: string,
): Promise<void> {
  await db.collection('subscriptions').doc(userId).set(
    {
      cancellation_order_id: orderId,
      cancellation_order_status: 'PAID',
      cancellation_amount: CANCELLATION_CHARGE_AMOUNT,
      cancellation_paid_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    },
    {merge: true},
  );
}

async function finalizeCancellationAfterPaidOrder({
  userId,
  orderId,
}: {
  userId: string;
  orderId: string;
}): Promise<{status: string; isPremium: false}> {
  if (!isCancellationOrderIdForUser(orderId, userId)) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Cannot use this payment to cancel.',
    );
  }

  const {local, subscriptionId} = await loadOwnedSubscription(userId);

  const config = getCashfreeConfig();
  const order = await fetchCashfreeOrder(config, orderId);
  if (!isPaidOrderStatus(order.order_status)) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      PAY_TO_CANCEL_MESSAGE,
    );
  }
  if (Number(order.order_amount) !== CANCELLATION_CHARGE_AMOUNT) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Invalid cancellation payment.',
    );
  }

  await markCancellationOrderPaid(userId, orderId);

  let remoteStatus = local.subscription_status ?? '';
  try {
    const remote = await fetchCashfreeSubscription(config, subscriptionId);
    remoteStatus = remote.subscription_status ?? remoteStatus;
  } catch (error) {
    functions.logger.warn('finalizeCancellationAfterPaidOrder: could not fetch status', {
      userId,
      subscriptionId,
      error,
    });
  }

  const finalStatus = await applySubscriptionCancellation({
    userId,
    subscriptionId,
    remoteStatus,
  });

  return {status: finalStatus, isPremium: false};
}

async function resolveCancellationChargeUserId(
  payload: CashfreePgWebhookPayload,
): Promise<string | null> {
  const orderId = payload.data?.order?.order_id ?? '';
  const taggedUserId = extractUserIdFromPgWebhook(payload);

  if (taggedUserId) {
    const stored = await db.collection('subscriptions').doc(taggedUserId).get();
    const storedOrderId = stored.data()?.cancellation_order_id as
      | string
      | undefined;
    if (
      storedOrderId === orderId ||
      isCancellationOrderIdForUser(orderId, taggedUserId)
    ) {
      return taggedUserId;
    }
  }

  if (orderId) {
    const match = await db
      .collection('subscriptions')
      .where('cancellation_order_id', '==', orderId)
      .limit(1)
      .get();
    if (!match.empty) {
      return match.docs[0].id;
    }
  }

  return null;
}

async function handleCancellationChargePayment(
  payload: CashfreePgWebhookPayload,
): Promise<void> {
  if (!isCancellationChargeSuccessWebhook(payload)) {
    return;
  }

  const orderId = payload.data?.order?.order_id;
  if (!orderId) {
    return;
  }

  const userId = await resolveCancellationChargeUserId(payload);
  if (!userId) {
    functions.logger.warn('cancellation charge webhook: user not found', {
      orderId,
    });
    return;
  }

  try {
    await finalizeCancellationAfterPaidOrder({userId, orderId});
  } catch (error) {
    functions.logger.error('cancellation charge webhook: finalize failed', {
      userId,
      orderId,
      error,
    });
  }
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

  if (isFirstChargeScheduleStale(existingFirstChargeAt)) {
    functions.logger.info('createPremiumSubscription: stale first_charge_at', {
      userId,
      subscriptionId: existingSubscriptionId,
      firstChargeAt: existingFirstChargeAt,
    });
    try {
      await cancelCashfreeSubscription(config, existingSubscriptionId);
    } catch (error) {
      functions.logger.warn('createPremiumSubscription: could not cancel stale subscription', {
        userId,
        subscriptionId: existingSubscriptionId,
        error,
      });
    }
    return null;
  }

  let remoteStatus = (existing.subscription_status as string | undefined) ?? '';
  let remoteSessionId = existingSessionId ?? '';

  // Option E: Skip the Cashfree GET if the Firestore doc was refreshed within the last
  // SESSION_CACHE_TTL_MS. This avoids a ~400ms round-trip on retry/pre-creation calls.
  const updatedAt = existing.updated_at as admin.firestore.Timestamp | undefined;
  const ageMs = updatedAt ? Date.now() - updatedAt.toMillis() : Infinity;
  const isFresh = ageMs < SESSION_CACHE_TTL_MS;

  if (isFresh && isPendingSubscriptionStatus(remoteStatus) && remoteSessionId) {
    functions.logger.info('createPremiumSubscription: using cached session (fresh)', {
      userId,
      subscriptionId: existingSubscriptionId,
      ageMs: Math.round(ageMs),
    });
    // Return the cached session immediately — no Cashfree API call.
    return buildSubscriptionSessionResponse({
      config,
      subscriptionId: existingSubscriptionId,
      subscriptionSessionId: remoteSessionId,
      firstChargeAt: existingFirstChargeAt || addDaysIso(PREMIUM_TRIAL_DAYS),
    });
  }

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
 * - ₹1 authorization now (when user completes UPI mandate)
 * - ₹299/month starting PREMIUM_TRIAL_DAYS after subscription is created at Pay tap
 *
 * Subscription is created only when the user taps Pay (not on screen open) so
 * first_charge_at stays ~3 days after the ₹1 authorization.
 */
export const createPremiumSubscription = functions.region(FUNCTION_REGION).https.onCall(
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

    let created: CashfreeSubscriptionResponse;
    try {
      created = await cashfreeRequest<CashfreeSubscriptionResponse>({
        config,
        method: 'POST',
        path: '/subscriptions',
        body: payload,
      });
    } catch (err) {
      functions.logger.error('createPremiumSubscription: Cashfree API error', {
        userId,
        error: err,
      });
      throw new functions.https.HttpsError(
        'unavailable',
        err instanceof Error ? err.message : 'Could not create subscription. Try again.',
      );
    }

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
export const verifyPremiumSubscription = functions.region(FUNCTION_REGION).https.onCall(
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
    const alreadyAuthorized = Boolean(local.authorized_at);

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
        ...(isActive && !alreadyAuthorized
          ? {
              authorized_at: admin.firestore.FieldValue.serverTimestamp(),
              first_charge_at: addDaysIso(PREMIUM_TRIAL_DAYS),
            }
          : {}),
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
 * Creates a ₹299 Cashfree order and returns a PhonePe UPI session.
 * Subscription is not cancelled until the charge is paid.
 */
export const createCancellationCharge = functions.region(FUNCTION_REGION).https.onCall(
  async (_data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Sign in to cancel your subscription.',
      );
    }

    const userId = context.auth.uid;
    const {local, subscriptionId} = await loadOwnedSubscription(userId);
    const config = getCashfreeConfig();

    let remoteStatus = local.subscription_status ?? '';
    try {
      const remote = await fetchCashfreeSubscription(config, subscriptionId);
      remoteStatus = remote.subscription_status ?? remoteStatus;
    } catch (error) {
      functions.logger.warn('createCancellationCharge: could not fetch status', {
        userId,
        subscriptionId,
        error,
      });
    }

    if (isTerminalSubscriptionStatus(remoteStatus)) {
      const finalStatus = await applySubscriptionCancellation({
        userId,
        subscriptionId,
        remoteStatus,
      });
      return {
        alreadyCancelled: true,
        status: finalStatus,
        isPremium: false,
        orderId: local.cancellation_order_id ?? '',
        paymentSessionId: '',
        environment: config.environment,
        amount: CANCELLATION_CHARGE_AMOUNT,
      };
    }

    const existingOrderId = local.cancellation_order_id;
    if (existingOrderId && isCancellationOrderIdForUser(existingOrderId, userId)) {
      try {
        const existingOrder = await fetchCashfreeOrder(config, existingOrderId);
        if (isPaidOrderStatus(existingOrder.order_status)) {
          const result = await finalizeCancellationAfterPaidOrder({
            userId,
            orderId: existingOrderId,
          });
          return {
            alreadyCancelled: true,
            status: result.status,
            isPremium: false,
            orderId: existingOrderId,
            paymentSessionId: '',
            environment: config.environment,
            amount: CANCELLATION_CHARGE_AMOUNT,
          };
        }

        if (
          isReusableOrderStatus(existingOrder.order_status) &&
          existingOrder.payment_session_id
        ) {
          await db.collection('subscriptions').doc(userId).set(
            {
              cancellation_order_id: existingOrder.order_id,
              cancellation_order_status: existingOrder.order_status,
              cancellation_payment_session_id: existingOrder.payment_session_id,
              cancellation_amount: CANCELLATION_CHARGE_AMOUNT,
              updated_at: admin.firestore.FieldValue.serverTimestamp(),
            },
            {merge: true},
          );

          return {
            alreadyCancelled: false,
            orderId: existingOrder.order_id,
            paymentSessionId: existingOrder.payment_session_id,
            environment: config.environment,
            amount: CANCELLATION_CHARGE_AMOUNT,
          };
        }
      } catch (error) {
        functions.logger.warn('createCancellationCharge: could not reuse order', {
          userId,
          orderId: existingOrderId,
          error,
        });
      }
    }

    const customer = await loadCustomerDetails(userId);
    const orderId = cancellationOrderId(userId);
    const created = await createCashfreeOrder(
      config,
      buildCancellationOrderPayload({
        orderId,
        customerId: userId,
        customerName: customer.name,
        customerEmail: customer.email,
        customerPhone: customer.phone,
        notifyUrl: pgWebhookNotifyUrl(),
      }),
    );

    if (!created.payment_session_id) {
      throw new functions.https.HttpsError(
        'unavailable',
        'Could not start PhonePe payment. Try again.',
      );
    }

    await db.collection('subscriptions').doc(userId).set(
      {
        cancellation_order_id: created.order_id,
        cancellation_order_status: created.order_status,
        cancellation_payment_session_id: created.payment_session_id,
        cancellation_amount: CANCELLATION_CHARGE_AMOUNT,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: true},
    );

    return {
      alreadyCancelled: false,
      orderId: created.order_id,
      paymentSessionId: created.payment_session_id,
      environment: config.environment,
      amount: CANCELLATION_CHARGE_AMOUNT,
    };
  },
);

/**
 * Verifies the ₹299 PhonePe payment, then cancels Autopay and ends Premium.
 */
export const completeCancellationAfterCharge = functions.region(FUNCTION_REGION).https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Sign in to cancel your subscription.',
      );
    }

    const orderId = (data as {orderId?: string})?.orderId;
    if (!orderId) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        PAY_TO_CANCEL_MESSAGE,
      );
    }

    return finalizeCancellationAfterPaidOrder({
      userId: context.auth.uid,
      orderId,
    });
  },
);

/**
 * Completes cancellation only after a ₹299 PhonePe charge is paid.
 * Idempotent: already-cancelled subscriptions still expire local premium.
 */
export const cancelPremiumSubscription = functions.region(FUNCTION_REGION).https.onCall(
  async (_data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Sign in to cancel your subscription.',
      );
    }

    const userId = context.auth.uid;
    const {local, subscriptionId} = await loadOwnedSubscription(userId);
    const config = getCashfreeConfig();
    let remoteStatus = local.subscription_status ?? '';

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

    if (isTerminalSubscriptionStatus(remoteStatus)) {
      const finalStatus = await applySubscriptionCancellation({
        userId,
        subscriptionId,
        remoteStatus,
      });
      return {status: finalStatus, isPremium: false};
    }

    const orderId = local.cancellation_order_id;
    if (orderId) {
      return finalizeCancellationAfterPaidOrder({userId, orderId});
    }

    throw new functions.https.HttpsError(
      'failed-precondition',
      PAY_TO_CANCEL_MESSAGE,
    );
  },
);

export const cashfreeSubscriptionWebhook = functions.region(FUNCTION_REGION).https.onRequest(
  handleCashfreeHttpWebhook,
);

/** Same handler as subscriptions — point Cashfree PG webhooks here. */
export const cashfreePgWebhook = functions.region(FUNCTION_REGION).https.onRequest(
  handleCashfreeHttpWebhook,
);

async function handleCashfreeHttpWebhook(
  req: functions.https.Request,
  res: functions.Response,
): Promise<void> {
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

    if (isPaymentWebhookType(payload.type)) {
      await handleCancellationChargePayment(
        payload as unknown as CashfreePgWebhookPayload,
      );
      res.status(200).send('OK');
      return;
    }

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
          ...(isAuthorizationSuccessWebhook(payload)
            ? {
                authorized_at: admin.firestore.FieldValue.serverTimestamp(),
                // Display schedule: ₹299 due PREMIUM_TRIAL_DAYS after ₹1 auth.
                first_charge_at: addDaysIso(PREMIUM_TRIAL_DAYS),
              }
            : {}),
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
}

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
