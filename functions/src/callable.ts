import * as functions from 'firebase-functions/v1';

export const FUNCTION_REGION = 'asia-south1';

/**
 * Shared callable wrapper. App Check is intentionally disabled — the mobile app
 * does not integrate firebase_app_check and must not be rejected at the edge.
 */
export function callable() {
  return functions.region(FUNCTION_REGION).runWith({
    enforceAppCheck: false,
  });
}
