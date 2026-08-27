const test = require("node:test");
const assert = require("node:assert/strict");

const { daysSince } = require("../time");

/**
 * daysSince feeds the "Seizure-free 18d" chip on the caregiver watch list and
 * the "Last event 18 days ago" card on the incoming-SOS screen. Both are read
 * by someone deciding how urgent a situation is, so the failure that matters
 * is not an off-by-one — it is returning a number when the input was garbage,
 * or throwing and taking the screen down with it.
 */

const NOW = Date.parse("2026-03-14T12:00:00.000Z");

test("counts whole days elapsed", () => {
  assert.equal(daysSince("2026-02-24T12:00:00.000Z", NOW), 18);
  assert.equal(daysSince("2026-03-13T12:00:00.000Z", NOW), 1);
  assert.equal(daysSince("2026-03-14T12:00:00.000Z", NOW), 0);
});

test("floors a partial day rather than rounding up", () => {
  // 23h 59m is still "0 days ago". Rounding up would report a seizure that
  // happened this morning as having been yesterday.
  assert.equal(daysSince("2026-03-13T12:00:01.000Z", NOW), 0);
  assert.equal(daysSince("2026-03-13T11:59:59.000Z", NOW), 1);
});

test("accepts the unzoned ISO strings the Dart client writes", () => {
  // Dart's toIso8601String() on a local DateTime emits no timezone suffix.
  // This is the format actually in the database, so it must parse.
  assert.equal(typeof daysSince("2026-02-24T09:00:00.000", NOW), "number");
});

test("returns null for anything unmeasurable", () => {
  assert.equal(daysSince(null), null);
  assert.equal(daysSince(undefined), null);
  assert.equal(daysSince(""), null);
  assert.equal(daysSince("not-a-date", NOW), null);
});

test("never returns a negative count for a future timestamp", () => {
  // Clock skew between a phone and the server is real. "-2 days since last
  // seizure" on an emergency screen is worse than showing 0.
  assert.equal(daysSince("2026-03-20T12:00:00.000Z", NOW), 0);
});
