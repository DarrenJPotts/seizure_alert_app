/**
 * Which notification rate limit applies to an alert event.
 *
 * Previously every alert event for a user (SOS, Heads Up, missed check-in and
 * every cancel) shared one budget of 6 per 10 minutes. A few false starts
 * during cluster seizures could use it up, and the next real SOS was dropped
 * with only a log line.
 *
 * Now:
 *  - SOS has its own, much higher ceiling. It exists only to stop a runaway
 *    client from flooding its own circle, never to ration real alerts.
 *  - A missed check-in (`headsUpExpired`) is written by the server, never by a
 *    phone (firestore.rules allows clients only `sos` and `headsUp`), so it is
 *    trusted and never limited.
 *  - Heads Up keeps a modest limit in its own bucket.
 *  - Cancels are never limited: the update trigger fires once per alert, on
 *    the transition to `cancelled`, so they are bounded by the creates.
 *
 * Returns null when no limit applies.
 */

const MINUTE_MS = 60 * 1000;

const CREATE_LIMITS = {
  sos: { action: "sosNotify", max: 20, windowMs: 60 * MINUTE_MS },
  headsUp: { action: "headsUpNotify", max: 6, windowMs: 10 * MINUTE_MS },
  headsUpExpired: null,
};

const DEFAULT_CREATE_LIMIT = { action: "alertNotify", max: 6, windowMs: 10 * MINUTE_MS };

/**
 * @param {"created" | "cancelled"} event
 * @param {string} alertType
 * @returns {{action: string, max: number, windowMs: number} | null}
 */
function notifyLimitFor(event, alertType) {
  if (event === "cancelled") return null;
  if (Object.prototype.hasOwnProperty.call(CREATE_LIMITS, alertType)) {
    return CREATE_LIMITS[alertType];
  }
  return DEFAULT_CREATE_LIMIT;
}

/** Alert types whose fan-out writes per-contact `alert_deliveries` records. */
function tracksDelivery(alertType) {
  return alertType === "sos" || alertType === "headsUpExpired";
}

module.exports = { notifyLimitFor, tracksDelivery };
