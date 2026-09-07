const IST_OFFSET_MS = (5 * 60 + 30) * 60 * 1000;

export const APPLY_TRIAL_DAYS = 3;
export const FREE_APPLIES_PER_DAY = 3;

export type ApplyGateReason = 'allowed' | 'daily_limit' | 'trial_ended';

export interface ApplyQuotaApplication {
  appliedAt: Date;
  status: string;
}

/** Calendar date in IST — matches the Indian market for this app. */
export function istDateOnly(date: Date): Date {
  const ist = new Date(date.getTime() + IST_OFFSET_MS);
  return new Date(
    Date.UTC(ist.getUTCFullYear(), ist.getUTCMonth(), ist.getUTCDate()),
  );
}

export function isSameIstDay(a: Date, b: Date): boolean {
  return istDateOnly(a).getTime() === istDateOnly(b).getTime();
}

export function trialDayNumber(createdAt: Date, now: Date = new Date()): number {
  const start = istDateOnly(createdAt);
  const today = istDateOnly(now);
  const day =
    Math.floor((today.getTime() - start.getTime()) / (24 * 60 * 60 * 1000)) +
    1;
  return day < 1 ? 1 : day;
}

export function appliesToday(
  applications: ApplyQuotaApplication[],
  now: Date = new Date(),
): number {
  return applications.filter((item) => {
    if (item.status === 'withdrawn') return false;
    return isSameIstDay(item.appliedAt, now);
  }).length;
}

export function evaluateApplyGate(opts: {
  isPremium: boolean;
  accountCreatedAt: Date;
  applications: ApplyQuotaApplication[];
  now?: Date;
}): ApplyGateReason {
  const now = opts.now ?? new Date();
  if (opts.isPremium) return 'allowed';
  if (trialDayNumber(opts.accountCreatedAt, now) > APPLY_TRIAL_DAYS) {
    return 'trial_ended';
  }
  if (appliesToday(opts.applications, now) >= FREE_APPLIES_PER_DAY) {
    return 'daily_limit';
  }
  return 'allowed';
}
