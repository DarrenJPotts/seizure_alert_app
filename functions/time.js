/**
 * Time helpers shared by the callables.
 * Split out of `index.js` for the same reason as `phone.js`: that module
 * calls `initializeApp()` at load, so anything living inside it can only be
 * exercised against real credentials. These are pure functions and are
 * covered by `test/time.test.js`.
 */

/**
 * Timestamps in this database are written with Dart's `toIso8601String()` on
 * a *local* DateTime, so they carry no timezone suffix and `Date.parse` reads
 * them as UTC. That skews the result by at most the writer's offset, which
 * cannot change a day count that is only ever rendered as "18d" / "18 days
 * ago". Do not reuse this for anything that needs to be exact to the hour.
 */
function daysSince(iso, now = Date.now()) {
  if (!iso) return null;
  const then = Date.parse(iso);
  if (Number.isNaN(then)) return null;
  return Math.max(0, Math.floor((now - then) / 86400000));
}

function isEscalationStale(expiresAtMs, nowMs, graceMs) {
  if (typeof expiresAtMs !== "number" || Number.isNaN(expiresAtMs)) return false;
  return nowMs - expiresAtMs > graceMs;
}

module.exports = { daysSince, isEscalationStale };
