const test = require("node:test");
const assert = require("node:assert/strict");

const { functionsEnabled, CACHE_TTL_MS, _resetCache } = require("../killswitch");

function fakeDb(impl) {
  return {
    collection(name) {
      assert.equal(name, "system");
      return {
        doc(id) {
          assert.equal(id, "functionsConfig");
          return { get: impl };
        },
      };
    },
  };
}

test.beforeEach(() => _resetCache());

test("enabled when the config doc does not exist", async () => {
  const db = fakeDb(async () => ({ exists: false }));
  assert.equal(await functionsEnabled(db), true);
});

test("enabled when the doc exists but says nothing", async () => {
  const db = fakeDb(async () => ({ exists: true, data: () => ({}) }));
  assert.equal(await functionsEnabled(db), true);
});

test("disabled only on an explicit enabled: false", async () => {
  const db = fakeDb(async () => ({ exists: true, data: () => ({ enabled: false }) }));
  assert.equal(await functionsEnabled(db), false);
});

test("enabled again once the doc flips back", async () => {
  let docEnabled = true;
  const db = fakeDb(async () => ({ exists: true, data: () => ({ enabled: docEnabled }) }));

  let now = 0;
  assert.equal(await functionsEnabled(db, now), true);

  docEnabled = false;
  now += CACHE_TTL_MS + 1; // past the cache window, so this read is live
  assert.equal(await functionsEnabled(db, now), false);

  docEnabled = true;
  now += CACHE_TTL_MS + 1;
  assert.equal(await functionsEnabled(db, now), true);
});

test("fails open when the read itself throws", async () => {
  const db = fakeDb(async () => {
    throw new Error("Firestore is unreachable");
  });
  assert.equal(await functionsEnabled(db), true);
});

test("caches the result instead of reading on every call", async () => {
  let reads = 0;
  const db = fakeDb(async () => {
    reads += 1;
    return { exists: true, data: () => ({ enabled: false }) };
  });

  const now = 1_000;
  await functionsEnabled(db, now);
  await functionsEnabled(db, now + 1);
  await functionsEnabled(db, now + CACHE_TTL_MS - 1);
  assert.equal(reads, 1, "still inside the TTL window");

  await functionsEnabled(db, now + CACHE_TTL_MS);
  assert.equal(reads, 2, "TTL elapsed, so this call reads again");
});
