/**
 * Kill switch for every Cloud Function in this project.
 *
 * A single Firestore doc, `system/functionsConfig`, that every exported
 * function checks before doing any billable work — a query, a transaction, an
 * FCM send. Setting `enabled: false` on that doc from the Firebase Console
 * (Firestore → Data) stops all of it within CACHE_TTL_MS, with no redeploy.
 * firestore.rules denies the doc to clients outright; only the Admin SDK
 * (these functions, or a human in the console) can touch it.
 *
 * The check is cached per warm instance rather than read on every invocation.
 * A cost or abuse spike is exactly the scenario this needs to survive without
 * itself becoming a second source of unbounded reads.
 *
 * Fails open: a missing doc, or a Firestore read that itself errors, is
 * treated as enabled. This is a switch a human flips on purpose — it must
 * never go off by itself because of a transient read failure. Only an
 * explicit `enabled: false` turns functions off.
 */

const CACHE_TTL_MS = 30 * 1000;

let cached = { enabled: true, fetchedAt: -Infinity };

function _resetCache() {
  cached = { enabled: true, fetchedAt: -Infinity };
}

async function functionsEnabled(db, now = Date.now()) {
  if (now - cached.fetchedAt < CACHE_TTL_MS) return cached.enabled;

  try {
    const snap = await db.collection("system").doc("functionsConfig").get();
    const enabled = !(snap.exists && snap.data().enabled === false);
    cached = { enabled, fetchedAt: now };
    return enabled;
  } catch (e) {
    console.error("Kill switch check failed; failing open (functions stay enabled).", e);
    cached = { enabled: true, fetchedAt: now };
    return true;
  }
}

module.exports = { functionsEnabled, CACHE_TTL_MS, _resetCache };
