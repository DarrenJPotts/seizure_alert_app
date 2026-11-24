/**
 * A user's push tokens, one per signed-in device.
 *
 * Each user doc used to hold a single `fcmToken`, so a caregiver signed in on
 * a phone and a tablet only got alerts on whichever registered last. Devices
 * now also write `fcmTokens.<token> = <updatedAtMs>`. `fcmToken` is still
 * written (the latest device) and read, so older app versions keep working
 * during the rollout.
 *
 * Pure functions, covered by test/push-tokens.test.js.
 */

/** Newest devices first; older ones beyond this are not sent to. */
const MAX_TOKENS_PER_USER = 5;

const STALE_CODES = [
  "messaging/registration-token-not-registered",
  "messaging/invalid-registration-token",
];

function isStaleTokenError(error) {
  const code = error?.code || error?.errorInfo?.code;
  return STALE_CODES.includes(code);
}

/** The user's tokens, newest first, without duplicates. */
function tokensOf(userData) {
  if (!userData || typeof userData !== "object") return [];
  const byToken = new Map();
  const map = userData.fcmTokens;
  if (map && typeof map === "object") {
    for (const [token, at] of Object.entries(map)) {
      if (typeof token === "string" && token.length > 0) {
        byToken.set(token, Number(at) || 0);
      }
    }
  }
  // The legacy field is always the most recently registered device.
  const legacy = userData.fcmToken;
  if (typeof legacy === "string" && legacy.length > 0) {
    byToken.set(legacy, Number.MAX_SAFE_INTEGER);
  }
  return [...byToken.entries()]
    .sort((a, b) => b[1] - a[1])
    .slice(0, MAX_TOKENS_PER_USER)
    .map(([token]) => token);
}

/**
 * One delivery status for a user from the result of each device send
 * ("sent", "stale" or "failed"): sent if any device got it; failed if a
 * device hit an error worth retrying; otherwise deviceOffline.
 */
function summarizeSends(results) {
  if (results.includes("sent")) return "sent";
  if (results.includes("failed")) return "failed";
  return "deviceOffline";
}

/** The better of two delivery statuses, for a user reached several ways. */
function betterStatus(a, b) {
  const rank = { sent: 3, failed: 2, deviceOffline: 1 };
  return (rank[b] || 0) > (rank[a] || 0) ? b : a;
}

module.exports = {
  MAX_TOKENS_PER_USER,
  isStaleTokenError,
  tokensOf,
  summarizeSends,
  betterStatus,
};
