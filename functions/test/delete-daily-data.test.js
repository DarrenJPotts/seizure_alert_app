const { test } = require('node:test');
const assert = require('node:assert/strict');
const { deleteDailyData } = require('../delete-daily-data');
function fixture(count, failOnce = false) {
  const remaining = new Set(Array.from({length: count}, (_, i) => i));
  const events = []; let fail = failOnce;
  const ref = {
    async delete() { events.push('profile'); },
    collection(name) { assert.equal(name, 'dailyLogs'); return { limit(size) { assert.ok(size <= 400); return { async get() { const docs = [...remaining].slice(0,size).map(ref => ({ref})); return {docs, empty: !docs.length}; } }; } }; },
  };
  const db = { batch() { const ids = []; return { delete(id) { ids.push(id); }, async commit() { if (fail) { fail = false; throw new Error('retry'); } events.push(ids.length); ids.forEach(id => remaining.delete(id)); } }; } };
  return {db, ref, remaining, events};
}
test('profile is removed before daily records are deleted in bounded batches', async () => {
  const f = fixture(905);
  assert.equal(await deleteDailyData(f.db,f.ref),905);
  assert.deepEqual(f.events,['profile',400,400,105]); assert.equal(f.remaining.size,0);
});
test('cleanup safely retries after a failed batch and handles empty histories', async () => {
  const f = fixture(3,true);
  await assert.rejects(deleteDailyData(f.db,f.ref)); assert.equal(f.remaining.size,3);
  assert.equal(await deleteDailyData(f.db,f.ref),3);
  assert.equal(await deleteDailyData(f.db,f.ref),0);
});
