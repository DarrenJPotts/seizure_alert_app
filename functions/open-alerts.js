/**
 * Rules for which alerts still count as open.
 *
 * Alerts that were never closed used to keep people marked as "SOS" on every
 * caregiver's watch list indefinitely, and an old SOS stopped the watch from
 * sending a new one. These are pure functions, covered by
 * test/open-alerts.test.js.
 */

const MINUTE_MS = 60 * 1000;

/** A missed check-in nobody closed is treated as over after this long. */
const MISSED_CHECK_IN_TTL_MS = 12 * 60 * MINUTE_MS;

/** A watch SOS reuses an open SOS only if it is this recent. */
const WATCH_SOS_REUSE_MS = 15 * MINUTE_MS;

/** Alert types that put a person at the top of the watch list. */
const URGENT_TYPES = ["sos", "headsUpExpired"];

function ageMs(alert, nowMs) {
  const createdMs = Date.parse(alert?.createdAt);
  return Number.isNaN(createdMs) ? null : nowMs - createdMs;
}

/** A missed check-in still open after MISSED_CHECK_IN_TTL_MS. */
function isMissedCheckInExpired(alert, nowMs) {
  if (alert?.type !== "headsUpExpired" || alert.status !== "sent") return false;
  const age = ageMs(alert, nowMs);
  return age !== null && age > MISSED_CHECK_IN_TTL_MS;
}

/**
 * From a person's open alerts, the one the watch list should show: an SOS
 * first, then a missed check-in that has not timed out. Heads Up alerts are
 * not urgent and are shown through the Heads Up document instead.
 */
function pickUrgentAlert(alerts, nowMs) {
  const live = alerts.filter(
    (alert) =>
      alert?.status === "sent" &&
      URGENT_TYPES.includes(alert.type) &&
      !isMissedCheckInExpired(alert, nowMs)
  );
  return live.find((alert) => alert.type === "sos") || live[0] || null;
}

/**
 * Whether a watch SOS should reuse this open SOS instead of creating a new
 * one. Phone timestamps carry no offset, so a recent alert can look a little
 * in the future; that still counts as recent.
 */
function isReusableWatchSos(alert, nowMs) {
  if (alert?.type !== "sos" || alert.status !== "sent") return false;
  const age = ageMs(alert, nowMs);
  return age !== null && age <= WATCH_SOS_REUSE_MS;
}

/**
 * Which push, if any, an alert update should send:
 *  - "cancelled" when the patient cancels;
 *  - "okay" when the patient closes a missed check-in by saying they are OK;
 *  - null otherwise, including a missed check-in the server timed out.
 */
function updateNotification(before, after) {
  if (!before || !after || before.status !== "sent") return null;
  if (after.status === "cancelled") return "cancelled";
  if (
    after.type === "headsUpExpired" &&
    after.status === "resolved" &&
    after.resolvedReason !== "timeout"
  ) {
    return "okay";
  }
  return null;
}

module.exports = {
  MISSED_CHECK_IN_TTL_MS,
  WATCH_SOS_REUSE_MS,
  URGENT_TYPES,
  isMissedCheckInExpired,
  pickUrgentAlert,
  isReusableWatchSos,
  updateNotification,
};
