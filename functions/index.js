const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onMessagePublished } = require("firebase-functions/v2/pubsub");
const { setGlobalOptions } = require("firebase-functions/v2");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { normalizePhone } = require("./phone");
const { daysSince, isEscalationStale } = require("./time");
const { functionsEnabled } = require("./killswitch");

setGlobalOptions({ maxInstances: 5 });

// Callable endpoints reject requests without a valid Firebase App Check
// attestation. The mobile client initializes App Check before any Firebase
// services are used.
const CALLABLE_OPTIONS = { enforceAppCheck: true };

const BILLING_BUDGET_TOPIC = "seizure-alert-budget-alerts";
const BILLING_ACCOUNT_ID = "017AAE-400AB6-98B366";
const BILLING_BUDGET_ID = "2a77275e-d5c9-46dc-85e6-9c7a50113786";

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

/**
 * Stop function work when the $10 monthly budget's actual spend reaches 100%.
 * The kill switch remains off until an operator manually re-enables it in
 * Firestore. Billing notifications are delayed/estimated, so this is a safety
 * brake, not a guaranteed hard spending ceiling.
 */
exports.disableFunctionsAtBudget = onMessagePublished(
  { topic: BILLING_BUDGET_TOPIC, retry: true },
  async (event) => {
    const message = event.data?.message;
    const attributes = message?.attributes || {};
    const alert = message?.json;

    if (
      attributes.schemaVersion !== "1.0" ||
      attributes.billingAccountId !== BILLING_ACCOUNT_ID ||
      attributes.budgetId !== BILLING_BUDGET_ID
    ) {
      console.info("Ignoring budget notification for an unrelated budget.");
      return;
    }

    if (!alert || typeof alert !== "object") {
      throw new Error("Budget notification did not contain a JSON payload.");
    }

    const thresholdExceeded = Number(alert.alertThresholdExceeded);
    const costAmount = Number(alert.costAmount);
    const budgetAmount = Number(alert.budgetAmount);
    if (
      !Number.isFinite(thresholdExceeded) ||
      thresholdExceeded < 1 ||
      !Number.isFinite(costAmount) ||
      !Number.isFinite(budgetAmount) ||
      costAmount < budgetAmount
    ) {
      console.info("Budget notification is below the actual-spend cap.");
      return;
    }

    await db.collection("system").doc("functionsConfig").set(
      {
        enabled: false,
        reason: "monthly_budget_reached",
        budgetId: BILLING_BUDGET_ID,
        costAmount,
        budgetAmount,
        currencyCode: alert.currencyCode || null,
        triggeredAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    console.error(
      `Function kill switch enabled: budget reached ${costAmount} ${alert.currencyCode || ""} / ${budgetAmount}.`
    );
  }
);

async function findUserByPhone(phone) {
  const normalized = normalizePhone(phone);

  if (normalized) {
    const snap = await db
      .collection("users")
      .where("phoneNormalized", "==", normalized)
      .limit(1)
      .get();
    if (!snap.empty) return snap.docs[0];
  }

  if (!phone) return null;

  const legacySnap = await db
    .collection("users")
    .where("phone", "==", phone)
    .limit(1)
    .get();
  return legacySnap.empty ? null : legacySnap.docs[0];
}

async function findLinkedContacts(uid, extraWhere = []) {
  if (!uid) return [];
  let query = db.collection("contacts").where("linkedUid", "==", uid);
  for (const [f, op, v] of extraWhere) query = query.where(f, op, v);
  const snap = await query.get();
  return snap.docs.filter((doc) => doc.data().status !== "pending");
}

async function enforceRateLimit(uid, action, max, windowMs) {
  const ref = db.collection("rate_limits").doc(`${uid}_${action}`);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const now = Date.now();
    const data = snap.exists ? snap.data() : { count: 0, windowStart: now };
    const expired = now - data.windowStart > windowMs;
    const count = expired ? 1 : data.count + 1;
    if (count > max) {
      throw new HttpsError(
        "resource-exhausted",
        "Too many requests. Try again shortly."
      );
    }
    tx.set(ref, { count, windowStart: expired ? now : data.windowStart });
  });
}

function getCreatedCopy(alertType, userName) {
  switch (alertType) {
    case "sos":
      return {
        title: "SOS Alert",
        body: `${userName} has sent an emergency SOS. Check on them immediately.`,
      };
    case "headsUp":
      return {
        title: "Heads Up",
        body: `${userName} is feeling off and will check in soon. Keep an eye out.`,
      };
    case "headsUpExpired":
      return {
        title: "Check-in Missed",
        body: `${userName} missed their check-in window. Please reach out.`,
      };
    default:
      return null;
  }
}

function getCancelledCopy(alertType, userName) {
  switch (alertType) {
    case "sos":
      return {
        title: "SOS Cancelled",
        body: `${userName} has cancelled their SOS alert. They are okay.`,
      };
    case "headsUp":
      return {
        title: "Heads Up Cancelled",
        body: `${userName} has cancelled their Heads Up.`,
      };
    default:
      return null;
  }
}

function buildMessage({ token, title, body, alertId, alertType, alertStatus, userId }) {
  return {
    token,
    notification: { title, body },
    data: {
      alertId: String(alertId),
      alertType: String(alertType),
      alertStatus: String(alertStatus),
      userId: String(userId),
    },
    android: {
      priority: "high",
      notification: { sound: "default" },
    },
    apns: {
      payload: {
        aps: { sound: "default", contentAvailable: true },
      },
    },
  };
}

function buildInviteMessage({ token, title, body, inviteId, kind }) {
  return {
    token,
    notification: { title, body },
    data: {
      type: kind,
      inviteId: String(inviteId),
    },
    android: {
      priority: "high",
      notification: { sound: "default" },
    },
    apns: {
      payload: {
        aps: { sound: "default", contentAvailable: true },
      },
    },
  };
}

async function notifyContacts(alertUserId, alert, copy) {
  const contactsSnap = await db
    .collection("contacts")
    .where("userId", "==", alertUserId)
    .where("notifyViaPush", "==", true)
    .get();

  if (contactsSnap.empty) {
    console.log(`No push-enabled contacts for user ${alertUserId}.`);
    return;
  }

  const sendPromises = contactsSnap.docs.map(async (contactDoc) => {
    const contact = contactDoc.data();
    const linkedUid = contact.linkedUid;

if (contact.status === "pending" || typeof linkedUid !== "string" || !linkedUid) {
      console.log(`Contact ${contactDoc.id} is not linked; skipping push.`);
      return;
    }

    const userDoc = await db.collection("users").doc(linkedUid).get();
    if (!userDoc.exists) {
      console.log(`Contact ${contactDoc.id} has no matching account.`);
      return;
    }

    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) {
      console.log(`User ${userDoc.id} (contact ${contactDoc.id}) has no fcmToken.`);
      return;
    }

    const message = buildMessage({
      token: fcmToken,
      title: copy.title,
      body: copy.body,
      alertId: alert.id,
      alertType: alert.type,
      alertStatus: alert.status,
      userId: alertUserId,
    });

    const response = await messaging.send(message);
    console.log(`Notified contact ${contactDoc.id}: ${response}`);
  });

  const results = await Promise.allSettled(sendPromises);
  results.forEach((result, i) => {
    if (result.status === "rejected") {
      console.error(`Failed to notify contact ${i}:`, result.reason);
    }
  });
}

exports.onAlertCreated = onDocumentCreated("alerts/{alertId}", async (event) => {
  if (!(await functionsEnabled(db))) {
    console.warn("Kill switch is on; skipping onAlertCreated.");
    return;
  }

  const alert = event.data?.data();
  if (!alert || alert.status !== "sent") return;

  const alertUserId = alert.userId;
  if (!alertUserId) return;

  const userDoc = await db.collection("users").doc(alertUserId).get();
  const userName = userDoc.exists ? (userDoc.data().displayName || "Someone") : "Someone";

  const copy = getCreatedCopy(alert.type, userName);
  if (!copy) return;

  await notifyContacts(alertUserId, alert, copy);
});

exports.onAlertUpdated = onDocumentUpdated("alerts/{alertId}", async (event) => {
  if (!(await functionsEnabled(db))) {
    console.warn("Kill switch is on; skipping onAlertUpdated.");
    return;
  }

  const before = event.data?.before?.data();
  const after = event.data?.after?.data();

  if (!before || !after) return;
  if (before.status === "cancelled" || after.status !== "cancelled") return;

  const alertUserId = after.userId;
  if (!alertUserId) return;

  const userDoc = await db.collection("users").doc(alertUserId).get();
  const userName = userDoc.exists ? (userDoc.data().displayName || "Someone") : "Someone";

  const copy = getCancelledCopy(after.type, userName);
  if (!copy) return;

  await notifyContacts(alertUserId, after, copy);
});

// ---------------------------------------------------------------------------
//
// The client also counts down and escalates locally, but only while the app
// is alive. A Heads Up exists precisely for the case where the user goes
// quiet — phone dead, app killed by the OS, mid-seizure — so the client can
// never be the thing that guarantees the escalation fires. This sweep is that
// guarantee; the client path is now just a fast local path.
//
// Both paths write the alert under the same deterministic id, so whichever
// gets there first wins and the contact circle is notified exactly once.
// ---------------------------------------------------------------------------

const HEADS_UP_SWEEP_LIMIT = 200;

// How late an expiry may be and still be worth telling anyone about.
//
// The sweep runs every minute, so normal lateness is under 60s. Anything much
// older than that means the sweep itself was broken — as it was for ~3 days
// when the `headsUp (status, expiresAtMs)` composite index had been declared in
// firestore.indexes.json but never deployed, so every run threw
// FAILED_PRECONDITION.
//
// Without this guard, the first successful run after that fix escalates the
// entire backlog at once: up to 200 "Check-in Missed" pushes for windows that
// closed days ago. That is not a late alert, it is a false alarm — and a
// caregiver who gets a handful of those learns to disregard the one channel
// this app exists to keep credible.
//
// An hour is generous enough to escalate through any realistic transient
// outage (a deploy, a brief incident) while suppressing a stale backlog.
// Suppressed windows are still closed, and logged at warn so the backlog is
// visible rather than silently dropped.
const HEADS_UP_ESCALATION_GRACE_MS = 60 * 60 * 1000;

exports.expireHeadsUpWindows = onSchedule(
  { schedule: "every 1 minutes", timeoutSeconds: 120 },
  async () => {
    if (!(await functionsEnabled(db))) {
      console.warn("Kill switch is on; skipping expireHeadsUpWindows.");
      return;
    }

    const nowMs = Date.now();

    const dueSnap = await db
      .collection("headsUp")
      .where("status", "==", "active")
      .where("expiresAtMs", "<=", nowMs)
      .limit(HEADS_UP_SWEEP_LIMIT)
      .get();

    if (dueSnap.empty) return;

    console.log(`Expiring ${dueSnap.size} Heads Up window(s).`);

    const results = await Promise.allSettled(
      dueSnap.docs.map((doc) => expireOneHeadsUp(doc, nowMs))
    );

    let suppressed = 0;
    results.forEach((result, i) => {
      if (result.status === "rejected") {
        console.error(`Failed to expire ${dueSnap.docs[i].id}:`, result.reason);
        return;
      }
      if (result.value?.suppressed) suppressed += 1;
    });

    if (suppressed > 0) {
      console.warn(
        `Closed ${suppressed} Heads Up window(s) without notifying anyone: ` +
          `they expired more than ${HEADS_UP_ESCALATION_GRACE_MS / 60000} minutes ` +
          `ago, so an escalation now would be a false alarm. A non-zero count ` +
          `here means this sweep was not running when it should have been.`
      );
    }

    if (dueSnap.size === HEADS_UP_SWEEP_LIMIT) {
      console.warn(
        `Sweep hit its ${HEADS_UP_SWEEP_LIMIT}-document limit; the remainder ` +
          `will be picked up on the next run.`
      );
    }
  }
);

async function expireOneHeadsUp(doc, nowMs) {
  const headsUp = doc.data();
  const alertId = `${doc.id}_expired`;
  const alertRef = db.collection("alerts").doc(alertId);

  // Too late to be worth an alert — close the window and say nothing. Done
  // before the origin-alert read below, so a large backlog costs one write per
  // document rather than a read, a transaction and a push.
  const lateBy = nowMs - (headsUp.expiresAtMs ?? nowMs);
  if (isEscalationStale(headsUp.expiresAtMs, nowMs, HEADS_UP_ESCALATION_GRACE_MS)) {
    await doc.ref.update({ status: "expired" });
    return { suppressed: true, lateBy };
  }

  // Carry the last known position across from the Heads Up's original alert,
  // and do it *before* creating the expiry alert — creating it is what fires
  // onAlertCreated, so anything added afterwards could be missed by a
  // caregiver who opens the notification immediately. Without this the most
  // urgent alert type in the app — a missed check-in — would reach the
  // contact circle with no location at all.
  const originAlert = await db.collection("alerts").doc(`${doc.id}_alert`).get();
  const origin = originAlert.exists ? originAlert.data() : {};
  const hasPosition = origin.latitude != null && origin.longitude != null;

await db.runTransaction(async (tx) => {
    const [freshHeadsUp, existingAlert] = await Promise.all([
      tx.get(doc.ref),
      tx.get(alertRef),
    ]);

if (!freshHeadsUp.exists || freshHeadsUp.data().status !== "active") {
      return;
    }

    tx.update(doc.ref, { status: "expired" });

if (existingAlert.exists) return;

    tx.set(alertRef, {
      id: alertId,
      userId: headsUp.userId,
      type: "headsUpExpired",
      status: "sent",
      latitude: hasPosition ? origin.latitude : null,
      longitude: hasPosition ? origin.longitude : null,
      locationLabel: hasPosition ? origin.locationLabel ?? null : null,
      message: headsUp.note ?? null,
      createdAt: new Date(nowMs).toISOString(),
      resolvedAt: null,
    });
  });

  return { suppressed: false, lateBy };
}

async function latestSeizureLog(ownerId) {
  const snap = await db
    .collection("seizureLogs")
    .where("userId", "==", ownerId)
    .orderBy("occurredAt", "desc")
    .limit(1)
    .get();
  return snap.empty ? null : snap.docs[0].data();
}

// ---------------------------------------------------------------------------
// phone number as an emergency contact, and report their current status.
//
// This and getAlertDetail previously ran with `minInstances: 1` to avoid cold
// starts. A reserved Cloud Run instance bills for CPU and memory every second
// it is alive whether or not anything calls it, so the two of them cost
// roughly $5/month at zero traffic — which on this project was the entire
// monthly budget, spent while the app sat idle. Both now scale to zero and
// pay a 1-3s cold start on first call instead.
//
// The parallelised reads below still matter: they were a separate fix, and
// they cut the warm-path latency that the cold start now adds to.
// ---------------------------------------------------------------------------

exports.getPeopleIWatch = onCall(CALLABLE_OPTIONS, async (request) => {
  if (!(await functionsEnabled(db))) {
    throw new HttpsError("unavailable", "This feature is temporarily disabled.");
  }

  const callerUid = request.auth?.uid;
  if (!callerUid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  await enforceRateLimit(callerUid, "watchList", 30, 60 * 1000);

  const contactDocs = await findLinkedContacts(callerUid);
  if (contactDocs.length === 0) {
    return { people: [], recentActivity: [] };
  }

  const people = await Promise.all(
    contactDocs.map(async (contactDoc) => {
      const contact = contactDoc.data();
      const ownerId = contact.userId;
      if (!ownerId) return null;

      // These reads are independent of each other, so fire them together
      // instead of paying a round trip each — this was previously the main
      // per-person latency cost of the whole callable.
      //
      // recentAlertsSnap is deliberately separate from sosSnap rather than
      // being derived from it. A person with an unresolved SOS and five newer
      // alerts on top would drop out of a "most recent 5" window, and the
      // watch list silently failing to show a live SOS is the one failure
      // this screen must not have. One extra read buys that guarantee.
      const [ownerDoc, sosSnap, headsUpSnap, recentAlertsSnap, lastLog] =
        await Promise.all([
          db.collection("users").doc(ownerId).get(),
          db
            .collection("alerts")
            .where("userId", "==", ownerId)
            .where("status", "==", "sent")
            .limit(1)
            .get(),
          db
            .collection("headsUp")
            .where("userId", "==", ownerId)
            .where("status", "==", "active")
            .limit(1)
            .get(),
          db
            .collection("alerts")
            .where("userId", "==", ownerId)
            .orderBy("createdAt", "desc")
            .limit(5)
            .get(),
          latestSeizureLog(ownerId),
        ]);

      const ownerData = ownerDoc.exists ? ownerDoc.data() : {};
      const ownerName = ownerData.displayName || "Someone";
      const ownerPhone = ownerData.phone || null;

      let status = "monitoring";
      let activeAlertId = null;
      let headsUpNote = null;
      let headsUpAt = null;

      if (!sosSnap.empty) {
        status = "sos";
        activeAlertId = sosSnap.docs[0].id;
      } else if (!headsUpSnap.empty) {
        status = "headsUp";
        const headsUp = headsUpSnap.docs[0].data();
        headsUpNote = headsUp.note || null;
        headsUpAt = headsUp.createdAt || null;
      }

      const lastAlert = recentAlertsSnap.empty
        ? null
        : recentAlertsSnap.docs[0].data();

const activity = recentAlertsSnap.docs.map((doc) => {
        const alert = doc.data();
        return {
          personName: ownerName,
          kind: alert.type || "sos",
          at: alert.createdAt || null,
        };
      });

      return {
        ownerId,
        ownerName,
        ownerPhone,
        contactId: contactDoc.id,
        status,
        activeAlertId,
        headsUpNote,
        headsUpAt,
        lastSeizureAt: lastLog?.occurredAt || null,
        daysSinceLastSeizure: daysSince(lastLog?.occurredAt),
        lastAlertAt: lastAlert?.createdAt || null,
        activity,
      };
    })
  );

  const found = people.filter(Boolean);

const recentActivity = found
    .flatMap((person) => person.activity)
    .filter((event) => event.at)
    .sort((a, b) => (a.at < b.at ? 1 : a.at > b.at ? -1 : 0))
    .slice(0, 10);

found.forEach((person) => delete person.activity);

  return { people: found, recentActivity };
});

exports.getAlertDetail = onCall(CALLABLE_OPTIONS, async (request) => {
  if (!(await functionsEnabled(db))) {
    throw new HttpsError("unavailable", "This feature is temporarily disabled.");
  }

  const callerUid = request.auth?.uid;
  if (!callerUid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  await enforceRateLimit(callerUid, "alertDetail", 30, 60 * 1000);

  const alertId = request.data?.alertId;
  if (!alertId) {
    throw new HttpsError("invalid-argument", "alertId is required.");
  }

  const alertDoc = await db.collection("alerts").doc(alertId).get();
  if (!alertDoc.exists) {
    throw new HttpsError("not-found", "Alert not found.");
  }
  const alertUserId = alertDoc.data().userId;

const [ownerDoc, contactDocs] = await Promise.all([
    db.collection("users").doc(alertUserId).get(),
    findLinkedContacts(callerUid, [["userId", "==", alertUserId]]),
  ]);
  const owner = ownerDoc.exists ? ownerDoc.data() : {};

  const contactDoc = contactDocs[0];
  if (!contactDoc) {
    throw new HttpsError(
      "permission-denied",
      "You are not listed as a contact for this alert."
    );
  }
  const contact = contactDoc.data();

  // Everything below is authorization-gated on the check above, so it only
  // runs once the caller is known to be one of this person's contacts.
  //
  // The responder roster has to come from here rather than from a client
  // listener: firestore.rules scopes /alert_responses to the responder and
  // the alert owner, and a caregiver is neither of those for *other*
  // caregivers' rows. Widening that rule would expose the roster to anyone
  // who could guess an alert id; the admin SDK reads it safely instead.
  const [responsesSnap, circleSnap, lastLog] = await Promise.all([
    db.collection("alert_responses").where("alertId", "==", alertId).get(),
    db
      .collection("contacts")
      .where("userId", "==", alertUserId)
      .where("notifyViaPush", "==", true)
      .get(),
    latestSeizureLog(alertUserId),
  ]);

  const responders = responsesSnap.docs
    .map((doc) => {
      const response = doc.data();
      return {
        contactId: response.contactId || null,
        contactName: response.contactName || "Someone",
        responderId: response.responderId || null,
        isCaller: response.responderId === callerUid,
        seen: response.seen === true,
        responding: response.responding === true,
        seenAt: response.seenAt || null,
        respondedAt: response.respondedAt || null,
        note: response.note || null,
      };
    })

    .sort((a, b) => Number(b.responding) - Number(a.responding) || Number(b.seen) - Number(a.seen));

  // Who the alert actually went out to — pending invites are skipped by
  // notifyContacts, so they are skipped here too or the count would overstate
  // how many people know.
  const notifiedCount = circleSnap.docs.filter(
    (doc) => doc.data().status !== "pending" && typeof doc.data().linkedUid === "string"
  ).length;

  return {
    alert: { id: alertDoc.id, ...alertDoc.data() },
    ownerProfile: {
      displayName: owner.displayName || "Someone",
      phone: owner.phone || null,
      bloodType: owner.bloodType || null,
      seizureType: owner.seizureType || null,
      emergencyNote: owner.emergencyNote || null,
      medications: Array.isArray(owner.medications) ? owner.medications : [],
      daysSinceLastSeizure: daysSince(lastLog?.occurredAt),
    },
    callerContactId: contactDoc.id,
    callerContactName: contact.name,
    notifiedCount,
    responders,
  };
});

// ---------------------------------------------------------------------------
// registered user, send them an in-app invite instead of relying on the
// SMS/WhatsApp share link. The contact is gated to `status: "pending"` until
// the recipient accepts, so they aren't notified of anything before consenting.
// ---------------------------------------------------------------------------

exports.sendCircleInvite = onCall(CALLABLE_OPTIONS, async (request) => {
  if (!(await functionsEnabled(db))) {
    throw new HttpsError("unavailable", "This feature is temporarily disabled.");
  }

  const callerUid = request.auth?.uid;
  if (!callerUid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  await enforceRateLimit(callerUid, "invite", 10, 60 * 60 * 1000);

  const contactId = request.data?.contactId;
  const phone = request.data?.phone;
  if (!contactId || !phone) {
    throw new HttpsError("invalid-argument", "contactId and phone are required.");
  }

  const contactDoc = await db.collection("contacts").doc(contactId).get();
  if (!contactDoc.exists || contactDoc.data().userId !== callerUid) {
    throw new HttpsError("permission-denied", "Not your contact.");
  }

const contactPhone = contactDoc.data().phone;
  if (
    !contactPhone ||
    normalizePhone(contactPhone) !== normalizePhone(phone)
  ) {
    throw new HttpsError(
      "invalid-argument",
      "That phone number does not match the contact."
    );
  }

  const recipientDoc = await findUserByPhone(contactPhone);

  if (!recipientDoc) {
    return { isRegisteredUser: false };
  }

  const recipientUid = recipientDoc.id;
  if (recipientUid === callerUid) {
    return { isRegisteredUser: false };
  }

  const existingSnap = await db
    .collection("invites")
    .where("senderUid", "==", callerUid)
    .where("recipientUid", "==", recipientUid)
    .where("status", "==", "pending")
    .limit(1)
    .get();

  const callerDoc = await db.collection("users").doc(callerUid).get();
  const senderName = callerDoc.exists ? (callerDoc.data().displayName || "Someone") : "Someone";

  let inviteId;
  if (!existingSnap.empty) {
    inviteId = existingSnap.docs[0].id;
  } else {
    const inviteRef = db.collection("invites").doc();
    inviteId = inviteRef.id;
    await inviteRef.set({
      id: inviteId,
      contactId,
      senderUid: callerUid,
      senderName,
      recipientUid,
      recipientPhone: phone,
      status: "pending",
      createdAt: new Date().toISOString(),
      respondedAt: null,
    });
  }

  await db.collection("contacts").doc(contactId).update({ status: "pending" });

  const fcmToken = recipientDoc.data().fcmToken;
  if (fcmToken) {
    try {
      await messaging.send(
        buildInviteMessage({
          token: fcmToken,
          title: "Circle invite",
          body: `${senderName} wants to add you to their circle.`,
          inviteId,
          kind: "circle_invite",
        })
      );
    } catch (e) {
      console.error("Failed to send invite push:", e);
    }
  }

  return { isRegisteredUser: true, inviteId };
});

// ---------------------------------------------------------------------------
// deletes it. Both mutate a contact doc owned by a different uid, which is
// only safe because this runs under the Admin SDK.
// ---------------------------------------------------------------------------

exports.respondToInvite = onCall(CALLABLE_OPTIONS, async (request) => {
  if (!(await functionsEnabled(db))) {
    throw new HttpsError("unavailable", "This feature is temporarily disabled.");
  }

  const callerUid = request.auth?.uid;
  if (!callerUid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  await enforceRateLimit(callerUid, "inviteResponse", 20, 60 * 60 * 1000);

  const inviteId = request.data?.inviteId;
  const accept = request.data?.accept;
  if (!inviteId || typeof accept !== "boolean") {
    throw new HttpsError("invalid-argument", "inviteId and accept are required.");
  }

  const inviteRef = db.collection("invites").doc(inviteId);
  const inviteDoc = await inviteRef.get();
  if (!inviteDoc.exists) {
    throw new HttpsError("not-found", "Invite not found.");
  }

  const invite = inviteDoc.data();
  if (invite.recipientUid !== callerUid) {
    throw new HttpsError("permission-denied", "This invite is not yours to respond to.");
  }

  if (invite.status !== "pending") {
    return { status: invite.status };
  }

  const newStatus = accept ? "accepted" : "declined";
  await inviteRef.update({ status: newStatus, respondedAt: new Date().toISOString() });

  const contactRef = db.collection("contacts").doc(invite.contactId);
  if (accept) {

await contactRef
      .update({ status: "active", linkedUid: callerUid })
      .catch(() => null);
  } else {
    await contactRef.delete().catch(() => null);
  }

  const senderDoc = await db.collection("users").doc(invite.senderUid).get();
  const fcmToken = senderDoc.exists ? senderDoc.data().fcmToken : null;
  if (fcmToken) {
    const recipientDoc = await db.collection("users").doc(callerUid).get();
    const recipientName = recipientDoc.exists
      ? (recipientDoc.data().displayName || "Your contact")
      : "Your contact";
    try {
      await messaging.send(
        buildInviteMessage({
          token: fcmToken,
          title: accept ? "Invite accepted" : "Invite declined",
          body: accept
            ? `${recipientName} accepted your circle invite.`
            : `${recipientName} declined your circle invite.`,
          inviteId,
          kind: "circle_invite_response",
        })
      );
    } catch (e) {
      console.error("Failed to send invite response push:", e);
    }
  }

  return { status: newStatus };
});

// ---------------------------------------------------------------------------
//
// Exists because the respond screen shows the whole roster: seeing "Sipho V.
// — called, no answer" is only useful if you can do something about it. The
// alternative was for the caregiver to leave the app and phone them, which
// is the thing they are already failing to do.
//
// Authorization mirrors getAlertDetail: the caller must be a non-pending
// contact of the alert's owner. Without that this would be an open push
// endpoint keyed on a guessable alert id.
// ---------------------------------------------------------------------------

exports.nudgeResponder = onCall(CALLABLE_OPTIONS, async (request) => {
  if (!(await functionsEnabled(db))) {
    throw new HttpsError("unavailable", "This feature is temporarily disabled.");
  }

  const callerUid = request.auth?.uid;
  if (!callerUid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const { alertId, targetResponderId } = request.data || {};
  if (!alertId || !targetResponderId) {
    throw new HttpsError(
      "invalid-argument",
      "alertId and targetResponderId are required."
    );
  }
  if (targetResponderId === callerUid) {
    throw new HttpsError("invalid-argument", "You cannot nudge yourself.");
  }

  const alertDoc = await db.collection("alerts").doc(alertId).get();
  if (!alertDoc.exists) {
    throw new HttpsError("not-found", "Alert not found.");
  }
  const alert = alertDoc.data();
  const alertUserId = alert.userId;

  const [callerDoc, ownerDoc, targetDoc, callerContacts, targetContacts] =
    await Promise.all([
      db.collection("users").doc(callerUid).get(),
      db.collection("users").doc(alertUserId).get(),
      db.collection("users").doc(targetResponderId).get(),
      findLinkedContacts(callerUid, [["userId", "==", alertUserId]]),

findLinkedContacts(targetResponderId, [["userId", "==", alertUserId]]),
    ]);

  if (!callerContacts[0]) {
    throw new HttpsError(
      "permission-denied",
      "You are not listed as a contact for this alert."
    );
  }
  if (!targetContacts[0]) {
    throw new HttpsError(
      "permission-denied",
      "That person is not in this circle."
    );
  }

  // This sends a high-priority push with sound. Without a cap, one caregiver
  // can hammer another's phone indefinitely.
  await enforceRateLimit(callerUid, "nudge", 3, 10 * 60 * 1000);

  const fcmToken = targetDoc.exists ? targetDoc.data().fcmToken : null;
  if (!fcmToken) {
    // Not an error the caller can act on, and throwing would make the button
    // look broken. Report it so the UI can say the nudge did not land.
    return { delivered: false, reason: "no-token" };
  }

  const ownerName = ownerDoc.exists
    ? ownerDoc.data().displayName || "Someone"
    : "Someone";
  const callerName = callerDoc.exists
    ? callerDoc.data().displayName || "A caregiver"
    : "A caregiver";

  await messaging.send(
    buildMessage({
      token: fcmToken,
      title: "Response needed",
      body: `${callerName} is asking you to respond to ${ownerName}'s SOS.`,
      alertId,
      alertType: alert.type || "sos",
      alertStatus: alert.status || "sent",
      userId: alertUserId,
    })
  );

  return { delivered: true };
});

// ---------------------------------------------------------------------------
// responding, or records what happened afterwards.
//
// writer was not impersonating another *responder*, but not that they had
// anything to do with the alert: `alertId` and `alertOwnerId` were both
// attacker-supplied strings, and alert ids were wall-clock milliseconds and
// therefore guessable. Anyone who knew a victim's uid could forge

const MAX_RESPONSE_NOTE = 2000;

exports.submitAlertResponse = onCall(CALLABLE_OPTIONS, async (request) => {
  if (!(await functionsEnabled(db))) {
    throw new HttpsError("unavailable", "This feature is temporarily disabled.");
  }

  const callerUid = request.auth?.uid;
  if (!callerUid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  await enforceRateLimit(callerUid, "alertResponse", 60, 60 * 1000);

  const { alertId, responding, note } = request.data || {};
  if (!alertId || typeof alertId !== "string") {
    throw new HttpsError("invalid-argument", "alertId is required.");
  }
  if (note !== undefined && note !== null && typeof note !== "string") {
    throw new HttpsError("invalid-argument", "note must be a string.");
  }
  if (typeof note === "string" && note.length > MAX_RESPONSE_NOTE) {
    throw new HttpsError(
      "invalid-argument",
      `note must be ${MAX_RESPONSE_NOTE} characters or fewer.`
    );
  }

  const alertDoc = await db.collection("alerts").doc(alertId).get();
  if (!alertDoc.exists) {
    throw new HttpsError("not-found", "Alert not found.");
  }
  const alertUserId = alertDoc.data().userId;

  const contactDocs = await findLinkedContacts(callerUid, [
    ["userId", "==", alertUserId],
  ]);
  const contactDoc = contactDocs[0];
  if (!contactDoc) {
    throw new HttpsError(
      "permission-denied",
      "You are not listed as a contact for this alert."
    );
  }

  const now = new Date().toISOString();
  const responseRef = db
    .collection("alert_responses")
    .doc(`${alertId}_${contactDoc.id}`);
  const existing = await responseRef.get();
  const prev = existing.exists ? existing.data() : {};

  // Merge rather than overwrite: opening the screen marks it seen, and a
  // later "on my way" or note must not clear that first timestamp.
  const payload = {
    id: responseRef.id,
    alertId,
    alertOwnerId: alertUserId,
    contactId: contactDoc.id,
    contactName: contactDoc.data().name || "Someone",
    responderId: callerUid,
    seen: true,
    seenAt: prev.seenAt || now,
    responding: responding === true || prev.responding === true,
    respondedAt:
      responding === true ? prev.respondedAt || now : prev.respondedAt || null,
    note: typeof note === "string" && note.trim() ? note.trim() : prev.note || null,
  };

  await responseRef.set(payload, { merge: true });
  return { ok: true };
});

const DELETE_BATCH_LIMIT = 400;

async function deleteDocs(docs) {
  for (let i = 0; i < docs.length; i += DELETE_BATCH_LIMIT) {
    const batch = db.batch();
    docs.slice(i, i + DELETE_BATCH_LIMIT).forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
  }
  return docs.length;
}

async function docsMatchingAny(collection, clauses) {
  const byId = new Map();
  await Promise.all(
    clauses.map(async ([field, value]) => {
      const snap = await db.collection(collection).where(field, "==", value).get();
      snap.docs.forEach((doc) => byId.set(doc.id, doc));
    })
  );
  return [...byId.values()];
}

exports.deleteMyData = onCall(CALLABLE_OPTIONS, async (request) => {
  if (!(await functionsEnabled(db))) {
    throw new HttpsError("unavailable", "This feature is temporarily disabled.");
  }

  const callerUid = request.auth?.uid;
  if (!callerUid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

const [own, responses, invites, rateLimits, linkedContacts] = await Promise.all([
    Promise.all(
      ["contacts", "seizureLogs", "alerts", "headsUp"].map((collection) =>
        db.collection(collection).where("userId", "==", callerUid).get()
      )
    ),
    docsMatchingAny("alert_responses", [
      ["responderId", callerUid],
      ["alertOwnerId", callerUid],
    ]),
    docsMatchingAny("invites", [
      ["senderUid", callerUid],
      ["recipientUid", callerUid],
    ]),
    db.collection("rate_limits").where("__name__", ">=", `${callerUid}_`).where("__name__", "<", `${callerUid}_\uf8ff`).get(),

    db.collection("contacts").where("linkedUid", "==", callerUid).get(),
  ]);

  const deleted = {};
  const ownDocs = own.flatMap((snap) => snap.docs);
  deleted.owned = await deleteDocs(ownDocs);
  deleted.responses = await deleteDocs(responses);
  deleted.invites = await deleteDocs(invites);
  deleted.rateLimits = await deleteDocs(rateLimits.docs);

const unlinked = linkedContacts.docs;
  for (let i = 0; i < unlinked.length; i += DELETE_BATCH_LIMIT) {
    const batch = db.batch();
    unlinked.slice(i, i + DELETE_BATCH_LIMIT).forEach((doc) => {
      batch.update(doc.ref, { linkedUid: FieldValue.delete(), status: "pending" });
    });
    await batch.commit();
  }
  deleted.unlinked = unlinked.length;

  await db.collection("users").doc(callerUid).delete();

console.log(`Erased data for ${callerUid}:`, deleted);

  return { ok: true, ...deleted };
});
