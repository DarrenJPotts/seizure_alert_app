const test = require("node:test");
const assert = require("node:assert/strict");

const { buildMessage, isUrgentPush } = require("../push-message");

const base = { token: "t", title: "T", body: "B", alertId: "a1", userId: "u1" };
const aps = (message) => message.apns.payload.aps;

test("an open SOS is time-sensitive on iOS", () => {
  const message = buildMessage({ ...base, alertType: "sos", alertStatus: "sent" });
  assert.equal(aps(message)["interruption-level"], "time-sensitive");
  assert.equal(aps(message)["relevance-score"], 1);
  assert.equal(message.apns.headers["apns-priority"], "10");
  assert.equal(message.apns.headers["apns-push-type"], "alert");
});

test("a missed check-in is time-sensitive on iOS", () => {
  const message = buildMessage({ ...base, alertType: "headsUpExpired", alertStatus: "sent" });
  assert.equal(aps(message)["interruption-level"], "time-sensitive");
});

test("the caregiver test alert behaves like a real one", () => {
  assert.equal(isUrgentPush("test", "test"), true);
});

test("cancels, Heads Up and 'okay' updates are not time-sensitive", () => {
  for (const [type, status] of [
    ["sos", "cancelled"],
    ["headsUp", "sent"],
    ["headsUpExpired", "resolved"],
  ]) {
    const message = buildMessage({ ...base, alertType: type, alertStatus: status });
    assert.equal(aps(message)["interruption-level"], "active", `${type}/${status}`);
    assert.equal(aps(message)["relevance-score"], undefined);
  }
});

test("keeps the existing sound, data and Android settings", () => {
  const message = buildMessage({ ...base, alertType: "sos", alertStatus: "sent", route: "/x" });
  assert.equal(aps(message).sound, "default");
  assert.equal(aps(message).contentAvailable, true);
  assert.deepEqual(message.data, {
    alertType: "sos",
    alertStatus: "sent",
    userId: "u1",
    alertId: "a1",
    route: "/x",
  });
  assert.equal(message.android.priority, "high");
  assert.equal(message.android.notification.sound, "seizure_alert");
});

test("a TTL sets the Android TTL and the APNs expiry together with the other headers", () => {
  const message = buildMessage({ ...base, alertType: "test", alertStatus: "test", ttlMs: 5 * 60 * 1000 });
  assert.equal(message.android.ttl, 5 * 60 * 1000);
  assert.ok(Number(message.apns.headers["apns-expiration"]) > Date.now() / 1000);
  assert.equal(message.apns.headers["apns-priority"], "10");
});
