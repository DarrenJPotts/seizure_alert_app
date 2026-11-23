const test = require("node:test");
const assert = require("node:assert/strict");

const {
  safetyFunctionsEnabled,
  remoteConfigFlagLoader,
  SAFETY_FLAG_PARAM,
  SAFETY_FLAG_CACHE_TTL_MS,
  _resetSafetyFlagCache,
} = require("../safety-flag");

test.beforeEach(() => _resetSafetyFlagCache());

test("enabled when the parameter is true", async () => {
  assert.equal(await safetyFunctionsEnabled(async () => true), true);
});

test("disabled only when the parameter is explicitly false", async () => {
  assert.equal(await safetyFunctionsEnabled(async () => false), false);
});

test("fails open when Remote Config has never been read", async () => {
  const enabled = await safetyFunctionsEnabled(async () => {
    throw new Error("Remote Config is unreachable");
  });
  assert.equal(enabled, true);
});

test("keeps an explicit off while Remote Config is unreachable", async () => {
  let now = 0;
  assert.equal(await safetyFunctionsEnabled(async () => false, now), false);

  now += SAFETY_FLAG_CACHE_TTL_MS + 1;
  const enabled = await safetyFunctionsEnabled(async () => {
    throw new Error("Remote Config is unreachable");
  }, now);
  assert.equal(enabled, false);
});

test("turns back on once the parameter flips", async () => {
  let value = false;
  let now = 0;
  assert.equal(await safetyFunctionsEnabled(async () => value, now), false);

  value = true;
  now += SAFETY_FLAG_CACHE_TTL_MS + 1;
  assert.equal(await safetyFunctionsEnabled(async () => value, now), true);
});

test("caches the value instead of reading on every call", async () => {
  let reads = 0;
  const load = async () => {
    reads += 1;
    return true;
  };
  const now = 1_000;
  await safetyFunctionsEnabled(load, now);
  await safetyFunctionsEnabled(load, now + SAFETY_FLAG_CACHE_TTL_MS - 1);
  assert.equal(reads, 1);

  await safetyFunctionsEnabled(load, now + SAFETY_FLAG_CACHE_TTL_MS);
  assert.equal(reads, 2);
});

test("is independent of the budget kill switch", async () => {
  const { functionsEnabled, _resetCache } = require("../killswitch");
  _resetCache();
  const budgetTripped = {
    collection: () => ({
      doc: () => ({ get: async () => ({ exists: true, data: () => ({ enabled: false }) }) }),
    }),
  };
  assert.equal(await functionsEnabled(budgetTripped), false);
  assert.equal(await safetyFunctionsEnabled(async () => true), true);
});

test("the Remote Config loader passes a true default and reads the parameter", async () => {
  let options;
  const fakeRemoteConfig = {
    getServerTemplate: async (opts) => {
      options = opts;
      return { evaluate: () => ({ getBoolean: (key) => (key === SAFETY_FLAG_PARAM ? false : true) }) };
    },
  };
  const value = await remoteConfigFlagLoader(fakeRemoteConfig)();
  assert.deepEqual(options, { defaultConfig: { [SAFETY_FLAG_PARAM]: true } });
  assert.equal(value, false);
});
