const test = require("node:test");
const assert = require("node:assert/strict");

const {
  MISSED_CHECK_IN_TTL_MS,
  WATCH_SOS_REUSE_MS,
  isMissedCheckInExpired,
  pickUrgentAlert,
  isReusableWatchSos,
  updateNotification,
} = require("../open-alerts");

const NOW = Date.parse("2026-11-23T12:00:00.000Z");
const ago = (ms) => new Date(NOW - ms).toISOString();
const MIN = 60 * 1000;

test("a missed check-in times out after 12 hours", () => {
  assert.equal(MISSED_CHECK_IN_TTL_MS, 12 * 60 * MIN);
  const alert = { type: "headsUpExpired", status: "sent" };
  assert.equal(isMissedCheckInExpired({ ...alert, createdAt: ago(MISSED_CHECK_IN_TTL_MS) }, NOW), false);
  assert.equal(isMissedCheckInExpired({ ...alert, createdAt: ago(MISSED_CHECK_IN_TTL_MS + 1) }, NOW), true);
});

test("only open missed check-ins time out", () => {
  const old = ago(MISSED_CHECK_IN_TTL_MS * 2);
  assert.equal(isMissedCheckInExpired({ type: "sos", status: "sent", createdAt: old }, NOW), false);
  assert.equal(isMissedCheckInExpired({ type: "headsUpExpired", status: "resolved", createdAt: old }, NOW), false);
});

test("an open Heads Up never marks someone as urgent", () => {
  assert.equal(pickUrgentAlert([{ type: "headsUp", status: "sent", createdAt: ago(MIN) }], NOW), null);
});

test("an open missed check-in shows like an SOS until it times out", () => {
  const fresh = { id: "m1", type: "headsUpExpired", status: "sent", createdAt: ago(MIN) };
  const stale = { id: "m2", type: "headsUpExpired", status: "sent", createdAt: ago(MISSED_CHECK_IN_TTL_MS + MIN) };
  assert.equal(pickUrgentAlert([fresh], NOW).id, "m1");
  assert.equal(pickUrgentAlert([stale], NOW), null);
});

test("an SOS takes priority over a missed check-in", () => {
  const missed = { id: "m1", type: "headsUpExpired", status: "sent", createdAt: ago(MIN) };
  const sos = { id: "s1", type: "sos", status: "sent", createdAt: ago(5 * MIN) };
  assert.equal(pickUrgentAlert([missed, sos], NOW).id, "s1");
});

test("a watch SOS reuses only a recent open SOS", () => {
  const sos = { type: "sos", status: "sent" };
  assert.equal(isReusableWatchSos({ ...sos, createdAt: ago(WATCH_SOS_REUSE_MS) }, NOW), true);
  assert.equal(isReusableWatchSos({ ...sos, createdAt: ago(WATCH_SOS_REUSE_MS + 1) }, NOW), false);
  assert.equal(isReusableWatchSos({ ...sos, createdAt: ago(7 * 24 * 60 * MIN) }, NOW), false);
});

test("a phone timestamp that reads slightly in the future still counts as recent", () => {
  // Local time with no offset, written in UTC+2 and parsed as UTC.
  assert.equal(isReusableWatchSos({ type: "sos", status: "sent", createdAt: "2026-11-23T14:00:00.000" }, NOW), true);
});

test("an unreadable timestamp is never reused", () => {
  assert.equal(isReusableWatchSos({ type: "sos", status: "sent", createdAt: "?" }, NOW), false);
});

test("cancelling sends the cancelled push", () => {
  assert.equal(updateNotification({ status: "sent" }, { type: "sos", status: "cancelled" }), "cancelled");
});

test("closing a missed check-in sends an okay push, unless the server timed it out", () => {
  const before = { status: "sent" };
  assert.equal(updateNotification(before, { type: "headsUpExpired", status: "resolved" }), "okay");
  assert.equal(
    updateNotification(before, { type: "headsUpExpired", status: "resolved", resolvedReason: "timeout" }),
    null
  );
});

test("other updates send nothing", () => {
  assert.equal(updateNotification({ status: "sent" }, { type: "sos", status: "sent" }), null);
  assert.equal(updateNotification({ status: "sent" }, { type: "headsUp", status: "resolved" }), null);
  assert.equal(updateNotification({ status: "cancelled" }, { type: "sos", status: "cancelled" }), null);
});
