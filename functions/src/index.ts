import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import {
  AGENCY_PREMIUM_AMOUNT,
  buildAgencyPaymentOrderPayload,
  buildCancellationOrderPayload,
  buildPremiumSubscriptionPayload,
  CANCELLATION_CHARGE_AMOUNT,
  cancelCashfreeSubscription,
  cashfreeRequest,
  CashfreeSubscriptionResponse,
  createCashfreeOrder as createCashfreePgOrder,
  extractUserIdFromPgWebhook,
  extractUserIdFromWebhook,
  fetchCashfreeOrder,
  getCashfreeConfig,
  getWebhookVerificationSecret,
  isAgencyPaymentPurpose,
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
  type AgencyPaymentPurpose,
  type CashfreePgWebhookPayload,
  type CashfreeWebhookPayload,
} from './cashfree';
import {sendPushToUser} from './push';

admin.initializeApp();

export {
  onUserRegistered,
  sendRegistrationReminder10Min,
  sendRegistrationReminder24Hour,
} from './registrationReminders';
export {submitJobApplication} from './submitJobApplication';
export {deleteAccount} from './deleteAccount';

const db = admin.firestore();
const RTDB_INSTANCE = 'talenthire-d86a1-default-rtdb';

/** All payment-related functions run in Mumbai for lowest latency to Cashfree India. */
const FUNCTION_REGION = 'asia-south1';

const PREMIUM_TRIAL_DAYS = 3;
/** Prepaid monthly access after a successful ₹299 charge. */
const BILLING_PERIOD_DAYS = 30;
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

function parseFlexibleDate(value: unknown): Date | null {
  if (value == null) return null;
  if (value instanceof Date) return value;
  if (value instanceof admin.firestore.Timestamp) return value.toDate();
  if (typeof value === 'object' && value && 'toDate' in value) {
    try {
      return (value as admin.firestore.Timestamp).toDate();
    } catch {
      return null;
    }
  }
  if (typeof value === 'string') return parseIsoDate(value);
  return null;
}

function addDays(from: Date, days: number): Date {
  return new Date(from.getTime() + days * 24 * 60 * 60 * 1000);
}

/**
 * Current prepaid period end: last ₹299 charge + 30 days, or first_charge_at
 * walked forward in 30-day steps. Null during trial (first charge still upcoming).
 */
function currentPrepaidPeriodEnd(local: LocalSubscriptionRecord): Date | null {
  if (local.cancel_at_period_end === true) {
    return parseFlexibleDate(local.period_end_at);
  }

  const lastCharged = parseFlexibleDate(local.last_charged_at);
  if (lastCharged) {
    return addDays(lastCharged, BILLING_PERIOD_DAYS);
  }

  const firstCharge = parseFlexibleDate(local.first_charge_at);
  if (!firstCharge || firstCharge.getTime() > Date.now()) {
    return null;
  }

  let periodEnd = addDays(firstCharge, BILLING_PERIOD_DAYS);
  while (periodEnd.getTime() <= Date.now()) {
    periodEnd = addDays(periodEnd, BILLING_PERIOD_DAYS);
  }
  return periodEnd;
}

function hasPaidMonthlyCharge(local: LocalSubscriptionRecord): boolean {
  if (parseFlexibleDate(local.last_charged_at) != null) return true;
  const firstCharge = parseFlexibleDate(local.first_charge_at);
  return firstCharge != null && firstCharge.getTime() <= Date.now();
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
  first_charge_at?: string;
  last_charged_at?: admin.firestore.Timestamp | string;
  period_end_at?: admin.firestore.Timestamp | string;
  cancel_at_period_end?: boolean;
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

async function expirePremiumUnlessPrepaidCancel(userId: string): Promise<void> {
  const stored = await db.collection('subscriptions').doc(userId).get();
  const data = (stored.data() ?? {}) as LocalSubscriptionRecord;
  if (data.cancel_at_period_end === true) {
    const periodEnd = parseFlexibleDate(data.period_end_at);
    if (periodEnd && periodEnd.getTime() > Date.now()) {
      return;
    }
  }

  const profileDoc = await db.collection('profiles').doc(userId).get();
  if (profileDoc.data()?.subscription_status === 'premium') {
    await setUserSubscriptionStatus(userId, 'expired');
  }
}

async function expirePrepaidIfPeriodEnded(userId: string): Promise<void> {
  const stored = await db.collection('subscriptions').doc(userId).get();
  const data = (stored.data() ?? {}) as LocalSubscriptionRecord;
  if (data.cancel_at_period_end !== true) return;
  const periodEnd = parseFlexibleDate(data.period_end_at);
  if (!periodEnd || periodEnd.getTime() > Date.now()) return;
  await expirePremiumUnlessPrepaidCancel(userId);
}

async function applySubscriptionCancellation({
  userId,
  subscriptionId,
  remoteStatus,
  keepAccessUntil,
}: {
  userId: string;
  subscriptionId: string;
  remoteStatus: string;
  keepAccessUntil?: Date | null;
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

  const keepUntil =
    keepAccessUntil && keepAccessUntil.getTime() > Date.now()
      ? keepAccessUntil
      : null;

  await db.collection('subscriptions').doc(userId).set(
    {
      subscription_status: finalStatus,
      cancelled_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
      ...(keepUntil
        ? {
            cancel_at_period_end: true,
            period_end_at: admin.firestore.Timestamp.fromDate(keepUntil),
          }
        : {
            cancel_at_period_end: false,
          }),
    },
    {merge: true},
  );

  if (!keepUntil) {
    await expirePremiumUnlessPrepaidCancel(userId);
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
  await recordCancellationChargeTransaction(userId, orderId);
  await markPaymentCompleted({
    orderId,
    userId,
    amount: CANCELLATION_CHARGE_AMOUNT,
    purpose: 'cancellation_charge',
  });
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
 * - ₹299/month starting PREMIUM_TRIAL_DAYS after the ₹1 authorization
 *
 * Cancelling in this trial window (₹1 paid, ₹299 not yet charged) requires a
 * ₹299 PhonePe charge. After the monthly Autopay, cancel is free.
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
    await expirePrepaidIfPeriodEnded(userId);
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
 * Prepaid current period (₹299 already paid, still within 30 days): cancel
 * Autopay with no extra charge and keep Premium until period end.
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
    await expirePrepaidIfPeriodEnded(userId);
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
      await expirePrepaidIfPeriodEnded(userId);
      const storedPeriodEnd = parseFlexibleDate(local.period_end_at);
      const keepAccess =
        local.cancel_at_period_end === true &&
        storedPeriodEnd != null &&
        storedPeriodEnd.getTime() > Date.now();
      if (!keepAccess) {
        await applySubscriptionCancellation({
          userId,
          subscriptionId,
          remoteStatus,
        });
      }
      return {
        alreadyCancelled: true,
        chargeWaived: keepAccess,
        status: remoteStatus,
        isPremium: keepAccess,
        orderId: local.cancellation_order_id ?? '',
        paymentSessionId: '',
        environment: config.environment,
        amount: keepAccess ? 0 : CANCELLATION_CHARGE_AMOUNT,
        periodEndAt: keepAccess && storedPeriodEnd
          ? storedPeriodEnd.toISOString()
          : '',
      };
    }

    if (hasPaidMonthlyCharge(local)) {
      const prepaidUntil = currentPrepaidPeriodEnd(local);
      const keepUntil =
        prepaidUntil && prepaidUntil.getTime() > Date.now()
          ? prepaidUntil
          : null;
      const finalStatus = await applySubscriptionCancellation({
        userId,
        subscriptionId,
        remoteStatus,
        keepAccessUntil: keepUntil,
      });
      return {
        alreadyCancelled: true,
        chargeWaived: true,
        status: finalStatus,
        isPremium: keepUntil != null,
        orderId: '',
        paymentSessionId: '',
        environment: config.environment,
        amount: 0,
        periodEndAt: keepUntil ? keepUntil.toISOString() : '',
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
            chargeWaived: false,
            status: result.status,
            isPremium: false,
            orderId: existingOrderId,
            paymentSessionId: '',
            environment: config.environment,
            amount: CANCELLATION_CHARGE_AMOUNT,
            periodEndAt: '',
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
          await upsertPendingPayment({
            orderId: existingOrder.order_id,
            userId,
            amount: CANCELLATION_CHARGE_AMOUNT,
            purpose: 'cancellation_charge',
          });

          return {
            alreadyCancelled: false,
            chargeWaived: false,
            orderId: existingOrder.order_id,
            paymentSessionId: existingOrder.payment_session_id,
            environment: config.environment,
            amount: CANCELLATION_CHARGE_AMOUNT,
            periodEndAt: '',
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
    const created = await createCashfreePgOrder(
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
    await upsertPendingPayment({
      orderId: created.order_id,
      userId,
      amount: CANCELLATION_CHARGE_AMOUNT,
      purpose: 'cancellation_charge',
    });

    return {
      alreadyCancelled: false,
      chargeWaived: false,
      orderId: created.order_id,
      paymentSessionId: created.payment_session_id,
      environment: config.environment,
      amount: CANCELLATION_CHARGE_AMOUNT,
      periodEndAt: '',
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
    await expirePrepaidIfPeriodEnded(userId);
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
      await expirePrepaidIfPeriodEnded(userId);
      const storedPeriodEnd = parseFlexibleDate(local.period_end_at);
      const keepAccess =
        local.cancel_at_period_end === true &&
        storedPeriodEnd != null &&
        storedPeriodEnd.getTime() > Date.now();
      if (!keepAccess) {
        const finalStatus = await applySubscriptionCancellation({
          userId,
          subscriptionId,
          remoteStatus,
        });
        return {status: finalStatus, isPremium: false};
      }
      return {status: remoteStatus, isPremium: true, chargeWaived: true};
    }

    if (hasPaidMonthlyCharge(local)) {
      const prepaidUntil = currentPrepaidPeriodEnd(local);
      const keepUntil =
        prepaidUntil && prepaidUntil.getTime() > Date.now()
          ? prepaidUntil
          : null;
      const finalStatus = await applySubscriptionCancellation({
        userId,
        subscriptionId,
        remoteStatus,
        keepAccessUntil: keepUntil,
      });
      return {
        status: finalStatus,
        isPremium: keepUntil != null,
        chargeWaived: true,
      };
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
      const pgPayload = payload as unknown as CashfreePgWebhookPayload;
      await handleCancellationChargePayment(pgPayload);
      await handleAgencyPaymentWebhook(pgPayload);
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
          ...(payload.type === 'SUBSCRIPTION_CHARGED'
            ? {
                last_charged_at: admin.firestore.FieldValue.serverTimestamp(),
                period_end_at: admin.firestore.Timestamp.fromDate(
                  addDays(new Date(), BILLING_PERIOD_DAYS),
                ),
              }
            : {}),
        },
        {merge: true},
      );

      if (isPremiumActivationWebhook(payload)) {
        await setUserSubscriptionStatus(userId, 'premium');
      } else if (isPremiumDeactivationWebhook(payload)) {
        await expirePremiumUnlessPrepaidCancel(userId);
      } else {
        await expirePrepaidIfPeriodEnded(userId);
      }

      if (subscriptionId) {
        if (isAuthorizationSuccessWebhook(payload)) {
          await recordPremiumTrialTransaction(userId, subscriptionId);
        }
        if (payload.type === 'SUBSCRIPTION_CHARGED') {
          await recordPremiumMonthlyTransaction(userId, subscriptionId);
        }
      }
    }

    res.status(200).send('OK');
}

/**
 * Drops Premium after a prepaid cancel once the paid 30-day period ends.
 */
export const expireEndedPremiumSubscriptions = functions
  .region(FUNCTION_REGION)
  .pubsub.schedule('every 6 hours')
  .timeZone('Asia/Kolkata')
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();
    const snap = await db
      .collection('subscriptions')
      .where('cancel_at_period_end', '==', true)
      .where('period_end_at', '<=', now)
      .limit(200)
      .get();

    await Promise.all(
      snap.docs.map((doc) => expirePrepaidIfPeriodEnded(doc.id)),
    );
    return null;
  });

async function requireAdmin(uid: string | undefined): Promise<void> {
  if (!uid) {
    throw new functions.https.HttpsError('unauthenticated', 'Sign in first.');
  }
  const caller = await db.collection('users').doc(uid).get();
  if (caller.data()?.role !== 'admin') {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only admins can send notifications.',
    );
  }
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
    const body = text.length > 100 ? `${text.substring(0, 100)}...` : text;

    await db.collection('notifications').add({
      userId: recipientId,
      type: 'new_message',
      title: senderName,
      body,
      conversationId,
      senderId,
      read: false,
      pushed: true,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    await sendPushToUser({
      userId: recipientId,
      title: senderName,
      body,
      channelId: 'messages',
      data: {
        type: 'new_message',
        conversationId,
        senderId,
        senderName,
        body,
      },
    });

    return null;
  });

/**
 * Pushes FCM when admin (or another server write) creates an inbox notification.
 * Chat messages already send their own push, so those docs are skipped.
 */
export const onNotificationCreated = functions
  .region(FUNCTION_REGION)
  .firestore.document('notifications/{notificationId}')
  .onCreate(async (snapshot) => {
    const data = snapshot.data();
    if (!data) return null;
    if (data.pushed === true || data.type === 'new_message') return null;

    const userId = String(data.userId || '');
    const title = String(data.title || 'Notification');
    const body = String(data.body || data.message || '');
    if (!userId || !title) return null;

    await sendPushToUser({
      userId,
      title,
      body: body || title,
      channelId: 'alerts',
      data: {
        type: String(data.type || 'admin'),
        title,
        body: body || title,
        conversationId: String(data.conversationId || ''),
        jobId: String(data.jobId || data.job_id || ''),
        notificationId: snapshot.id,
      },
    });

    await snapshot.ref.set({pushed: true}, {merge: true});
    return null;
  });

/**
 * Admin panel callable: write inbox docs for artists / agencies / a single user.
 * Device push is sent by onNotificationCreated.
 */
export const sendAdminNotification = functions
  .region(FUNCTION_REGION)
  .https.onCall(async (data, context) => {
    await requireAdmin(context.auth?.uid);

    const title = String(data?.title || '').trim();
    const body = String(data?.body || '').trim();
    const type = String(data?.type || 'admin').trim() || 'admin';
    const audience = String(data?.audience || 'influencers').trim();
    const jobId = String(data?.jobId || '').trim();
    const userId = String(data?.userId || '').trim();

    if (!title || title.length > 200) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Enter a title up to 200 characters.',
      );
    }
    if (!body || body.length > 2000) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Enter a message up to 2000 characters.',
      );
    }

    let recipientIds: string[] = [];
    if (audience === 'user') {
      if (!userId) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Choose a user to notify.',
        );
      }
      recipientIds = [userId];
    } else {
      const usersSnap = await db.collection('users').get();
      recipientIds = usersSnap.docs
        .filter((doc) => {
          const role = String(doc.data()?.role || '');
          if (role === 'admin') return false;
          if (audience === 'agencies') return role === 'agency';
          if (audience === 'all') return role === 'influencer' || role === 'agency';
          return role === 'influencer';
        })
        .map((doc) => doc.id);
    }

    if (recipientIds.length === 0) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'No matching users to notify.',
      );
    }

    const createdAt = admin.firestore.FieldValue.serverTimestamp();
    let written = 0;
    const chunkSize = 400;
    for (let i = 0; i < recipientIds.length; i += chunkSize) {
      const batch = db.batch();
      for (const recipientId of recipientIds.slice(i, i + chunkSize)) {
        const ref = db.collection('notifications').doc();
        batch.set(ref, {
          userId: recipientId,
          type,
          title,
          body,
          jobId,
          read: false,
          created_at: createdAt,
        });
        written += 1;
      }
      await batch.commit();
    }

    return {sent: written};
  });

/** Agency portal Cashfree callables — run in Mumbai alongside other payment functions. */
const AGENCY_PG_REGION = FUNCTION_REGION;

async function loadAgencyPayerDetails(userId: string): Promise<{
  name: string;
  email: string;
  phone: string;
}> {
  const userDoc = await db.collection('users').doc(userId).get();
  const user = userDoc.data() ?? {};
  const name =
    (user.agencyName as string | undefined)?.trim() ||
    (user.companyName as string | undefined)?.trim() ||
    (user.name as string | undefined)?.trim() ||
    'Agency';
  const email = (user.email as string | undefined)?.trim() || '';
  const phone =
    normalizeIndianPhone((user.contactNumber as string | undefined) ?? '') ||
    normalizeIndianPhone((user.mobile as string | undefined) ?? '') ||
    '9999999999';
  if (!email) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Add an email to your agency account before paying.',
    );
  }
  return {name, email, phone};
}

function agencyOrderId(purpose: AgencyPaymentPurpose, userId: string): string {
  const prefix = purpose === 'agency_premium' ? 'agp' : 'wlt';
  return `${prefix}_${userId}_${Date.now()}`;
}

type BillingTransactionType =
  | 'premium_trial'
  | 'premium_monthly'
  | 'cancellation_charge'
  | 'agency_premium'
  | 'wallet_topup';

async function recordBillingTransaction(opts: {
  docId: string;
  userId: string;
  amount: number;
  type: BillingTransactionType;
  status?: 'completed' | 'pending' | 'failed';
  cashfreeOrderId?: string | null;
  cashfreeSubscriptionId?: string | null;
  cashfreePaymentId?: string | null;
  paidAt?: admin.firestore.Timestamp | admin.firestore.FieldValue;
}): Promise<void> {
  const ref = db.collection('transactions').doc(opts.docId);
  const existing = await ref.get();
  if (existing.exists && existing.data()?.status === 'completed') {
    return;
  }

  await ref.set(
    {
      userId: opts.userId,
      amount: opts.amount,
      currency: 'INR',
      status: opts.status ?? 'completed',
      type: opts.type,
      purpose: opts.type,
      gateway: 'cashfree',
      cashfreeOrderId: opts.cashfreeOrderId ?? null,
      cashfreeSubscriptionId: opts.cashfreeSubscriptionId ?? null,
      cashfreePaymentId: opts.cashfreePaymentId ?? null,
      paidAt: opts.paidAt ?? admin.firestore.FieldValue.serverTimestamp(),
      createdAt:
        existing.data()?.createdAt ??
        admin.firestore.FieldValue.serverTimestamp(),
    },
    {merge: true},
  );
}

async function recordPremiumTrialTransaction(
  userId: string,
  subscriptionId: string,
  paidAt?: admin.firestore.Timestamp | admin.firestore.FieldValue,
): Promise<void> {
  await recordBillingTransaction({
    docId: `pt_${subscriptionId}`,
    userId,
    amount: 1,
    type: 'premium_trial',
    cashfreeSubscriptionId: subscriptionId,
    paidAt,
  });
}

async function recordPremiumMonthlyTransaction(
  userId: string,
  subscriptionId: string,
  paidAt?: admin.firestore.Timestamp | admin.firestore.FieldValue,
): Promise<void> {
  const paidAtDate =
    paidAt instanceof admin.firestore.Timestamp
      ? paidAt.toDate()
      : new Date();
  const chargeKey = paidAtDate.getTime();
  await recordBillingTransaction({
    docId: `pm_${subscriptionId}_${chargeKey}`,
    userId,
    amount: 299,
    type: 'premium_monthly',
    cashfreeSubscriptionId: subscriptionId,
    paidAt,
  });
}

async function recordCancellationChargeTransaction(
  userId: string,
  orderId: string,
  paidAt?: admin.firestore.Timestamp | admin.firestore.FieldValue,
): Promise<void> {
  await recordBillingTransaction({
    docId: `cxl_${orderId}`,
    userId,
    amount: CANCELLATION_CHARGE_AMOUNT,
    type: 'cancellation_charge',
    cashfreeOrderId: orderId,
    paidAt,
  });
}

async function upsertPendingPayment(opts: {
  orderId: string;
  userId: string;
  amount: number;
  purpose: BillingTransactionType;
}): Promise<void> {
  await db.collection('payments').doc(opts.orderId).set(
    {
      userId: opts.userId,
      orderId: opts.orderId,
      amount: opts.amount,
      purpose: opts.purpose,
      status: 'pending',
      gateway: 'cashfree',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    {merge: true},
  );
}

async function markPaymentCompleted(opts: {
  orderId: string;
  userId: string;
  amount: number;
  purpose: BillingTransactionType;
  paymentId?: string;
}): Promise<void> {
  await db.collection('payments').doc(opts.orderId).set(
    {
      userId: opts.userId,
      orderId: opts.orderId,
      amount: opts.amount,
      purpose: opts.purpose,
      status: 'completed',
      gateway: 'cashfree',
      cashfreePaymentId: opts.paymentId ?? null,
      paidAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    {merge: true},
  );
}

async function syncBillingHistoryFromSubscription(userId: string): Promise<number> {
  const snap = await db.collection('subscriptions').doc(userId).get();
  if (!snap.exists) return 0;

  const data = snap.data() ?? {};
  const subscriptionId = (data.subscription_id as string | undefined) ?? '';
  if (!subscriptionId) return 0;

  let created = 0;

  const authorizedAt = data.authorized_at as admin.firestore.Timestamp | undefined;
  if (authorizedAt) {
    await recordPremiumTrialTransaction(userId, subscriptionId, authorizedAt);
    created++;
  }

  const lastChargedAt = parseFlexibleDate(data.last_charged_at);
  if (lastChargedAt) {
    await recordPremiumMonthlyTransaction(
      userId,
      subscriptionId,
      admin.firestore.Timestamp.fromDate(lastChargedAt),
    );
    created++;
  } else {
    const firstChargeAt = parseFlexibleDate(data.first_charge_at);
    if (firstChargeAt && firstChargeAt.getTime() <= Date.now()) {
      await recordPremiumMonthlyTransaction(
        userId,
        subscriptionId,
        admin.firestore.Timestamp.fromDate(firstChargeAt),
      );
      created++;
    }
  }

  const cancellationStatus = (
    data.cancellation_order_status as string | undefined
  )?.toUpperCase();
  const cancellationOrderId = data.cancellation_order_id as string | undefined;
  if (cancellationStatus === 'PAID' && cancellationOrderId) {
    const paidAt = parseFlexibleDate(data.cancellation_paid_at);
    await recordCancellationChargeTransaction(
      userId,
      cancellationOrderId,
      paidAt
        ? admin.firestore.Timestamp.fromDate(paidAt)
        : admin.firestore.FieldValue.serverTimestamp(),
    );
    await markPaymentCompleted({
      orderId: cancellationOrderId,
      userId,
      amount: CANCELLATION_CHARGE_AMOUNT,
      purpose: 'cancellation_charge',
    });
    created++;
  }

  return created;
}

export const syncBillingHistory = functions.region(FUNCTION_REGION).https.onCall(
  async (_data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Sign in to sync billing history.',
      );
    }

    const synced = await syncBillingHistoryFromSubscription(context.auth.uid);
    return {synced};
  },
);

async function fulfillAgencyPayment(opts: {
  userId: string;
  orderId: string;
  amount: number;
  purpose: AgencyPaymentPurpose;
  paymentId?: string;
}): Promise<void> {
  const paymentRef = db.collection('payments').doc(opts.orderId);
  const userRef = db.collection('users').doc(opts.userId);

  await db.runTransaction(async (tx) => {
    const paymentSnap = await tx.get(paymentRef);
    if (paymentSnap.data()?.status === 'completed') {
      return;
    }

    const userSnap = await tx.get(userRef);
    const user = userSnap.data() ?? {};
    const updates: Record<string, unknown> = {
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    let expiresAt: string | null = null;

    if (opts.purpose === 'wallet_topup') {
      updates.wallet_balance = admin.firestore.FieldValue.increment(opts.amount);
    } else {
      const currentExpiry = parseFlexibleDate(user.subscription_expires_at);
      const from =
        currentExpiry && currentExpiry.getTime() > Date.now()
          ? currentExpiry
          : new Date();
      const next = new Date(from.getTime());
      next.setFullYear(next.getFullYear() + 1);
      expiresAt = next.toISOString();
      updates.subscription_status = 'premium';
      updates.subscription_expires_at = expiresAt;
    }

    tx.set(userRef, updates, {merge: true});
    tx.set(
      paymentRef,
      {
        userId: opts.userId,
        orderId: opts.orderId,
        amount: opts.amount,
        purpose: opts.purpose,
        status: 'completed',
        gateway: 'cashfree',
        cashfreePaymentId: opts.paymentId ?? null,
        paidAt: admin.firestore.FieldValue.serverTimestamp(),
        createdAt:
          paymentSnap.data()?.createdAt ??
          admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: true},
    );
    tx.set(db.collection('transactions').doc(), {
      userId: opts.userId,
      amount: opts.amount,
      currency: 'INR',
      status: 'completed',
      type: opts.purpose,
      purpose: opts.purpose,
      cashfreeOrderId: opts.orderId,
      cashfreePaymentId: opts.paymentId ?? null,
      gateway: 'cashfree',
      paidAt: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt,
    });
  });
}

async function handleAgencyPaymentWebhook(
  payload: CashfreePgWebhookPayload,
): Promise<void> {
  const paymentStatus = payload.data?.payment?.payment_status ?? '';
  if (paymentStatus && paymentStatus.toUpperCase() !== 'SUCCESS') {
    return;
  }

  const orderId = payload.data?.order?.order_id;
  if (!orderId) return;

  const tags = payload.data?.order?.order_tags ?? {};
  const purpose = tags.purpose;
  if (!isAgencyPaymentPurpose(purpose)) return;

  const userId =
    (typeof tags.user_id === 'string' && tags.user_id) ||
    extractUserIdFromPgWebhook(payload);
  if (!userId) {
    functions.logger.warn('agency payment webhook: user not found', {orderId});
    return;
  }

  const amount = Number(
    payload.data?.order?.order_amount ??
      payload.data?.payment?.payment_amount ??
      0,
  );

  try {
    await fulfillAgencyPayment({
      userId,
      orderId,
      amount: purpose === 'agency_premium' ? AGENCY_PREMIUM_AMOUNT : amount,
      purpose,
    });
  } catch (error) {
    functions.logger.error('agency payment webhook: fulfill failed', {
      userId,
      orderId,
      error,
    });
  }
}

export const createCashfreeOrder = functions
  .region(AGENCY_PG_REGION)
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Sign in to continue payment.',
      );
    }

    const userId = String((data as {userId?: string})?.userId ?? '');
    const purpose = String((data as {purpose?: string})?.purpose ?? '');
    const returnUrl = String((data as {returnUrl?: string})?.returnUrl ?? '');
    const amountRaw = Number((data as {amount?: number})?.amount ?? 0);

    if (userId !== context.auth.uid) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'You can only pay for your own agency account.',
      );
    }
    if (!isAgencyPaymentPurpose(purpose)) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Unsupported payment purpose.',
      );
    }
    if (!returnUrl.startsWith('http')) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'A valid return URL is required.',
      );
    }

    const amount =
      purpose === 'agency_premium' ? AGENCY_PREMIUM_AMOUNT : amountRaw;
    if (!Number.isFinite(amount) || amount < 1) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Enter a valid amount.',
      );
    }

    const config = getCashfreeConfig();
    const customer = await loadAgencyPayerDetails(userId);
    const orderId = agencyOrderId(purpose, userId);
    const created = await createCashfreePgOrder(
      config,
      buildAgencyPaymentOrderPayload({
        orderId,
        amount,
        purpose,
        customerId: userId,
        customerName: customer.name,
        customerEmail: customer.email,
        customerPhone: customer.phone,
        returnUrl,
        notifyUrl: pgWebhookNotifyUrl(),
      }),
    );

    if (!created.payment_session_id) {
      throw new functions.https.HttpsError(
        'unavailable',
        'Could not start Cashfree checkout. Try again.',
      );
    }

    await db.collection('payments').doc(created.order_id).set({
      userId,
      orderId: created.order_id,
      amount,
      purpose,
      status: 'pending',
      gateway: 'cashfree',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      paymentSessionId: created.payment_session_id,
      orderId: created.order_id,
      environment: config.environment,
    };
  });

export const verifyCashfreePayment = functions
  .region(AGENCY_PG_REGION)
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Sign in to confirm payment.',
      );
    }

    const orderId = String((data as {orderId?: string})?.orderId ?? '');
    const requestedUserId = String((data as {userId?: string})?.userId ?? '');
    if (!orderId) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Missing order id.',
      );
    }

    const userId = context.auth.uid;
    if (requestedUserId && requestedUserId !== userId) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'You can only confirm your own payments.',
      );
    }

    const paymentSnap = await db.collection('payments').doc(orderId).get();
    const stored = paymentSnap.data();
    if (stored?.userId && stored.userId !== userId) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'You can only confirm your own payments.',
      );
    }

    const config = getCashfreeConfig();
    const order = await fetchCashfreeOrder(config, orderId);
    if (!isPaidOrderStatus(order.order_status)) {
      return {success: false, status: order.order_status};
    }

    const purposeRaw = stored?.purpose ?? order.order_tags?.purpose;
    if (!isAgencyPaymentPurpose(purposeRaw)) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'This order is not an agency payment.',
      );
    }

    await fulfillAgencyPayment({
      userId,
      orderId,
      amount:
        purposeRaw === 'agency_premium'
          ? AGENCY_PREMIUM_AMOUNT
          : Number(stored?.amount ?? order.order_amount ?? 0),
      purpose: purposeRaw,
    });

    return {success: true, status: order.order_status, purpose: purposeRaw};
  });

