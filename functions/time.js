/**
 * Time helpers shared by the callables.
 *
 * Split out of `index.js` for the same reason as `phone.js`: that module
 * calls `initializeApp()` at load, so anything living inside it can only be
 * exercised against real credentials. These are pure functions and are
 * covered by `test/time.test.js`.
 */

/**
 * Whole days between `iso` and now, or null when there is nothing to measure.
 *
 * Timestamps in this database are written with Dart's `toIso8601String()` on
 * a *local* DateTime, so they carry no timezone suffix and `Date.parse` reads
 * them as UTC. That skews the result by at most the writer's offset, which
 * cannot change a day count that is only ever rendered as "18d" / "18 days
 * ago". Do not reuse this for anything that needs to be exact to the hour.
 *
 * @param {string|null|undefined} iso
 * @param {number} [now] epoch millis to measure against; defaults to Date.now()
 * @returns {number|null}
 */
function daysSince(iso, now = Date.now()) {
  if (!iso) return null;
  const then = Date.parse(iso);
  if (Number.isNaN(then)) return null;
  return Math.max(0, Math.floor((now - then) / 86400000));
}

/**
 * Whether a Heads Up expiry is too old to be worth escalating.
 *
 * The sweep runs every minute, so a real expiry is seconds late. Anything far
 * older means the sweep was down, and escalating a days-old backlog produces
 * false alarms on the one notification channel this app needs people to trust.
 *
 * A window with no `expiresAtMs` at all (written before that field existed)
 * is never treated as stale — it is simply unmeasurable, and the existing
 * range query already skips those documents.
 *
 * @param {number|null|undefined} expiresAtMs
 * @param {number} nowMs
 * @param {number} graceMs
 * @returns {boolean}
 */
function isEscalationStale(expiresAtMs, nowMs, graceMs) {
  if (typeof expiresAtMs !== "number" || Number.isNaN(expiresAtMs)) return false;
  return nowMs - expiresAtMs > graceMs;
}

module.exports = { daysSince, isEscalationStale };
