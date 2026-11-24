const test = require("node:test");
const assert = require("node:assert/strict");

const { notifyLimitFor, tracksDelivery } = require("../alert-rate-limit");

test("SOS has its own high ceiling, not the shared budget", () => {
  const limit = notifyLimitFor("created", "sos");
  assert.equal(limit.action, "sosNotify");
  assert.equal(limit.max, 20);
  assert.equal(limit.windowMs, 60 * 60 * 1000);
});

test("a missed check-in is server-written and never limited", () => {
  assert.equal(notifyLimitFor("created", "headsUpExpired"), null);
});

test("Heads Up has its own bucket", () => {
  const limit = notifyLimitFor("created", "headsUp");
  assert.equal(limit.action, "headsUpNotify");
  assert.equal(limit.max, 6);
});

test("no two alert types share a bucket", () => {
  const actions = ["sos", "headsUp", "somethingElse"]
    .map((type) => notifyLimitFor("created", type)?.action)
    .filter(Boolean);
  assert.equal(new Set(actions).size, actions.length);
});

test("cancels are never limited, whatever the type", () => {
  for (const type of ["sos", "headsUp", "headsUpExpired", "somethingElse"]) {
    assert.equal(notifyLimitFor("cancelled", type), null, type);
  }
});

test("unknown types fall back to a modest limit", () => {
  const limit = notifyLimitFor("created", "somethingElse");
  assert.equal(limit.action, "alertNotify");
  assert.equal(limit.max, 6);
});

test("SOS and missed check-ins are the delivery-tracked types", () => {
  assert.equal(tracksDelivery("sos"), true);
  assert.equal(tracksDelivery("headsUpExpired"), true);
  assert.equal(tracksDelivery("headsUp"), false);
});
