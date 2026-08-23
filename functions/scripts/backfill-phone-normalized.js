/**
 * One-off backfill for the two denormalised fields added alongside the
 * phone-matching and security-rules fixes:
 *
 *   - `phoneNormalized` on `users` and `contacts`, so cross-user lookups stop
 *     depending on how the number happened to be typed.
 *   - `alertOwnerId` on `alert_responses`, which the tightened rules in
 *     `firestore.rules` now require in order to grant the patient read access
 *     to responses on their own alerts.
 *
 * Until this has run, the Cloud Functions fall back to matching on the raw
 * `phone` field, so the app keeps working on un-backfilled data — but that
 * fallback is exactly the broken exact-match behaviour we're fixing, so run
 * this as soon as the new client is deployed.
 *
 * Usage (dry run first):
 *   GOOGLE_APPLICATION_CREDENTIALS=./service-account.json node scripts/backfill-phone-normalized.js
 *   GOOGLE_APPLICATION_CREDENTIALS=./service-account.json node scripts/backfill-phone-normalized.js --apply
 */

const { initializeApp, applicationDefault } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { normalizePhone } = require("../phone");

const APPLY = process.argv.includes("--apply");
const BATCH_LIMIT = 400;

initializeApp({ credential: applicationDefault() });
const db = getFirestore();

async function backfill(collection) {
  const snap = await db.collection(collection).get();

  let updated = 0;
  let skipped = 0;
  let unparseable = 0;
  let batch = db.batch();
  let batched = 0;

  for (const doc of snap.docs) {
    const data = doc.data();
    const normalized = normalizePhone(data.phone);

    if (!normalized) {
      // No number, or nothing that resolves to one. Left alone deliberately:
      // writing null would be indistinguishable from "not yet backfilled".
      if (data.phone) {
        unparseable++;
        console.warn(`  ${collection}/${doc.id}: cannot parse "${data.phone}"`);
      }
      continue;
    }

    if (data.phoneNormalized === normalized) {
      skipped++;
      continue;
    }

    updated++;
    if (!APPLY) continue;

    batch.update(doc.ref, { phoneNormalized: normalized });
    batched++;

    if (batched >= BATCH_LIMIT) {
      await batch.commit();
      batch = db.batch();
      batched = 0;
    }
  }

  if (APPLY && batched > 0) await batch.commit();

  console.log(
    `${collection}: ${snap.size} docs — ${updated} ${APPLY ? "updated" : "would update"}, ` +
      `${skipped} already correct, ${unparseable} unparseable`
  );

  return unparseable;
}

/**
 * Stamps `alertOwnerId` onto responses written before that field existed.
 * Without it the tightened alert_responses read rule denies the patient
 * access to their own historical status boards.
 */
async function backfillResponseOwners() {
  const snap = await db.collection("alert_responses").get();

  // Responses cluster onto a handful of alerts, so resolve each alert once.
  const ownerByAlertId = new Map();
  let updated = 0;
  let skipped = 0;
  let orphaned = 0;
  let batch = db.batch();
  let batched = 0;

  for (const doc of snap.docs) {
    const data = doc.data();

    if (data.alertOwnerId) {
      skipped++;
      continue;
    }

    if (!ownerByAlertId.has(data.alertId)) {
      const alertDoc = await db.collection("alerts").doc(data.alertId).get();
      ownerByAlertId.set(
        data.alertId,
        alertDoc.exists ? alertDoc.data().userId ?? null : null
      );
    }

    const ownerId = ownerByAlertId.get(data.alertId);
    if (!ownerId) {
      orphaned++;
      console.warn(
        `  alert_responses/${doc.id}: alert ${data.alertId} is missing; ` +
          `cannot resolve an owner`
      );
      continue;
    }

    updated++;
    if (!APPLY) continue;

    batch.update(doc.ref, { alertOwnerId: ownerId });
    batched++;

    if (batched >= BATCH_LIMIT) {
      await batch.commit();
      batch = db.batch();
      batched = 0;
    }
  }

  if (APPLY && batched > 0) await batch.commit();

  console.log(
    `alert_responses: ${snap.size} docs - ${updated} ${APPLY ? "updated" : "would update"}, ` +
      `${skipped} already correct, ${orphaned} orphaned`
  );
}

(async () => {
  console.log(APPLY ? "Applying backfill…" : "Dry run — pass --apply to write.\n");

  const unparseable =
    (await backfill("users")) + (await backfill("contacts"));

  await backfillResponseOwners();

  if (unparseable > 0) {
    console.warn(
      `\n${unparseable} document(s) have a phone value that could not be parsed. ` +
        `Those users/contacts will not be reachable by alerts until corrected.`
    );
  }

  process.exit(0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
