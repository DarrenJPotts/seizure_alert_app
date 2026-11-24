/**
 * Retry policy for the alert fan-out triggers (onAlertCreated, onAlertUpdated).
 *
 * Both triggers run with `retry: true`, so a transient error (a Firestore
 * read, a transaction conflict, an FCM outage) re-runs them instead of losing
 * the alert. Event-driven retries can continue for days, and a push about a
 * seizure that long ago would only confuse people, so a retry stops once the
 * triggering event is older than FANOUT_MAX_AGE_MS.
 *
 * Sends are made safe to repeat by the per-contact `alert_deliveries` record:
 * a contact already marked `sent` is skipped on the next attempt.
 */

const FANOUT_MAX_AGE_MS = 10 * 60 * 1000;

/** True once the triggering event is too old to be worth retrying. */
function isFanoutStale(eventTime, nowMs = Date.now(), maxAgeMs = FANOUT_MAX_AGE_MS) {
  const eventMs = Date.parse(eventTime);
  if (Number.isNaN(eventMs)) return false;
  return nowMs - eventMs > maxAgeMs;
}

/**
 * A `failed` send is an FCM error that was not a stale token, so it may work
 * on a retry. `notLinked`, `accountMissing` and `deviceOffline` will not.
 */
function hasRetryableFailure(deliveries) {
  return deliveries.some((delivery) => delivery.status === "failed");
}

module.exports = { FANOUT_MAX_AGE_MS, isFanoutStale, hasRetryableFailure };
