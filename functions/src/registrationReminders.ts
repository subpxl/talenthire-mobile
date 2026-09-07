import type {CloudTasksClient} from '@google-cloud/tasks';
import type {OAuth2Client} from 'google-auth-library';
import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions/v1';
import {sendPushToUser} from './push';

/**
 * Delayed registration reminders via one HTTP Cloud Tasks queue.
 *
 * Config (env, with production defaults):
 *   GCLOUD_PROJECT / GCP_PROJECT / TASKS_PROJECT_ID  → project ID
 *   TASKS_FUNCTION_REGION / TASKS_LOCATION                → asia-south1
 *   TASKS_QUEUE                                      → registration-reminders
 *   TASKS_INVOKER_SA                                 → {project}@appspot.gserviceaccount.com
 *   FUNCTION_URL_BASE                                → https://{region}-{project}.cloudfunctions.net
 *   REGISTRATION_REMINDER_10MIN_SECONDS              → 600
 *   REGISTRATION_REMINDER_24H_SECONDS                → 86400
 */

export const REMINDER_FUNCTION_REGION = 'asia-south1';
export const REMINDER_QUEUE_NAME = 'registration-reminders';

const REMINDER_10MIN = 'registration_reminder_10min';
const REMINDER_24H = 'registration_reminder_24h';

type ReminderType = typeof REMINDER_10MIN | typeof REMINDER_24H;

const REMINDER_SENT_FIELD: Record<ReminderType, string> = {
  [REMINDER_10MIN]: 'reminder_10min_sent_at',
  [REMINDER_24H]: 'reminder_24h_sent_at',
};

const REMINDER_COPY: Record<
  ReminderType,
  {title: string; body: string; functionName: string}
> = {
  [REMINDER_10MIN]: {
    title: 'Complete your profile',
    body: 'Add your photo and details so agencies can discover you.',
    functionName: 'sendRegistrationReminder10Min',
  },
  [REMINDER_24H]: {
    title: 'Finish setting up your profile',
    body: 'Complete your profile to start applying for casting calls.',
    functionName: 'sendRegistrationReminder24Hour',
  },
};

let oidcClient: OAuth2Client | undefined;
let tasksClient: CloudTasksClient | undefined;

function getOidcClient(): OAuth2Client {
  if (!oidcClient) {
    const {OAuth2Client} = require('google-auth-library') as typeof import('google-auth-library');
    oidcClient = new OAuth2Client();
  }
  return oidcClient;
}

function getTasksClient(): CloudTasksClient {
  if (!tasksClient) {
    const {CloudTasksClient} = require('@google-cloud/tasks') as typeof import('@google-cloud/tasks');
    tasksClient = new CloudTasksClient();
  }
  return tasksClient;
}

function db(): admin.firestore.Firestore {
  return admin.firestore();
}

export function reminderTasksConfig(): {
  projectId: string;
  location: string;
  queue: string;
  region: string;
  invokerSa: string;
  urlBase: string;
  delay10MinSeconds: number;
  delay24hSeconds: number;
} {
  const projectId =
    process.env.TASKS_PROJECT_ID ||
    process.env.GCLOUD_PROJECT ||
    process.env.GCP_PROJECT ||
    'talenthire-d86a1';
  const region =
    process.env.TASKS_FUNCTION_REGION ||
    process.env.TASKS_LOCATION ||
    REMINDER_FUNCTION_REGION;
  const location = process.env.TASKS_LOCATION || region;
  const queue = process.env.TASKS_QUEUE || REMINDER_QUEUE_NAME;
  const invokerSa =
    process.env.TASKS_INVOKER_SA || `${projectId}@appspot.gserviceaccount.com`;
  const urlBase =
    process.env.FUNCTION_URL_BASE ||
    `https://${region}-${projectId}.cloudfunctions.net`;
  const delay10MinSeconds = positiveIntEnv(
    'REGISTRATION_REMINDER_10MIN_SECONDS',
    10 * 60,
  );
  const delay24hSeconds = positiveIntEnv(
    'REGISTRATION_REMINDER_24H_SECONDS',
    24 * 60 * 60,
  );
  return {
    projectId,
    location,
    queue,
    region,
    invokerSa,
    urlBase,
    delay10MinSeconds,
    delay24hSeconds,
  };
}

function positiveIntEnv(name: string, fallback: number): number {
  const raw = process.env[name];
  if (!raw) return fallback;
  const value = Number(raw);
  return Number.isFinite(value) && value > 0 ? Math.floor(value) : fallback;
}

function reminderFunctionUrl(functionName: string): string {
  return `${reminderTasksConfig().urlBase.replace(/\/$/, '')}/${functionName}`;
}

function sanitizeTaskId(uid: string, type: ReminderType): string {
  const safeUid = uid.replace(/[^A-Za-z0-9_-]/g, '_').slice(0, 80);
  const prefix = type === REMINDER_10MIN ? 'reg-10min' : 'reg-24h';
  return `${prefix}-${safeUid}`;
}

function isAlreadyExists(error: unknown): boolean {
  return (
    typeof error === 'object' &&
    error !== null &&
    'code' in error &&
    (error as {code: number}).code === 6
  );
}

async function enqueueHttpReminderTask(opts: {
  uid: string;
  type: ReminderType;
  scheduleTime: Date;
}): Promise<string> {
  const config = reminderTasksConfig();
  const client = getTasksClient();
  const parent = client.queuePath(config.projectId, config.location, config.queue);
  const functionName = REMINDER_COPY[opts.type].functionName;
  const url = reminderFunctionUrl(functionName);
  const taskId = sanitizeTaskId(opts.uid, opts.type);
  const taskName = `${parent}/tasks/${taskId}`;

  const payload = JSON.stringify({
    uid: opts.uid,
    type: opts.type,
  });

  try {
    const [task] = await client.createTask({
      parent,
      task: {
        name: taskName,
        scheduleTime: {
          seconds: Math.floor(opts.scheduleTime.getTime() / 1000),
        },
        dispatchDeadline: {seconds: 60},
        httpRequest: {
          httpMethod: 'POST',
          url,
          headers: {'Content-Type': 'application/json'},
          body: Buffer.from(payload).toString('base64'),
          oidcToken: {
            serviceAccountEmail: config.invokerSa,
            audience: url,
          },
        },
      },
    });
    const createdName = task.name || taskName;
    functions.logger.info('registration reminder task created', {
      uid: opts.uid,
      type: opts.type,
      taskName: createdName,
      scheduleTime: opts.scheduleTime.toISOString(),
      url,
      queue: config.queue,
    });
    return createdName;
  } catch (error) {
    if (isAlreadyExists(error)) {
      functions.logger.info('registration reminder task already queued', {
        uid: opts.uid,
        type: opts.type,
        taskName,
      });
      return taskName;
    }
    functions.logger.error('registration reminder task create failed', {
      uid: opts.uid,
      type: opts.type,
      taskName,
      url,
      error,
    });
    throw error;
  }
}

function hasText(value: unknown): boolean {
  return value != null && String(value).trim().length > 0;
}

function hasList(value: unknown): boolean {
  if (Array.isArray(value)) {
    return value.some((item) => String(item).trim().length > 0);
  }
  return typeof value === 'string' && value.trim().length > 0;
}

function formSection(
  formData: Record<string, unknown>,
  key: string,
): Record<string, unknown> {
  const section = formData[key];
  return section && typeof section === 'object' && !Array.isArray(section)
    ? (section as Record<string, unknown>)
    : {};
}

/** Matches the mobile profile completion score. Skip FCM at 100% or explicit flag. */
export function isRegistrationActionComplete(
  profile: admin.firestore.DocumentData | undefined,
): boolean {
  if (!profile) return false;
  if (profile.profile_completed === true) return true;

  let score = 0;
  if (String(profile.profile_image || '').trim()) score += 20;

  const formData =
    profile.form_data && typeof profile.form_data === 'object'
      ? (profile.form_data as Record<string, unknown>)
      : {};
  const personal = formSection(formData, 'personal');
  if (hasText(profile.gender) || hasText(personal.gender)) score += 8;
  if (profile.age != null || hasText(personal.age)) score += 8;
  if (
    hasText(profile.city) ||
    hasText(profile.state) ||
    hasText(personal.location)
  ) {
    score += 8;
  }
  if (
    hasList(profile.languages) ||
    hasList(personal.language) ||
    hasList(personal.languages)
  ) {
    score += 8;
  }
  if (hasText(profile.bio) || hasText(personal.about)) score += 8;

  const social = formSection(formData, 'social');
  if (
    (Array.isArray(profile.platform_metrics) &&
      profile.platform_metrics.length > 0) ||
    hasText(profile.contact) ||
    hasText(social.handle)
  ) {
    score += 20;
  }

  const creator = formSection(formData, 'creator');
  if (hasList(creator.collab_types)) score += 7;
  if (hasList(creator.platforms)) score += 7;
  if (hasList(creator.niches) || hasList(profile.niches)) score += 6;

  return score >= 100;
}

function shouldSkipRole(role: unknown): boolean {
  return role === 'agency' || role === 'admin';
}

async function claimReminderSend(
  uid: string,
  type: ReminderType,
): Promise<boolean> {
  const userRef = db().collection('users').doc(uid);
  const field = REMINDER_SENT_FIELD[type];
  return db().runTransaction(async (tx) => {
    const snap = await tx.get(userRef);
    if (!snap.exists) return false;
    const reminders =
      (snap.data()?.registration_reminders as Record<string, unknown> | undefined) ??
      {};
    if (reminders[field]) return false;
    tx.set(
      userRef,
      {
        registration_reminders: {
          ...reminders,
          [field]: admin.firestore.FieldValue.serverTimestamp(),
        },
      },
      {merge: true},
    );
    return true;
  });
}

function readTaskPayload(req: functions.https.Request): {
  uid: string;
  type?: string;
} {
  const body = req.body;
  if (body && typeof body === 'object' && !Buffer.isBuffer(body)) {
    return {
      uid: String((body as {uid?: unknown}).uid || '').trim(),
      type:
        typeof (body as {type?: unknown}).type === 'string'
          ? String((body as {type?: unknown}).type)
          : undefined,
    };
  }
  if (typeof body === 'string' && body.length > 0) {
    const parsed = JSON.parse(body) as {uid?: unknown; type?: unknown};
    return {
      uid: String(parsed.uid || '').trim(),
      type: typeof parsed.type === 'string' ? parsed.type : undefined,
    };
  }
  return {uid: ''};
}

async function verifyCloudTasksRequest(
  req: functions.https.Request,
  expectedAudience: string,
): Promise<void> {
  const config = reminderTasksConfig();
  const queueHeader = req.get('X-CloudTasks-QueueName') || '';
  if (queueHeader && queueHeader !== config.queue) {
    const error = new Error('Unexpected Cloud Tasks queue');
    (error as {status?: number}).status = 403;
    throw error;
  }

  const authorization = req.get('Authorization') || '';
  const token = authorization.startsWith('Bearer ')
    ? authorization.slice(7)
    : '';
  if (!token) {
    const error = new Error('Missing Cloud Tasks OIDC bearer token');
    (error as {status?: number}).status = 401;
    throw error;
  }

  const ticket = await getOidcClient().verifyIdToken({
    idToken: token,
    audience: expectedAudience,
  });
  const payload = ticket.getPayload();
  const email = payload?.email || '';
  if (!payload?.email_verified || email !== config.invokerSa) {
    functions.logger.warn('registration reminder OIDC rejected', {
      email,
      expected: config.invokerSa,
    });
    const error = new Error('Request is not from the Cloud Tasks service account');
    (error as {status?: number}).status = 403;
    throw error;
  }
}

async function handleReminderRequest(
  req: functions.https.Request,
  res: functions.Response,
  expectedType: ReminderType,
): Promise<void> {
  const copy = REMINDER_COPY[expectedType];
  const audience = reminderFunctionUrl(copy.functionName);
  const retryCount = Number(req.get('X-CloudTasks-TaskRetryCount') || 0);

  if (req.method !== 'POST') {
    res.status(405).send('Method not allowed');
    return;
  }

  try {
    await verifyCloudTasksRequest(req, audience);
  } catch (error) {
    const status = (error as {status?: number}).status || 401;
    functions.logger.warn('registration reminder auth failed', {
      type: expectedType,
      status,
      error: error instanceof Error ? error.message : error,
    });
    res.status(status).send('Unauthenticated');
    return;
  }

  let uid = '';
  try {
    const payload = readTaskPayload(req);
    uid = payload.uid;
    if (!uid) {
      functions.logger.warn('registration reminder missing uid', {
        type: expectedType,
      });
      res.status(200).send('Ignored: missing uid');
      return;
    }
    if (payload.type && payload.type !== expectedType) {
      functions.logger.warn('registration reminder type mismatch', {
        uid,
        expectedType,
        payloadType: payload.type,
      });
      res.status(200).send('Ignored: type mismatch');
      return;
    }

    const [userSnap, profileSnap] = await Promise.all([
      db().collection('users').doc(uid).get(),
      db().collection('profiles').doc(uid).get(),
    ]);

    if (!userSnap.exists) {
      functions.logger.info('registration reminder skipped: no user', {
        uid,
        type: expectedType,
      });
      res.status(200).send('Skipped: user missing');
      return;
    }

    const user = userSnap.data() ?? {};
    if (shouldSkipRole(user.role) || user.is_active === false) {
      functions.logger.info('registration reminder skipped: role/status', {
        uid,
        type: expectedType,
        role: user.role,
        isActive: user.is_active,
      });
      res.status(200).send('Skipped: not eligible');
      return;
    }

    if (isRegistrationActionComplete(profileSnap.data())) {
      functions.logger.info('registration reminder skipped: action complete', {
        uid,
        type: expectedType,
      });
      res.status(200).send('Skipped: profile complete');
      return;
    }

    const claimed = await claimReminderSend(uid, expectedType);
    if (!claimed) {
      functions.logger.info('registration reminder skipped: already sent', {
        uid,
        type: expectedType,
        retryCount,
      });
      res.status(200).send('Skipped: already sent');
      return;
    }

    const notificationId = `reg_reminder_${
      expectedType === REMINDER_10MIN ? '10min' : '24h'
    }_${uid}`;
    await db().collection('notifications').doc(notificationId).set(
      {
        userId: uid,
        type: 'profile',
        title: copy.title,
        body: copy.body,
        read: false,
        pushed: true,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: true},
    );

    const tokens: unknown[] = user.fcm_tokens || [];
    if (!Array.isArray(tokens) || tokens.length === 0) {
      functions.logger.info('registration reminder skipped: no FCM tokens', {
        uid,
        type: expectedType,
        notificationId,
      });
      res.status(200).send('Skipped: no FCM tokens');
      return;
    }

    await sendPushToUser({
      userId: uid,
      title: copy.title,
      body: copy.body,
      channelId: 'alerts',
      data: {
        type: 'profile',
        title: copy.title,
        body: copy.body,
        notificationId,
      },
    });

    functions.logger.info('registration reminder sent', {
      uid,
      type: expectedType,
      notificationId,
      retryCount,
    });
    res.status(200).send('Sent');
  } catch (error) {
    functions.logger.error('registration reminder execution failed', {
      uid,
      type: expectedType,
      retryCount,
      error,
    });
    res.status(500).send('Transient failure');
  }
}

/**
 * After a successful `users/{uid}` create, enqueue the 10-minute and
 * 24-hour HTTP Cloud Tasks. Agency/admin accounts are ignored.
 */
export const onUserRegistered = functions
  .region(REMINDER_FUNCTION_REGION)
  .firestore.document('users/{uid}')
  .onCreate(async (snapshot, context) => {
    const uid = String(context.params.uid || snapshot.id);
    const role = snapshot.data()?.role;
    if (shouldSkipRole(role)) {
      functions.logger.info('registration reminder enqueue skipped', {uid, role});
      return null;
    }

    const registrationTime =
      snapshot.createTime?.toDate() ??
      (snapshot.data()?.created_at
        ? new Date(String(snapshot.data()?.created_at))
        : new Date());
    const config = reminderTasksConfig();
    const schedule10 = new Date(
      registrationTime.getTime() + config.delay10MinSeconds * 1000,
    );
    const schedule24 = new Date(
      registrationTime.getTime() + config.delay24hSeconds * 1000,
    );

    functions.logger.info('registration reminder enqueue start', {
      uid,
      registrationTime: registrationTime.toISOString(),
      schedule10: schedule10.toISOString(),
      schedule24: schedule24.toISOString(),
      queue: config.queue,
      location: config.location,
      projectId: config.projectId,
    });

    await Promise.all([
      enqueueHttpReminderTask({
        uid,
        type: REMINDER_10MIN,
        scheduleTime: schedule10,
      }),
      enqueueHttpReminderTask({
        uid,
        type: REMINDER_24H,
        scheduleTime: schedule24,
      }),
    ]);
    return null;
  });

export const sendRegistrationReminder10Min = functions
  .region(REMINDER_FUNCTION_REGION)
  .https.onRequest((req, res) =>
    handleReminderRequest(req, res, REMINDER_10MIN),
  );

export const sendRegistrationReminder24Hour = functions
  .region(REMINDER_FUNCTION_REGION)
  .https.onRequest((req, res) =>
    handleReminderRequest(req, res, REMINDER_24H),
  );
