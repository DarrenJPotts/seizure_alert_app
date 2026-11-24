const test = require("node:test");
const assert = require("node:assert/strict");

const {
  MAX_TOKENS_PER_USER,
  isStaleTokenError,
  tokensOf,
  summarizeSends,
  betterStatus,
} = require("../push-tokens");

test("a user with a phone and a tablet gets both tokens, newest first", () => {
  const tokens = tokensOf({ fcmTokens: { phone: 100, tablet: 200 } });
  assert.deepEqual(tokens, ["tablet", "phone"]);
});

test("the legacy single token still works on its own", () => {
  assert.deepEqual(tokensOf({ fcmToken: "old-app" }), ["old-app"]);
});

test("the legacy token counts as the newest and is not duplicated", () => {
  const tokens = tokensOf({ fcmToken: "phone", fcmTokens: { phone: 100, tablet: 200 } });
  assert.deepEqual(tokens, ["phone", "tablet"]);
});

test("caps the number of devices sent to", () => {
  const map = {};
  for (let i = 0; i < MAX_TOKENS_PER_USER + 3; i += 1) map[`t${i}`] = i;
  const tokens = tokensOf({ fcmTokens: map });
  assert.equal(tokens.length, MAX_TOKENS_PER_USER);
  assert.equal(tokens[0], `t${MAX_TOKENS_PER_USER + 2}`);
});

test("no tokens for a missing or empty user", () => {
  assert.deepEqual(tokensOf(undefined), []);
  assert.deepEqual(tokensOf({}), []);
  assert.deepEqual(tokensOf({ fcmToken: "", fcmTokens: { "": 1 } }), []);
});

test("one device reached is enough", () => {
  assert.equal(summarizeSends(["stale", "sent", "failed"]), "sent");
});

test("a retryable failure is reported over an offline device", () => {
  assert.equal(summarizeSends(["stale", "failed"]), "failed");
});

test("no tokens or only stale ones is deviceOffline", () => {
  assert.equal(summarizeSends([]), "deviceOffline");
  assert.equal(summarizeSends(["stale", "stale"]), "deviceOffline");
});

test("betterStatus keeps the best outcome", () => {
  assert.equal(betterStatus("deviceOffline", "sent"), "sent");
  assert.equal(betterStatus("sent", "failed"), "sent");
  assert.equal(betterStatus("deviceOffline", "failed"), "failed");
});

test("recognises stale-token errors in both shapes", () => {
  assert.equal(isStaleTokenError({ code: "messaging/registration-token-not-registered" }), true);
  assert.equal(isStaleTokenError({ errorInfo: { code: "messaging/invalid-registration-token" } }), true);
  assert.equal(isStaleTokenError({ code: "messaging/internal-error" }), false);
});
