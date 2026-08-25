import * as crypto from 'crypto';

export type CashfreeEnvironment = 'sandbox' | 'production';

export interface CashfreeConfig {
  clientId: string;
  clientSecret: string;
  environment: CashfreeEnvironment;
  webhookSecret: string;
}

const API_VERSION = '2025-01-01';

export const CANCELLATION_CHARGE_AMOUNT = 299;

function isPlaceholderEnvValue(value: string): boolean {
  const trimmed = value.trim();
  if (!trimmed) return true;
  if (trimmed.startsWith('<') || trimmed.startsWith('your_')) return true;
  if (trimmed.toLowerCase().includes('dashboard')) return true;
  return false;
}

export function getCashfreeConfig(): CashfreeConfig {
  return {
    clientId: process.env.CASHFREE_CLIENT_ID ?? '',
    clientSecret: process.env.CASHFREE_CLIENT_SECRET ?? '',
    environment:
      process.env.CASHFREE_ENV === 'production' ? 'production' : 'sandbox',
    webhookSecret: process.env.CASHFREE_WEBHOOK_SECRET ?? '',
  };
}

/**
 * Returns the secret used to verify Cashfree Subscription webhook signatures.
 *
 * Per Cashfree Subscriptions documentation, webhook payloads are signed with
 * HMAC-SHA256 using the merchant's CLIENT SECRET as the key. There is no
 * separate "webhook secret" concept for the Subscriptions product.
 *
 * CASHFREE_WEBHOOK_SECRET is an optional override kept for forward compatibility
 * (e.g., if Cashfree ever introduces per-endpoint secrets). When absent or
 * placeholder, the function correctly falls back to clientSecret, which is the
 * documented signing key.
 */
export function getWebhookVerificationSecret(config: CashfreeConfig): string {
  const explicit = config.webhookSecret.trim();
  if (!isPlaceholderEnvValue(explicit)) {
    return explicit;
  }
  // Correct per Cashfree Subscription docs: use clientSecret for HMAC-SHA256 verification.
  return config.clientSecret;
}

function baseUrl(environment: CashfreeEnvironment): string {
  return environment === 'production'
    ? 'https://api.cashfree.com/pg'
    : 'https://sandbox.cashfree.com/pg';
}

export function assertCashfreeConfigured(config: CashfreeConfig): void {
  if (!config.clientId || !config.clientSecret) {
    throw new Error(
      'Cashfree is not configured. Set CASHFREE_CLIENT_ID and CASHFREE_CLIENT_SECRET.',
    );
  }
}

export async function cancelCashfreeSubscription(
  config: CashfreeConfig,
  subscriptionId: string,
): Promise<CashfreeSubscriptionResponse> {
  return cashfreeRequest<CashfreeSubscriptionResponse>({
    config,
    method: 'POST',
    path: `/subscriptions/${encodeURIComponent(subscriptionId)}/manage`,
    body: {
      subscription_id: subscriptionId,
      action: 'CANCEL',
    },
  });
}

export async function cashfreeRequest<T>({
  config,
  method,
  path,
  body,
}: {
  config: CashfreeConfig;
  method: 'GET' | 'POST';
  path: string;
  body?: unknown;
}): Promise<T> {
  assertCashfreeConfigured(config);

  const response = await fetch(`${baseUrl(config.environment)}${path}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      'x-api-version': API_VERSION,
      'x-client-id': config.clientId,
      'x-client-secret': config.clientSecret,
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });

  const text = await response.text();
  let payload: unknown = {};
  if (text) {
    try {
      payload = JSON.parse(text);
    } catch {
      payload = {message: text};
    }
  }

  if (!response.ok) {
    const message =
      typeof payload === 'object' &&
      payload !== null &&
      'message' in payload &&
      typeof (payload as {message?: unknown}).message === 'string'
        ? (payload as {message: string}).message
        : `Cashfree API error (${response.status})`;
    throw new Error(message);
  }

  return payload as T;
}

export interface CreatePremiumSubscriptionInput {
  subscriptionId: string;
  customerName: string;
  customerEmail: string;
  customerPhone: string;
  userId: string;
  firstChargeTimeIso: string;
}

export interface CashfreeSubscriptionResponse {
  subscription_id: string;
  subscription_session_id: string;
  subscription_status: string;
  cf_subscription_id?: string;
}

export function buildPremiumSubscriptionPayload(
  input: CreatePremiumSubscriptionInput,
) {
  return {
    subscription_id: input.subscriptionId,
    customer_details: {
      customer_name: input.customerName,
      customer_email: input.customerEmail,
      customer_phone: input.customerPhone,
    },
    plan_details: {
      plan_name: 'Premium Monthly',
      plan_type: 'PERIODIC',
      plan_amount: 299,
      plan_max_amount: 299,
      plan_max_cycles: 120,
      plan_intervals: 1,
      plan_currency: 'INR',
      plan_interval_type: 'MONTH',
      plan_note: 'Bombay Casting Premium — ₹299/month after 3-day trial',
    },
    authorization_details: {
      authorization_amount: 1,
      authorization_amount_refund: false,
      payment_methods: ['upi'],
    },
    subscription_meta: {
      return_url: 'https://bombaycastingcompany.app/subscription-return',
      notification_channel: ['EMAIL', 'SMS'],
    },
    subscription_expiry_time: '2100-01-01T23:59:59+05:30',
    subscription_first_charge_time: input.firstChargeTimeIso,
    subscription_tags: {
      user_id: input.userId,
      psp_note: 'Bombay Casting Premium',
    },
  };
}

export function normalizeIndianPhone(raw: string): string {
  const digits = raw.replace(/\D/g, '');
  if (digits.length >= 10) {
    return digits.slice(-10);
  }
  return '';
}

export function verifyWebhookSignature({
  rawBody,
  signature,
  timestamp,
  secret,
}: {
  rawBody: string;
  signature: string;
  timestamp: string;
  secret: string;
}): boolean {
  if (!secret || !signature || !timestamp) return false;

  const signedPayload = `${timestamp}${rawBody}`;
  const expected = crypto
    .createHmac('sha256', secret)
    .update(signedPayload)
    .digest('base64');

  if (expected.length !== signature.length) {
    return false;
  }

  try {
    return crypto.timingSafeEqual(
      Buffer.from(expected),
      Buffer.from(signature),
    );
  } catch {
    return false;
  }
}

export function readWebhookRawBody(req: {
  rawBody?: Buffer;
  body?: unknown;
}): string {
  if (req.rawBody && req.rawBody.length > 0) {
    return req.rawBody.toString('utf8');
  }
  if (typeof req.body === 'string') {
    return req.body;
  }
  if (req.body && typeof req.body === 'object') {
    return JSON.stringify(req.body);
  }
  return '';
}

export interface CashfreeWebhookPayload {
  type?: string;
  data?: {
    subscription_details?: {
      subscription_id?: string;
      subscription_status?: string;
    };
    authorization_details?: {
      authorization_status?: string;
    };
    authorisation_details?: {
      authorization_status?: string;
    };
    subscription_tags?: Record<string, string>;
  };
}

export function extractUserIdFromWebhook(
  payload: CashfreeWebhookPayload,
): string | null {
  const tags = payload.data?.subscription_tags;
  if (tags && typeof tags.user_id === 'string' && tags.user_id.length > 0) {
    return tags.user_id;
  }
  return null;
}

/** Statuses where a new Cashfree subscription may be created safely. */
export const TERMINAL_SUBSCRIPTION_STATUSES = [
  'CUSTOMER_CANCELLED',
  'CANCELLED',
  'EXPIRED',
  'LINK_EXPIRED',
  'COMPLETED',
] as const;

export function isTerminalSubscriptionStatus(
  status: string | undefined | null,
): boolean {
  if (!status) return false;
  return TERMINAL_SUBSCRIPTION_STATUSES.includes(
    status.toUpperCase() as (typeof TERMINAL_SUBSCRIPTION_STATUSES)[number],
  );
}

/** In-flight mandate/checkout — reuse instead of creating a duplicate subscription. */
export function isPendingSubscriptionStatus(
  status: string | undefined | null,
): boolean {
  if (!status) return false;
  const normalized = status.toUpperCase();
  if (normalized === 'ACTIVE') return false;
  return !isTerminalSubscriptionStatus(normalized);
}

export function subscriptionStatusFromWebhook(
  payload: CashfreeWebhookPayload,
): string {
  return payload.data?.subscription_details?.subscription_status ?? '';
}

/** Premium is granted only when Cashfree reports the subscription as ACTIVE. */
export function isPremiumSubscriptionActive(
  payload: CashfreeWebhookPayload,
): boolean {
  return subscriptionStatusFromWebhook(payload) === 'ACTIVE';
}

export function isPremiumActivationWebhook(
  payload: CashfreeWebhookPayload,
): boolean {
  const type = payload.type ?? '';

  if (
    type === 'SUBSCRIPTION_STATUS_CHANGED' ||
    type === 'SUBSCRIPTION_NEW' ||
    type === 'SUBSCRIPTION_AUTH_STATUS'
  ) {
    // Align with verifyPremiumSubscription: auth SUCCESS alone is not enough.
    return isPremiumSubscriptionActive(payload);
  }

  // Recurring monthly charge succeeded — keeps/restores premium after lapse.
  if (type === 'SUBSCRIPTION_CHARGED') {
    const subscriptionStatus = subscriptionStatusFromWebhook(payload);
    return subscriptionStatus === '' || subscriptionStatus === 'ACTIVE';
  }

  return false;
}

export function isPremiumDeactivationWebhook(
  payload: CashfreeWebhookPayload,
): boolean {
  const type = payload.type ?? '';
  const subscriptionStatus =
    payload.data?.subscription_details?.subscription_status ?? '';

  if (type === 'SUBSCRIPTION_STATUS_CHANGED') {
    return [
      'CUSTOMER_CANCELLED',
      'CANCELLED',
      'EXPIRED',
      'LINK_EXPIRED',
      'COMPLETED',
    ].includes(subscriptionStatus);
  }
  // Treat persistent payment failure as deactivation (Cashfree fires this
  // after all retry attempts are exhausted).
  if (type === 'SUBSCRIPTION_PAYMENT_FAILED') {
    return true;
  }
  return false;
}

export interface CreateCancellationOrderInput {
  orderId: string;
  customerId: string;
  customerName: string;
  customerEmail: string;
  customerPhone: string;
  notifyUrl?: string;
}

export interface CashfreeOrderResponse {
  cf_order_id?: number | string;
  order_id: string;
  order_amount: number;
  order_currency?: string;
  order_status: string;
  payment_session_id?: string;
}

export function buildCancellationOrderPayload(
  input: CreateCancellationOrderInput,
) {
  return {
    order_id: input.orderId,
    order_amount: CANCELLATION_CHARGE_AMOUNT,
    order_currency: 'INR',
    customer_details: {
      customer_id: input.customerId,
      customer_name: input.customerName,
      customer_email: input.customerEmail,
      customer_phone: input.customerPhone,
    },
    order_meta: {
      return_url:
        'https://bombaycastingcompany.app/subscription-return?order_id={order_id}',
      ...(input.notifyUrl ? {notify_url: input.notifyUrl} : {}),
    },
    order_note: 'Premium cancellation — one month ₹299',
    order_tags: {
      user_id: input.customerId,
      purpose: 'cancellation_charge',
    },
  };
}

export async function createCashfreeOrder(
  config: CashfreeConfig,
  payload: ReturnType<typeof buildCancellationOrderPayload>,
): Promise<CashfreeOrderResponse> {
  return cashfreeRequest<CashfreeOrderResponse>({
    config,
    method: 'POST',
    path: '/orders',
    body: payload,
  });
}

export async function fetchCashfreeOrder(
  config: CashfreeConfig,
  orderId: string,
): Promise<CashfreeOrderResponse> {
  return cashfreeRequest<CashfreeOrderResponse>({
    config,
    method: 'GET',
    path: `/orders/${encodeURIComponent(orderId)}`,
  });
}

export function isPaidOrderStatus(status: string | undefined | null): boolean {
  return (status ?? '').toUpperCase() === 'PAID';
}

export function isReusableOrderStatus(
  status: string | undefined | null,
): boolean {
  const normalized = (status ?? '').toUpperCase();
  return normalized === 'ACTIVE' || normalized === 'PENDING';
}

export function isCancellationOrderIdForUser(
  orderId: string,
  userId: string,
): boolean {
  return orderId.startsWith(`cxl_${userId}_`);
}

export interface CashfreePgWebhookPayload {
  type?: string;
  data?: {
    order?: {
      order_id?: string;
      order_amount?: number;
      order_status?: string;
      order_tags?: Record<string, string> | null;
    };
    payment?: {
      payment_status?: string;
      payment_amount?: number;
    };
    customer_details?: {
      customer_id?: string;
    };
  };
}

export function isPaymentWebhookType(type: string | undefined | null): boolean {
  return (type ?? '').startsWith('PAYMENT_');
}

export function isCancellationChargeSuccessWebhook(
  payload: CashfreePgWebhookPayload,
): boolean {
  if (payload.type !== 'PAYMENT_SUCCESS_WEBHOOK') {
    return false;
  }

  const paymentStatus = payload.data?.payment?.payment_status ?? '';
  if (paymentStatus && paymentStatus.toUpperCase() !== 'SUCCESS') {
    return false;
  }

  const tags = payload.data?.order?.order_tags;
  if (tags && tags.purpose === 'cancellation_charge') {
    return true;
  }

  const orderId = payload.data?.order?.order_id ?? '';
  return orderId.startsWith('cxl_');
}

export function extractUserIdFromPgWebhook(
  payload: CashfreePgWebhookPayload,
): string | null {
  const tags = payload.data?.order?.order_tags;
  if (tags && typeof tags.user_id === 'string' && tags.user_id.length > 0) {
    return tags.user_id;
  }

  const customerId = payload.data?.customer_details?.customer_id;
  if (typeof customerId === 'string' && customerId.length > 0) {
    return customerId;
  }

  return null;
}
