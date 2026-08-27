const test = require("node:test");
const assert = require("node:assert/strict");

const { isEscalationStale } = require("../time");

/**
 * Gates whether a caregiver is told about a missed check-in. Getting it wrong
 * in one direction means a real missed check-in goes unreported; in the other,
 * it means a burst of false alarms — which is how the alert channel stops being
 * taken seriously. The boundary is worth pinning in both directions.
 */

const GRACE = 60 * 60 * 1000; // one hour, matching HEADS_UP_ESCALATION_GRACE_MS
const NOW = Date.parse("2026-03-14T12:00:00.000Z");

test("escalates an expiry that is only seconds late", () => {
  // The normal case: the sweep runs every minute.
  assert.equal(isEscalationStale(NOW - 30_000, NOW, GRACE), false);
  assert.equal(isEscalationStale(NOW, NOW, GRACE), false);
});

test("still escalates through a plausible transient outage", () => {
  assert.equal(isEscalationStale(NOW - 20 * 60_000, NOW, GRACE), false);
  assert.equal(isEscalationStale(NOW - GRACE, NOW, GRACE), false, "exactly at the grace still counts");
});

test("suppresses a backlog older than the grace", () => {
  assert.equal(isEscalationStale(NOW - GRACE - 1, NOW, GRACE), true);
  // The case that prompted this: ~3 days of failed sweeps.
  assert.equal(isEscalationStale(NOW - 3 * 24 * 3600_000, NOW, GRACE), true);
});

test("never suppresses a window with no measurable expiry", () => {
  // Written before expiresAtMs existed. Unmeasurable is not the same as stale,
  // and the sweep's range query already skips these anyway.
  assert.equal(isEscalationStale(undefined, NOW, GRACE), false);
  assert.equal(isEscalationStale(null, NOW, GRACE), false);
  assert.equal(isEscalationStale(NaN, NOW, GRACE), false);
});

test("treats a future expiry as not stale", () => {
  // Clock skew between a phone and the server is real.
  assert.equal(isEscalationStale(NOW + 5 * 60_000, NOW, GRACE), false);
});
