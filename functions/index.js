const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { normalizePhone } = require("./phone");

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/**
 * Finds the user account that owns `phone`.
 *
 * Matching runs on the normalised `phoneNormalized` field. Documents written
 * before that field existed are still matched by their raw `phone` value, so
 * a partially-backfilled database keeps working — remove the fallback once
 * `scripts/backfill-phone-normalized.js` has run against production.
 */
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

/**
 * Finds every contact document, across all users, that points at `phone`.
 * Same normalised-then-legacy strategy as findUserByPhone, deduped by doc id
 * because a backfilled document matches both queries.
 */
async function findContactsByPhone(phone, extraWhere = []) {
  const normalized = normalizePhone(phone);
  const byId = new Map();

  const run = async (field, value) => {
    let query = db.collection("contacts").where(field, "==", value);
    for (const [f, op, v] of extraWhere) query = query.where(f, op, v);
    const snap = await query.get();
    snap.docs.forEach((doc) => byId.set(doc.id, doc));
  };

  if (normalized) await run("phoneNormalized", normalized);
  if (phone) await run("phone", phone);

  return [...byId.values()];
}

function getCreatedCopy(alertType, userName) {
  switch (alertType) {
    case "sos":
      return {
        title: "🚨 SOS Alert",
        body: `${userName} has sent an emergency SOS. Check on them immediately.`,
      };
    case "headsUp":
      return {
        title: "⚠️ Heads Up",
        body: `${userName} is feeling off and will check in soon. Keep an eye out.`,
      };
    case "headsUpExpired":
      return {
        title: "⚠️ Check-in Missed",
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
    const phone = contact.phone;

    if (contact.status === "pending") {
      console.log(`Contact ${contactDoc.id} has a pending invite; skipping push.`);
      return;
    }

    if (!phone) {
      console.log(`Contact ${contactDoc.id} has no phone field.`);
      return;
    }

    const userDoc = await findUserByPhone(phone);

    if (!userDoc) {
      console.log(`No user found with phone ${phone}.`);
      return;
    }

    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) {
      console.log(`User ${userDoc.id} (phone ${phone}) has no fcmToken.`);
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
    console.log(`Notification sent to ${phone}: ${response}`);
  });

  const results = await Promise.allSettled(sendPromises);
  results.forEach((result, i) => {
    if (result.status === "rejected") {
      console.error(`Failed to notify contact ${i}:`, result.reason);
    }
  });
}

// ---------------------------------------------------------------------------
// onAlertCreated — notify contacts when a new alert is sent
// ---------------------------------------------------------------------------

exports.onAlertCreated = onDocumentCreated("alerts/{alertId}", async (event) => {
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

// ---------------------------------------------------------------------------
// onAlertUpdated — notify contacts when an alert is cancelled
// ---------------------------------------------------------------------------

exports.onAlertUpdated = onDocumentUpdated("alerts/{alertId}", async (event) => {
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
// expireHeadsUpWindows — escalate check-in windows the user never closed.
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

exports.expireHeadsUpWindows = onSchedule(
  { schedule: "every 1 minutes", timeoutSeconds: 120 },
  async () => {
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

    results.forEach((result, i) => {
      if (result.status === "rejected") {
        console.error(`Failed to expire ${dueSnap.docs[i].id}:`, result.reason);
      }
    });

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

  // Carry the last known position across from the Heads Up's original alert,
  // and do it *before* creating the expiry alert — creating it is what fires
  // onAlertCreated, so anything added afterwards could be missed by a
  // caregiver who opens the notification immediately. Without this the most
  // urgent alert type in the app — a missed check-in — would reach the
  // contact circle with no location at all.
  const originAlert = await db.collection("alerts").doc(`${doc.id}_alert`).get();
  const origin = originAlert.exists ? originAlert.data() : {};
  const hasPosition = origin.latitude != null && origin.longitude != null;

  // Flip the window and claim the alert in one transaction, so a concurrent
  // client-side expiry can't produce a second notification.
  await db.runTransaction(async (tx) => {
    const [freshHeadsUp, existingAlert] = await Promise.all([
      tx.get(doc.ref),
      tx.get(alertRef),
    ]);

    // The user may have checked in or cancelled between the query and here.
    if (!freshHeadsUp.exists || freshHeadsUp.data().status !== "active") {
      return;
    }

    tx.update(doc.ref, { status: "expired" });

    // Already escalated by the client's local countdown — flip the window but
    // don't create a second alert.
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
}

// ---------------------------------------------------------------------------
// getPeopleIWatch — for the caller, find everyone who lists the caller's
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

exports.getPeopleIWatch = onCall(async (request) => {
  const callerUid = request.auth?.uid;
  if (!callerUid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const callerDoc = await db.collection("users").doc(callerUid).get();
  const callerPhone = callerDoc.exists ? callerDoc.data().phone : null;
  if (!callerPhone) {
    return { people: [] };
  }

  const contactDocs = await findContactsByPhone(callerPhone);

  const people = await Promise.all(
    contactDocs.map(async (contactDoc) => {
      const contact = contactDoc.data();
      if (contact.status === "pending") return null;

      const ownerId = contact.userId;
      if (!ownerId) return null;

      // These three reads are independent of each other, so fire them
      // together instead of paying a round trip each — this was previously
      // the main per-person latency cost of the whole callable.
      const [ownerDoc, sosSnap, headsUpSnap] = await Promise.all([
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
      ]);

      const ownerData = ownerDoc.exists ? ownerDoc.data() : {};
      const ownerName = ownerData.displayName || "Someone";
      const ownerPhone = ownerData.phone || null;

      let status = "monitoring";
      let activeAlertId = null;

      if (!sosSnap.empty) {
        status = "sos";
        activeAlertId = sosSnap.docs[0].id;
      } else if (!headsUpSnap.empty) {
        status = "headsUp";
      }

      return {
        ownerId,
        ownerName,
        ownerPhone,
        contactId: contactDoc.id,
        status,
        activeAlertId,
      };
    })
  );

  return { people: people.filter(Boolean) };
});

// ---------------------------------------------------------------------------
// getAlertDetail — fetch an alert and its owner's profile, authorizing the
// caller by confirming they are listed as one of the owner's contacts.
//
// Scales to zero, per the cost note on getPeopleIWatch. This is the one path
// where the cold start is actually felt — a caregiver opening an incoming SOS
// notification — so if the budget ever allows, this is the function to give
// `minInstances: 1` back to first.
// ---------------------------------------------------------------------------

exports.getAlertDetail = onCall(async (request) => {
  const callerUid = request.auth?.uid;
  if (!callerUid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const alertId = request.data?.alertId;
  if (!alertId) {
    throw new HttpsError("invalid-argument", "alertId is required.");
  }

  const alertDoc = await db.collection("alerts").doc(alertId).get();
  if (!alertDoc.exists) {
    throw new HttpsError("not-found", "Alert not found.");
  }
  const alertUserId = alertDoc.data().userId;

  // callerDoc and ownerDoc don't depend on each other's results — only the
  // contact lookup needs to wait on callerPhone (from callerDoc).
  const [callerDoc, ownerDoc] = await Promise.all([
    db.collection("users").doc(callerUid).get(),
    db.collection("users").doc(alertUserId).get(),
  ]);
  const callerPhone = callerDoc.exists ? callerDoc.data().phone : null;
  const owner = ownerDoc.exists ? ownerDoc.data() : {};

  const contactDocs = callerPhone
    ? await findContactsByPhone(callerPhone, [["userId", "==", alertUserId]])
    : [];
  const contactDoc = contactDocs[0];

  if (!contactDoc || contactDoc.data().status === "pending") {
    throw new HttpsError(
      "permission-denied",
      "You are not listed as a contact for this alert."
    );
  }
  const contact = contactDoc.data();

  return {
    alert: { id: alertDoc.id, ...alertDoc.data() },
    ownerProfile: {
      displayName: owner.displayName || "Someone",
      phone: owner.phone || null,
      bloodType: owner.bloodType || null,
      seizureType: owner.seizureType || null,
      emergencyNote: owner.emergencyNote || null,
    },
    callerContactId: contactDoc.id,
    callerContactName: contact.name,
  };
});

// ---------------------------------------------------------------------------
// sendCircleInvite — when adding a contact whose phone belongs to a
// registered user, send them an in-app invite instead of relying on the
// SMS/WhatsApp share link. The contact is gated to `status: "pending"` until
// the recipient accepts, so they aren't notified of anything before consenting.
// ---------------------------------------------------------------------------

exports.sendCircleInvite = onCall(async (request) => {
  const callerUid = request.auth?.uid;
  if (!callerUid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const contactId = request.data?.contactId;
  const phone = request.data?.phone;
  if (!contactId || !phone) {
    throw new HttpsError("invalid-argument", "contactId and phone are required.");
  }

  const contactDoc = await db.collection("contacts").doc(contactId).get();
  if (!contactDoc.exists || contactDoc.data().userId !== callerUid) {
    throw new HttpsError("permission-denied", "Not your contact.");
  }

  const recipientDoc = await findUserByPhone(phone);

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
// respondToInvite — the recipient accepts or declines a circle invite.
// Accepting flips the sender's contact doc to `status: "active"`; declining
// deletes it. Both mutate a contact doc owned by a different uid, which is
// only safe because this runs under the Admin SDK.
// ---------------------------------------------------------------------------

exports.respondToInvite = onCall(async (request) => {
  const callerUid = request.auth?.uid;
  if (!callerUid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

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
    await contactRef.update({ status: "active" }).catch(() => null);
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
