const test = require("node:test");
const assert = require("node:assert/strict");

const { isEscalationStale } = require("../time");

const GRACE = 60 * 60 * 1000;
const NOW = Date.parse("2026-03-14T12:00:00.000Z");

test("escalates an expiry that is only seconds late", () => {

  assert.equal(isEscalationStale(NOW - 30_000, NOW, GRACE), false);
  assert.equal(isEscalationStale(NOW, NOW, GRACE), false);
});

test("still escalates through a plausible transient outage", () => {
  assert.equal(isEscalationStale(NOW - 20 * 60_000, NOW, GRACE), false);
  assert.equal(isEscalationStale(NOW - GRACE, NOW, GRACE), false, "exactly at the grace still counts");
});

test("suppresses a backlog older than the grace", () => {
  assert.equal(isEscalationStale(NOW - GRACE - 1, NOW, GRACE), true);

  assert.equal(isEscalationStale(NOW - 3 * 24 * 3600_000, NOW, GRACE), true);
});

test("never suppresses a window with no measurable expiry", () => {

assert.equal(isEscalationStale(undefined, NOW, GRACE), false);
  assert.equal(isEscalationStale(null, NOW, GRACE), false);
  assert.equal(isEscalationStale(NaN, NOW, GRACE), false);
});

test("treats a future expiry as not stale", () => {

  assert.equal(isEscalationStale(NOW + 5 * 60_000, NOW, GRACE), false);
});
