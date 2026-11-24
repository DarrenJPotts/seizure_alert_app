const test = require("node:test");
const assert = require("node:assert/strict");

const { FANOUT_MAX_AGE_MS, isFanoutStale, hasRetryableFailure } = require("../alert-fanout");

const T0 = Date.parse("2026-11-23T10:00:00.000Z");

test("a fresh event is retried", () => {
  assert.equal(isFanoutStale("2026-11-23T10:00:00.000Z", T0 + 60 * 1000), false);
});

test("an event just inside the window is still retried", () => {
  assert.equal(isFanoutStale("2026-11-23T10:00:00.000Z", T0 + FANOUT_MAX_AGE_MS), false);
});

test("an event older than the window is dropped", () => {
  assert.equal(isFanoutStale("2026-11-23T10:00:00.000Z", T0 + FANOUT_MAX_AGE_MS + 1), true);
});

test("an unparseable event time is retried rather than dropped", () => {
  assert.equal(isFanoutStale(undefined, T0), false);
  assert.equal(isFanoutStale("not a date", T0), false);
});

test("the window is short enough that a late push is still useful", () => {
  assert.ok(FANOUT_MAX_AGE_MS <= 15 * 60 * 1000);
  assert.ok(FANOUT_MAX_AGE_MS >= 2 * 60 * 1000);
});

test("only an FCM failure is worth retrying", () => {
  assert.equal(hasRetryableFailure([{ status: "sent" }, { status: "failed" }]), true);
  for (const status of ["sent", "notLinked", "accountMissing", "deviceOffline"]) {
    assert.equal(hasRetryableFailure([{ status }]), false, status);
  }
  assert.equal(hasRetryableFailure([]), false);
});
