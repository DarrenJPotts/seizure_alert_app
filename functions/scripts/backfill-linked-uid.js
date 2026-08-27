/**
 * One-off backfill for `contacts.linkedUid`.
 *
 * `linkedUid` is now the authorization key for every cross-user read — see
 * `findLinkedContacts` in `functions/index.js`. It replaced matching on the
 * caller's `users/{uid}.phone`, which is self-asserted (signup is
 * email/password, there is no phone verification anywhere in the app) and
 * writable by its own owner: anyone could set their phone to a number they
 * knew was on somebody's contact list and read that person's live SOS
 * location, medical ID and emergency note.
 *
 * From now on `respondToInvite` stamps `linkedUid` when a recipient accepts.
 * Contacts accepted *before* that change have no such field, so until this
 * script runs those caregivers see an empty watch list and get
 * permission-denied on alert detail. **Deploy the functions, then run this
 * immediately.** Failing closed is the correct direction for the bug being
 * fixed, but it is still a real outage for existing caregivers.
 *
 * Two sources are used, in order of confidence:
 *
 *   1. `invites` with `status == "accepted"` — an explicit, verified consent
 *      record linking `contactId` to `recipientUid`. Always preferred.
 *   2. For non-pending contacts with no accepted invite (circles built before
 *      the invite flow existed in Feature 23), the phone match that used to
 *      grant access at request time. This reproduces the *existing* trust
 *      relationship rather than widening it — it grants nothing that was not
 *      already reachable — but it inherits the weakness of phone matching, so
 *      it is reported separately and skipped entirely under --strict.
 *
 * Usage (dry run first):
 *   GOOGLE_APPLICATION_CREDENTIALS=./service-account.json node scripts/backfill-linked-uid.js
 *   GOOGLE_APPLICATION_CREDENTIALS=./service-account.json node scripts/backfill-linked-uid.js --apply
 *   ... --apply --strict     # invite-derived links only
 */

const { initializeApp, applicationDefault } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { normalizePhone } = require("../phone");

const APPLY = process.argv.includes("--apply");
const STRICT = process.argv.includes("--strict");
const BATCH_LIMIT = 400;

initializeApp({ credential: applicationDefault() });
const db = getFirestore();

async function main() {
  const [contactsSnap, invitesSnap, usersSnap] = await Promise.all([
    db.collection("contacts").get(),
    db.collection("invites").where("status", "==", "accepted").get(),
    db.collection("users").get(),
  ]);

  // contactId -> recipientUid, from explicit accepted invites.
  const inviteLinks = new Map();
  invitesSnap.docs.forEach((doc) => {
    const invite = doc.data();
    if (invite.contactId && invite.recipientUid) {
      inviteLinks.set(invite.contactId, invite.recipientUid);
    }
  });

  // normalised phone -> uid, for the legacy fallback.
  const usersByPhone = new Map();
  usersSnap.docs.forEach((doc) => {
    const normalized =
      doc.data().phoneNormalized || normalizePhone(doc.data().phone);
    if (normalized && !usersByPhone.has(normalized)) {
      usersByPhone.set(normalized, doc.id);
    }
  });

  const planned = [];
  const stats = {
    fromInvite: 0,
    fromPhone: 0,
    alreadyLinked: 0,
    pending: 0,
    unresolved: 0,
  };

  for (const doc of contactsSnap.docs) {
    const contact = doc.data();

    if (contact.linkedUid) {
      stats.alreadyLinked += 1;
      continue;
    }
    if (contact.status === "pending") {
      // No consent yet; respondToInvite will stamp it on accept.
      stats.pending += 1;
      continue;
    }

    let linkedUid = inviteLinks.get(doc.id);
    let source = "invite";

    if (!linkedUid && !STRICT) {
      const normalized = contact.phoneNormalized || normalizePhone(contact.phone);
      linkedUid = normalized ? usersByPhone.get(normalized) : undefined;
      source = "phone";
    }

    // A contact pointing at the owner's own account would let someone watch
    // themselves and pollute their own watch list.
    if (linkedUid && linkedUid === contact.userId) linkedUid = undefined;

    if (!linkedUid) {
      // Expected and fine: most contacts are people with no account at all.
      // They receive SMS/push via notifyContacts and never call the
      // caregiver functions, so they need no linkedUid.
      stats.unresolved += 1;
      continue;
    }

    source === "invite" ? (stats.fromInvite += 1) : (stats.fromPhone += 1);
    planned.push({ ref: doc.ref, linkedUid, source, contactId: doc.id });
  }

  console.log(`contacts scanned:        ${contactsSnap.size}`);
  console.log(`  already linked:        ${stats.alreadyLinked}`);
  console.log(`  pending (skipped):     ${stats.pending}`);
  console.log(`  no account (skipped):  ${stats.unresolved}`);
  console.log(`  link via invite:       ${stats.fromInvite}`);
  console.log(
    `  link via phone:        ${stats.fromPhone}${STRICT ? " (disabled by --strict)" : ""}`
  );
  console.log(`writes planned:          ${planned.length}`);

  if (!APPLY) {
    console.log("\nDry run. Re-run with --apply to write.");
    planned.slice(0, 20).forEach((p) => {
      console.log(`  ${p.contactId} -> ${p.linkedUid} (${p.source})`);
    });
    return;
  }

  for (let i = 0; i < planned.length; i += BATCH_LIMIT) {
    const batch = db.batch();
    planned.slice(i, i + BATCH_LIMIT).forEach((p) => {
      batch.update(p.ref, { linkedUid: p.linkedUid });
    });
    await batch.commit();
    console.log(`committed ${Math.min(i + BATCH_LIMIT, planned.length)}/${planned.length}`);
  }

  console.log("Done.");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
