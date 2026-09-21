import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';

/** Fixed commission per referred user conversion (₹30 for now). */
export const AFFILIATE_COMMISSION_INR = 30;

interface KamaoWebhookConfig {
  webhookUrl: string;
  webhookSecret: string;
}

function getKamaoWebhookConfig(): KamaoWebhookConfig | null {
  const webhookUrl = (process.env.KAMAO_WEBHOOK_URL ?? '').trim();
  const webhookSecret = (process.env.KAMAO_WEBHOOK_SECRET ?? '').trim();

  if (!webhookUrl || !webhookSecret) {
    return null;
  }

  return {webhookUrl, webhookSecret};
}

/**
 * After a referred BCC user completes UPI mandate authorization (payment debited),
 * notify the Kamao affiliate project to credit the referrer once.
 */
export async function notifyKamaoAffiliateConversion(opts: {
  db: admin.firestore.Firestore;
  bccUserId: string;
  subscriptionId: string;
  idempotencyKey: string;
}): Promise<void> {
  const conversionRef = opts.db.collection('affiliate_conversions').doc(opts.bccUserId);
  const existing = await conversionRef.get();
  if (existing.exists) {
    functions.logger.info('Kamao affiliate conversion already reported', {
      bccUserId: opts.bccUserId,
    });
    return;
  }

  const userDoc = await opts.db.collection('users').doc(opts.bccUserId).get();
  const referralCode = (userDoc.data()?.referred_by_code ?? '').toString().trim();
  if (!referralCode) {
    return;
  }

  const webhookConfig = getKamaoWebhookConfig();
  if (!webhookConfig) {
    functions.logger.warn(
      'Kamao affiliate webhook not configured; skipping conversion notify',
      {bccUserId: opts.bccUserId, referralCode},
    );
    return;
  }

  const payload = {
    referralCode,
    bccUserId: opts.bccUserId,
    idempotencyKey: opts.idempotencyKey,
    amountInr: AFFILIATE_COMMISSION_INR,
    eventType: 'mandate_payment',
    subscriptionId: opts.subscriptionId,
  };

  try {
    const response = await fetch(webhookConfig.webhookUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Kamao-Secret': webhookConfig.webhookSecret,
      },
      body: JSON.stringify(payload),
    });

    const responseText = await response.text();
    if (!response.ok) {
      functions.logger.error('Kamao affiliate webhook failed', {
        status: response.status,
        body: responseText,
        bccUserId: opts.bccUserId,
        referralCode,
      });
      return;
    }

    await conversionRef.set({
      referral_code: referralCode,
      subscription_id: opts.subscriptionId,
      idempotency_key: opts.idempotencyKey,
      amount_inr: AFFILIATE_COMMISSION_INR,
      reported_at: admin.firestore.FieldValue.serverTimestamp(),
      kamao_response: responseText.slice(0, 500),
    });

    functions.logger.info('Kamao affiliate conversion reported', {
      bccUserId: opts.bccUserId,
      referralCode,
      amountInr: AFFILIATE_COMMISSION_INR,
    });
  } catch (error) {
    functions.logger.error('Kamao affiliate webhook request error', {
      bccUserId: opts.bccUserId,
      referralCode,
      error,
    });
  }
}
