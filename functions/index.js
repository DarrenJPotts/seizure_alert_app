const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onCall, onRequest, HttpsError } = require("firebase-functions/v2/https");
const { onTaskDispatched } = require("firebase-functions/v2/tasks");
const { onMessagePublished } = require("firebase-functions/v2/pubsub");
const { setGlobalOptions } = require("firebase-functions/v2");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getFunctions } = require("firebase-admin/functions");
const { getMessaging } = require("firebase-admin/messaging");
const crypto = require("node:crypto");
const { daysSince, isEscalationStale } = require("./time");
const { functionsEnabled } = require("./killswitch");

setGlobalOptions({ maxInstances: 5, minInstances: 0 });

// Callable endpoints reject requests without a valid Firebase App Check
// attestation. The mobile client initializes App Check before any Firebase
// services are used.
// Cloud Run must accept the transport request before callable Auth and App
// Check can validate it inside the function.
const CALLABLE_OPTIONS = { enforceAppCheck: true, invoker: "public" };

const BILLING_BUDGET_TOPIC = "seizure-alert-budget-alerts";
const BILLING_ACCOUNT_ID = "017AAE-400AB6-98B366";
const BILLING_BUDGET_ID = "2a77275e-d5c9-46dc-85e6-9c7a50113786";

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

/**
 * Stop function work when the $1 monthly budget's actual spend reaches 100%.
 * The kill switch remains off until an operator manually re-enables it in
 * Firestore. Billing notifications are delayed/estimated, so this is a safety
 * brake, not a guaranteed hard spending ceiling.
 */
exports.disableFunctionsAtBudget = onMessagePublished(
  { topic: BILLING_BUDGET_TOPIC, retry: false, maxInstances: 1, minInstances: 0 },
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

    const configRef = db.collection("system").doc("functionsConfig");
    const configSnapshot = await configRef.get();
    if (configSnapshot.exists && configSnapshot.data().enabled === false) {
      console.info("Function kill switch is already on.");
      return;
    }

    await configRef.set(
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

function normalizeInviteCode(value) {
  if (typeof value !== "string") return null;
  const code = value.replace(/[\s-]/g, "").toUpperCase();
  return /^(?:[0-9]{8}|[0-9A-F]{32})$/.test(code) ? code : null;
}

function hashInviteCode(code) {
  return crypto.createHash("sha256").update(code).digest("hex");
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

function hashWearableSecret(value) {
  return crypto.createHash("sha256").update(value).digest("hex");
}

function sendJson(response, status, body) {
  response.status(status).set("Cache-Control", "no-store").json(body);
}

async function authenticateWearable(request) {
  const authorization = request.get("authorization") || "";
  const match = authorization.match(/^Bearer ([a-f0-9]{64})$/i);
  if (!match) return null;
  const tokenHash = hashWearableSecret(match[1].toLowerCase());
  const snapshot = await db
    .collection("wearable_device_credentials")
    .where("tokenHash", "==", tokenHash)
    .where("revoked", "==", false)
    .limit(1)
    .get();
  return snapshot.empty ? null : snapshot.docs[0];
}

async function touchWearable(credential, batteryPercent) {
  const deviceRef = db.collection("wearableDevices").doc(credential.id);
  const battery = Number(batteryPercent);
  await deviceRef.set(
    {
      lastSeenAtMs: Date.now(),
      ...(Number.isInteger(battery) && battery >= 0 && battery <= 100
        ? { batteryPercent: battery }
        : {}),
    },
    { merge: true }
  );
}

exports.createWearablePairingCode = onCall(CALLABLE_OPTIONS, async (request) => {
  if (!(await functionsEnabled(db))) {
    throw new HttpsError("unavailable", "This feature is temporarily disabled.");
  }
  const callerUid = request.auth?.uid;
  if (!callerUid) throw new HttpsError("unauthenticated", "Sign in required.");
  await enforceRateLimit(callerUid, "wearablePairing", 5, 60 * 60 * 1000);

  for (let attempt = 0; attempt < 5; attempt += 1) {
    const code = String(crypto.randomInt(0, 1000000)).padStart(6, "0");
    const ref = db.collection("wearable_pairings").doc(hashWearableSecret(code));
    const expiresAt = Date.now() + 10 * 60 * 1000;
    try {
      await ref.create({
        userId: callerUid,
        createdAt: FieldValue.serverTimestamp(),
        expiresAt: new Date(expiresAt),
        status: "pending",
      });
      return { code, expiresAt };
    } catch (error) {
      if (error?.code !== 6 && error?.code !== "already-exists") throw error;
    }
  }
  throw new HttpsError("resource-exhausted", "Could not create a pairing code.");
});

exports.removeWearableDevice = onCall(CALLABLE_OPTIONS, async (request) => {
  if (!(await functionsEnabled(db))) {
    throw new HttpsError("unavailable", "This feature is temporarily disabled.");
  }
  const callerUid = request.auth?.uid;
  const deviceId = request.data?.deviceId;
  if (!callerUid) throw new HttpsError("unauthenticated", "Sign in required.");
  if (typeof deviceId !== "string" || !deviceId) {
    throw new HttpsError("invalid-argument", "deviceId is required.");
  }
  const publicRef = db.collection("wearableDevices").doc(deviceId);
  const publicDoc = await publicRef.get();
  if (!publicDoc.exists || publicDoc.data().userId !== callerUid) {
    throw new HttpsError("not-found", "Wearable not found.");
  }
  const batch = db.batch();
  batch.delete(publicRef);
  batch.delete(db.collection("wearable_device_credentials").doc(deviceId));
  await batch.commit();
  return { ok: true };
});

exports.wearablePair = onRequest(
  { invoker: "public", minInstances: 0, maxInstances: 5 },
  async (request, response) => {
    if (request.method !== "POST") return sendJson(response, 405, { error: "method" });
    if (!(await functionsEnabled(db))) {
      return sendJson(response, 503, { error: "disabled" });
    }
    const ipKey = hashWearableSecret(request.ip || "unknown").slice(0, 24);
    try {
      await enforceRateLimit(ipKey, "wearablePairAttempt", 20, 60 * 60 * 1000);
    } catch (_) {
      return sendJson(response, 429, { error: "rate-limit" });
    }
    const code = typeof request.body?.code === "string"
      ? request.body.code.replace(/\D/g, "")
      : "";
    if (!/^\d{6}$/.test(code)) {
      return sendJson(response, 400, { error: "invalid-code" });
    }
    const pairingRef = db.collection("wearable_pairings").doc(hashWearableSecret(code));
    const token = crypto.randomBytes(32).toString("hex");
    const deviceId = crypto.randomUUID();
    const deviceName = typeof request.body?.deviceName === "string"
      ? request.body.deviceName.trim().slice(0, 80)
      : "Garmin watch";
    try {
      await db.runTransaction(async (tx) => {
        const pairing = await tx.get(pairingRef);
        if (
          !pairing.exists ||
          pairing.data().status !== "pending" ||
          pairing.data().expiresAt.toMillis() <= Date.now()
        ) {
          throw new Error("invalid-code");
        }
        const userId = pairing.data().userId;
        tx.update(pairingRef, {
          status: "used",
          usedAt: FieldValue.serverTimestamp(),
          deviceId,
        });
        tx.create(db.collection("wearable_device_credentials").doc(deviceId), {
          userId,
          tokenHash: hashWearableSecret(token),
          revoked: false,
          createdAt: FieldValue.serverTimestamp(),
        });
        tx.create(db.collection("wearableDevices").doc(deviceId), {
          id: deviceId,
          userId,
          platform: "garmin",
          name: deviceName || "Garmin watch",
          pairedAt: new Date().toISOString(),
          lastSeenAtMs: Date.now(),
          batteryPercent: null,
        });
      });
      return sendJson(response, 200, { deviceId, token });
    } catch (_) {
      return sendJson(response, 400, { error: "invalid-code" });
    }
  }
);

exports.wearableStatus = onRequest(
  { invoker: "public", minInstances: 0, maxInstances: 5 },
  async (request, response) => {
    if (request.method !== "GET" && request.method !== "POST") {
      return sendJson(response, 405, { error: "method" });
    }
    if (!(await functionsEnabled(db))) {
      return sendJson(response, 503, { error: "disabled" });
    }
    const credential = await authenticateWearable(request);
    if (!credential) return sendJson(response, 401, { error: "unauthorized" });
    await touchWearable(credential, request.body?.batteryPercent);
    const userId = credential.data().userId;
    const [alerts, headsUp] = await Promise.all([
      db
        .collection("alerts")
        .where("userId", "==", userId)
        .where("status", "==", "sent")
        .orderBy("createdAt", "desc")
        .limit(1)
        .get(),
      db
        .collection("headsUp")
        .where("userId", "==", userId)
        .where("status", "==", "active")
        .limit(1)
        .get(),
    ]);
    const alert = alerts.empty ? null : alerts.docs[0].data();
    const activeHeadsUp = headsUp.empty ? null : headsUp.docs[0].data();
    return sendJson(response, 200, {
      state: alert?.type === "sos"
        ? "sos"
        : activeHeadsUp
          ? "headsUp"
          : "ready",
      alertId: alert?.type === "sos" ? alerts.docs[0].id : null,
      headsUpId: activeHeadsUp ? headsUp.docs[0].id : null,
      headsUpExpiresAtMs: activeHeadsUp?.expiresAtMs || null,
    });
  }
);

exports.wearableAction = onRequest(
  { invoker: "public", minInstances: 0, maxInstances: 5 },
  async (request, response) => {
    if (request.method !== "POST") return sendJson(response, 405, { error: "method" });
    if (!(await functionsEnabled(db))) {
      return sendJson(response, 503, { error: "disabled" });
    }
    const credential = await authenticateWearable(request);
    if (!credential) return sendJson(response, 401, { error: "unauthorized" });
    await touchWearable(credential, request.body?.batteryPercent);
    const userId = credential.data().userId;
    const action = request.body?.action;

    if (action === "sos") {
      const existing = await db
        .collection("alerts")
        .where("userId", "==", userId)
        .where("status", "==", "sent")
        .orderBy("createdAt", "desc")
        .limit(5)
        .get();
      const activeSos = existing.docs.find((doc) => doc.data().type === "sos");
      if (activeSos) {
        return sendJson(response, 200, {
          ok: true,
          alertId: activeSos.id,
          existing: true,
        });
      }
      const alertRef = db.collection("alerts").doc();
      const logRef = db.collection("seizureLogs").doc();
      const now = new Date().toISOString();
      const batch = db.batch();
      batch.create(alertRef, {
        id: alertRef.id,
        userId,
        type: "sos",
        status: "sent",
        latitude: null,
        longitude: null,
        locationLabel: "Sent from Garmin watch",
        message: null,
        createdAt: now,
        resolvedAt: null,
      });
      batch.create(logRef, {
        id: logRef.id,
        userId,
        occurredAt: now,
        durationSeconds: null,
        location: null,
        latitude: null,
        longitude: null,
        notes: "SOS sent from Garmin watch",
        trigger: null,
        seizureType: null,
        aura: null,
        severity: null,
        awareness: null,
        injuries: null,
        recoveryMinutes: null,
        rescueMedicationUsed: false,
        alertFired: true,
        alertId: alertRef.id,
      });
      await batch.commit();
      return sendJson(response, 200, { ok: true, alertId: alertRef.id });
    }

    if (action === "cancel") {
      const alertId = request.body?.alertId;
      if (typeof alertId !== "string") {
        return sendJson(response, 400, { error: "alert-required" });
      }
      const alertRef = db.collection("alerts").doc(alertId);
      const alert = await alertRef.get();
      if (!alert.exists || alert.data().userId !== userId || alert.data().status !== "sent") {
        return sendJson(response, 404, { error: "alert-not-active" });
      }
      await alertRef.update({
        status: "cancelled",
        resolvedAt: new Date().toISOString(),
      });
      return sendJson(response, 200, { ok: true });
    }

    if (action === "headsUp") {
      const durationMinutes = Number(request.body?.durationMinutes);
      if (![30, 60, 120].includes(durationMinutes)) {
        return sendJson(response, 400, { error: "duration" });
      }
      const headsUpRef = db.collection("headsUp").doc();
      const alertRef = db.collection("alerts").doc(`${headsUpRef.id}_alert`);
      const now = Date.now();
      const expiresAtMs = now + durationMinutes * 60 * 1000;
      const batch = db.batch();
      batch.create(headsUpRef, {
        id: headsUpRef.id,
        userId,
        createdAt: new Date(now).toISOString(),
        expiresAt: new Date(expiresAtMs).toISOString(),
        expiresAtMs,
        note: "Started from Garmin watch",
        status: "active",
      });
      batch.create(alertRef, {
        id: alertRef.id,
        userId,
        type: "headsUp",
        status: "sent",
        latitude: null,
        longitude: null,
        locationLabel: "Started from Garmin watch",
        message: "Started from Garmin watch",
        createdAt: new Date(now).toISOString(),
        resolvedAt: null,
      });
      await batch.commit();
      return sendJson(response, 200, { ok: true, headsUpId: headsUpRef.id });
    }

    if (action === "checkIn") {
      const headsUpId = request.body?.headsUpId;
      if (typeof headsUpId !== "string") {
        return sendJson(response, 400, { error: "heads-up-required" });
      }
      const headsUpRef = db.collection("headsUp").doc(headsUpId);
      const headsUp = await headsUpRef.get();
      if (!headsUp.exists || headsUp.data().userId !== userId || headsUp.data().status !== "active") {
        return sendJson(response, 404, { error: "heads-up-not-active" });
      }
      const batch = db.batch();
      batch.update(headsUpRef, { status: "checkedIn" });
      batch.update(db.collection("alerts").doc(`${headsUpId}_alert`), {
        status: "cancelled",
        resolvedAt: new Date().toISOString(),
      });
      await batch.commit();
      return sendJson(response, 200, { ok: true });
    }

    return sendJson(response, 400, { error: "unknown-action" });
  }
);

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

function buildMessage({
  token,
  title,
  body,
  alertId,
  alertType,
  alertStatus,
  userId,
  route,
  ttlMs,
}) {
  const data = {
    alertType: String(alertType),
    alertStatus: String(alertStatus),
    userId: String(userId),
  };
  if (alertId != null) data.alertId = String(alertId);
  if (typeof route === "string" && route.startsWith("/")) data.route = route;

  const message = {
    token,
    notification: { title, body },
    data,
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

  if (Number.isFinite(ttlMs) && ttlMs > 0) {
    message.android.ttl = ttlMs;
    message.apns.headers = {
      "apns-expiration": String(
        Math.floor(Date.now() / 1000) + Math.ceil(ttlMs / 1000)
      ),
    };
  }

  return message;
}

function isStaleMessagingToken(error) {
  const code = error?.code || error?.errorInfo?.code;
  return code === "messaging/registration-token-not-registered" ||
    code === "messaging/invalid-registration-token";
}

async function clearStaleToken(userRef, attemptedToken) {
  await db.runTransaction(async (transaction) => {
    const current = await transaction.get(userRef);
    if (current.data()?.fcmToken === attemptedToken) {
      transaction.update(userRef, {
        fcmToken: FieldValue.delete(),
        fcmTokenUpdatedAt: FieldValue.delete(),
      });
    }
  });
}

const TEST_ALERT_RECIPIENT_LIMIT = 20;

async function writeCaregiverTestStatuses(contacts, statusByUid) {
  if (contacts.length === 0) return;

  const batch = db.batch();
  const testedAtMs = Date.now();
  contacts.forEach((contactDoc) => {
    const linkedUid = contactDoc.data().linkedUid;
    batch.set(
      contactDoc.ref,
      {
        lastTestStatus: statusByUid.get(linkedUid) || "failed",
        lastTestedAtMs: testedAtMs,
      },
      { merge: true }
    );
  });
  await batch.commit();
}

exports.sendCaregiverTestAlert = onCall(CALLABLE_OPTIONS, async (request) => {
  if (!(await functionsEnabled(db))) {
    throw new HttpsError("unavailable", "This feature is temporarily disabled.");
  }

  const callerUid = request.auth?.uid;
  if (!callerUid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  await enforceRateLimit(callerUid, "caregiverTest", 2, 10 * 60 * 1000);

  const [ownerDoc, contactsSnap] = await Promise.all([
    db.collection("users").doc(callerUid).get(),
    db
      .collection("contacts")
      .where("userId", "==", callerUid)
      .where("notifyViaPush", "==", true)
      .limit(TEST_ALERT_RECIPIENT_LIMIT + 1)
      .get(),
  ]);

  if (!ownerDoc.exists) {
    throw new HttpsError("failed-precondition", "Complete your profile first.");
  }

  const contacts = contactsSnap.docs
    .filter((doc) => {
      const contact = doc.data();
      return (
        contact.status !== "pending" &&
        typeof contact.linkedUid === "string" &&
        contact.linkedUid.length > 0
      );
    })
    .slice(0, TEST_ALERT_RECIPIENT_LIMIT);

  const linkedUids = [...new Set(contacts.map((doc) => doc.data().linkedUid))];
  const recipientDocs = await Promise.all(
    linkedUids.map((uid) => db.collection("users").doc(uid).get())
  );
  const statusByUid = new Map(linkedUids.map((uid) => [uid, "deviceOffline"]));
  const recipientsByToken = new Map();
  recipientDocs.forEach((doc, index) => {
    if (!doc.exists) return;
    const token = doc.data().fcmToken;
    if (typeof token !== "string" || token.length === 0) return;

    const uid = linkedUids[index];
    const recipient = recipientsByToken.get(token) || { token, users: [] };
    recipient.users.push({ uid, doc });
    recipientsByToken.set(token, recipient);
  });
  const recipients = [...recipientsByToken.values()];

  if (recipients.length === 0) {
    await writeCaregiverTestStatuses(contacts, statusByUid);
    throw new HttpsError(
      "failed-precondition",
      "No connected caregivers are ready for push alerts."
    );
  }

  const ownerName = ownerDoc.data().displayName || "Someone in your circle";
  const sends = await Promise.allSettled(
    recipients.map(({ token }) =>
      messaging.send(
        buildMessage({
          token,
          title: "TEST — Caregiver alert",
          body: `${ownerName} is testing their alert connection. No action is needed.`,
          alertType: "test",
          alertStatus: "test",
          userId: callerUid,
          route: "/",
          ttlMs: 5 * 60 * 1000,
        })
      )
    )
  );

  const staleRecipients = sends.flatMap((result, index) => {
    if (result.status !== "rejected") return [];
    const code = result.reason?.code || result.reason?.errorInfo?.code;
    return code === "messaging/registration-token-not-registered" ||
      code === "messaging/invalid-registration-token"
      ? [recipients[index]]
      : [];
  });

  await Promise.allSettled(
    staleRecipients.flatMap(({ users, token }) =>
      users.map(({ doc }) =>
        db.runTransaction(async (transaction) => {
          const current = await transaction.get(doc.ref);
          if (current.data()?.fcmToken === token) {
            transaction.update(doc.ref, { fcmToken: FieldValue.delete() });
          }
        })
      )
    )
  );

  sends.forEach((result, index) => {
    const recipient = recipients[index];
    const code = result.status === "rejected"
      ? result.reason?.code || result.reason?.errorInfo?.code
      : null;
    const status = result.status === "fulfilled"
      ? "sent"
      : code === "messaging/registration-token-not-registered" ||
          code === "messaging/invalid-registration-token"
        ? "deviceOffline"
        : "failed";
    recipient.users.forEach(({ uid }) => statusByUid.set(uid, status));
  });
  await writeCaregiverTestStatuses(contacts, statusByUid);

  const sentCount = sends.filter((result) => result.status === "fulfilled").length;
  const failedCount = sends.length - sentCount;
  if (sentCount === 0) {
    console.error("Every caregiver test notification failed.", sends);
    if (staleRecipients.length === sends.length) {
      throw new HttpsError(
        "failed-precondition",
        "Connected caregivers need to reopen the app before testing."
      );
    }
    throw new HttpsError(
      "unavailable",
      "The test alert could not be sent. Try again later."
    );
  }

  return {
    recipientCount: recipients.length,
    sentCount,
    failedCount,
    capped: contactsSnap.size > TEST_ALERT_RECIPIENT_LIMIT,
  };
});

async function notifyContacts(alertUserId, alert, copy, { trackDelivery = false } = {}) {
  const contactsSnap = await db
    .collection("contacts")
    .where("userId", "==", alertUserId)
    .where("notifyViaPush", "==", true)
    .get();

  if (contactsSnap.empty) {
    console.log(`No push-enabled contacts for user ${alertUserId}.`);
    return [];
  }

  const sendPromises = contactsSnap.docs.map(async (contactDoc) => {
    const contact = contactDoc.data();
    const linkedUid = contact.linkedUid;

if (contact.status === "pending" || typeof linkedUid !== "string" || !linkedUid) {
      console.log(`Contact ${contactDoc.id} is not linked; skipping push.`);
      return { contactDoc, linkedUid: null, status: "notLinked" };
    }

    const userDoc = await db.collection("users").doc(linkedUid).get();
    if (!userDoc.exists) {
      console.log(`Contact ${contactDoc.id} has no matching account.`);
      return { contactDoc, linkedUid, status: "accountMissing" };
    }

    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) {
      console.log(`User ${userDoc.id} (contact ${contactDoc.id}) has no fcmToken.`);
      return { contactDoc, linkedUid, status: "deviceOffline" };
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

    try {
      const response = await messaging.send(message);
      console.log(`Notified contact ${contactDoc.id}: ${response}`);
      return { contactDoc, linkedUid, status: "sent" };
    } catch (error) {
      if (isStaleMessagingToken(error)) {
        await clearStaleToken(userDoc.ref, fcmToken);
        return { contactDoc, linkedUid, status: "deviceOffline" };
      }
      console.error(`Failed to notify contact ${contactDoc.id}:`, error);
      return { contactDoc, linkedUid, status: "failed" };
    }
  });

  const deliveries = await Promise.all(sendPromises);
  if (trackDelivery && alert.id) {
    const batch = db.batch();
    const sentAtMs = Date.now();
    deliveries.forEach(({ contactDoc, linkedUid, status }) => {
      const ref = db
        .collection("alert_deliveries")
        .doc(`${alert.id}_${contactDoc.id}`);
      batch.set(
        ref,
        {
          id: ref.id,
          alertId: alert.id,
          alertOwnerId: alertUserId,
          contactId: contactDoc.id,
          contactName: contactDoc.data().name || "Someone",
          responderId: linkedUid,
          priority: contactDoc.data().priority || 0,
          status,
          sentAtMs,
        },
        { merge: true }
      );
    });
    await batch.commit();
  }
  return deliveries;
}

const ALERT_ESCALATION_DELAY_MS = 90 * 1000;
const ALERT_ESCALATION_MAX_STAGES = 3;

async function enqueueAlertEscalation(alertId, stage) {
  if (stage >= ALERT_ESCALATION_MAX_STAGES) return;
  try {
    await getFunctions()
      .taskQueue("escalateUnansweredAlert")
      .enqueue(
        { alertId, stage },
        {
          id: `${alertId}_${stage}`,
          scheduleTime: new Date(Date.now() + ALERT_ESCALATION_DELAY_MS),
          dispatchDeadlineSeconds: 60,
        }
      );
  } catch (error) {
    if (error?.code === "functions/task-already-exists") return;
    throw error;
  }
}

exports.escalateUnansweredAlert = onTaskDispatched(
  {
    retryConfig: {
      maxAttempts: 3,
      minBackoffSeconds: 30,
      maxBackoffSeconds: 180,
      maxDoublings: 2,
    },
    rateLimits: { maxConcurrentDispatches: 5, maxDispatchesPerSecond: 5 },
    timeoutSeconds: 120,
    minInstances: 0,
    maxInstances: 5,
  },
  async (request) => {
    if (!(await functionsEnabled(db))) return;
    const alertId = request.data?.alertId;
    const stage = Number(request.data?.stage);
    if (
      typeof alertId !== "string" ||
      !Number.isInteger(stage) ||
      stage < 0 ||
      stage >= ALERT_ESCALATION_MAX_STAGES
    ) {
      return;
    }

    const alertRef = db.collection("alerts").doc(alertId);
    const alertDoc = await alertRef.get();
    if (!alertDoc.exists || alertDoc.data().status !== "sent") return;

    const responding = await db
      .collection("alert_responses")
      .where("alertId", "==", alertId)
      .where("responding", "==", true)
      .limit(1)
      .get();
    if (!responding.empty) {
      await alertRef.set(
        {
          acknowledgedAt: FieldValue.serverTimestamp(),
          acknowledgedBy: responding.docs[0].data().responderId || null,
        },
        { merge: true }
      );
      return;
    }

    const contacts = await db
      .collection("contacts")
      .where("userId", "==", alertDoc.data().userId)
      .orderBy("priority")
      .get();
    const ready = contacts.docs.filter((doc) => {
      const data = doc.data();
      return data.notifyViaPush === true &&
        data.status !== "pending" &&
        typeof data.linkedUid === "string" &&
        data.linkedUid.length > 0;
    });
    if (ready.length === 0 || stage >= ready.length) return;

    const contactDoc = ready[stage];
    const contact = contactDoc.data();
    const caregiver = await db.collection("users").doc(contact.linkedUid).get();
    const token = caregiver.exists ? caregiver.data().fcmToken : null;
    if (typeof token === "string" && token) {
      try {
        await messaging.send(
          buildMessage({
            token,
            title: "No caregiver has responded",
            body: "Open the active alert and confirm whether you can help.",
            alertId,
            alertType: alertDoc.data().type,
            alertStatus: "sent",
            userId: alertDoc.data().userId,
          })
        );
        await db
          .collection("alert_deliveries")
          .doc(`${alertId}_${contactDoc.id}`)
          .set(
            {
              escalationStage: stage + 1,
              lastEscalatedAtMs: Date.now(),
              status: "sent",
            },
            { merge: true }
          );
      } catch (error) {
        if (isStaleMessagingToken(error)) {
          await clearStaleToken(caregiver.ref, token);
        } else {
          throw error;
        }
      }
    }

    await alertRef.set(
      {
        escalationStage: stage + 1,
        escalatedAt: FieldValue.serverTimestamp(),
        escalatedContactId: contactDoc.id,
      },
      { merge: true }
    );
    if (stage + 1 < ready.length) {
      await enqueueAlertEscalation(alertId, stage + 1);
    }
  }
);

exports.onAlertCreated = onDocumentCreated("alerts/{alertId}", async (event) => {
  if (!(await functionsEnabled(db))) {
    console.warn("Kill switch is on; skipping onAlertCreated.");
    return;
  }

  const alert = event.data?.data();
  if (!alert || alert.status !== "sent") return;

  const alertUserId = alert.userId;
  if (!alertUserId) return;

  try {
    await enforceRateLimit(alertUserId, "alertNotify", 6, 10 * 60 * 1000);
  } catch (error) {
    if (error instanceof HttpsError && error.code === "resource-exhausted") {
      console.warn(`Notification rate limit reached for ${alertUserId}.`);
      return;
    }
    throw error;
  }

  const userDoc = await db.collection("users").doc(alertUserId).get();
  const userName = userDoc.exists ? (userDoc.data().displayName || "Someone") : "Someone";

  const copy = getCreatedCopy(alert.type, userName);
  if (!copy) return;

  const deliveries = await notifyContacts(alertUserId, alert, copy, {
    trackDelivery: alert.type === "sos" || alert.type === "headsUpExpired",
  });
  if (
    (alert.type === "sos" || alert.type === "headsUpExpired") &&
    deliveries.some((delivery) => delivery.status === "sent")
  ) {
    await enqueueAlertEscalation(alert.id, 0);
  }
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

  try {
    await enforceRateLimit(alertUserId, "alertNotify", 6, 10 * 60 * 1000);
  } catch (error) {
    if (error instanceof HttpsError && error.code === "resource-exhausted") {
      console.warn(`Notification rate limit reached for ${alertUserId}.`);
      return;
    }
    throw error;
  }

  const userDoc = await db.collection("users").doc(alertUserId).get();
  const userName = userDoc.exists ? (userDoc.data().displayName || "Someone") : "Someone";

  const copy = getCancelledCopy(after.type, userName);
  if (!copy) return;

  await notifyContacts(alertUserId, after, copy);
});

// ---------------------------------------------------------------------------
//
// A Heads Up must escalate even when the phone is off or the app is killed.
// The delayed task is therefore the only writer of the expiry alert, and its
// deterministic alert id keeps retries idempotent.
// ---------------------------------------------------------------------------

const HEADS_UP_ESCALATION_GRACE_MS = 60 * 60 * 1000;

// Each Heads Up creates one delayed task. This keeps server-side escalation
// reliable while avoiding an idle scheduler that wakes up every minute.
exports.onHeadsUpCreated = onDocumentCreated("headsUp/{headsUpId}", async (event) => {
  if (!(await functionsEnabled(db))) {
    console.warn("Kill switch is on; skipping Heads Up task creation.");
    return;
  }

  const headsUp = event.data?.data();
  const headsUpId = event.params.headsUpId;
  const expiresAtMs = headsUp?.expiresAtMs;
  if (
    headsUp?.status !== "active" ||
    typeof expiresAtMs !== "number" ||
    !Number.isFinite(expiresAtMs)
  ) {
    console.warn(`Heads Up ${headsUpId} cannot be scheduled because its expiry is invalid.`);
    return;
  }

  try {
    await getFunctions()
      .taskQueue("expireHeadsUpWindow")
      .enqueue(
        { headsUpId },
        {
          id: headsUpId,
          scheduleTime: new Date(Math.max(expiresAtMs, Date.now())),
          dispatchDeadlineSeconds: 60,
        }
      );
  } catch (error) {
    if (error?.code === "functions/task-already-exists") {
      console.info(`Expiry task already exists for Heads Up ${headsUpId}.`);
      return;
    }
    throw error;
  }
});

exports.expireHeadsUpWindow = onTaskDispatched(
  {
    retryConfig: {
      maxAttempts: 5,
      minBackoffSeconds: 30,
      maxBackoffSeconds: 300,
      maxDoublings: 3,
    },
    rateLimits: { maxConcurrentDispatches: 5, maxDispatchesPerSecond: 5 },
    timeoutSeconds: 120,
    minInstances: 0,
    maxInstances: 5,
  },
  async (request) => {
    if (!(await functionsEnabled(db))) {
      console.warn("Kill switch is on; skipping expireHeadsUpWindow.");
      return;
    }

    const headsUpId = request.data?.headsUpId;
    if (typeof headsUpId !== "string" || !headsUpId) return;

    const doc = await db.collection("headsUp").doc(headsUpId).get();
    if (!doc.exists || doc.data().status !== "active") return;

    const nowMs = Date.now();
    const expiresAtMs = doc.data().expiresAtMs;
    if (typeof expiresAtMs !== "number" || expiresAtMs > nowMs) {
      throw new Error(`Heads Up ${headsUpId} expiry task was dispatched early.`);
    }

    const result = await expireOneHeadsUp(doc, nowMs);
    if (result?.suppressed) {
      console.warn(
        `Closed Heads Up ${headsUpId} without notifying anyone because it expired ` +
          `more than ${HEADS_UP_ESCALATION_GRACE_MS / 60000} minutes ago.`
      );
    }
  }
);

async function expireOneHeadsUp(doc, nowMs) {
  const headsUp = doc.data();
  const alertId = `${doc.id}_expired`;
  const alertRef = db.collection("alerts").doc(alertId);

  // Too late to be useful as an alert, so close the window before doing the
  // extra reads and push work that a stale delayed task no longer justifies.
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

exports.getCaregiverAlertHistory = onCall(CALLABLE_OPTIONS, async (request) => {
  if (!(await functionsEnabled(db))) {
    throw new HttpsError("unavailable", "This feature is temporarily disabled.");
  }

  const callerUid = request.auth?.uid;
  if (!callerUid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  await enforceRateLimit(callerUid, "caregiverAlertHistory", 10, 60 * 1000);

  const contactDocs = await findLinkedContacts(callerUid);
  const ownerIds = [
    ...new Set(contactDocs.map((doc) => doc.data().userId).filter(Boolean)),
  ].slice(0, 30);

  if (ownerIds.length === 0) return { alerts: [] };

  // Firestore `in` queries accept at most 30 values. Keeping the fan-out in a
  // single bounded query also caps reads each time the history tab is opened.
  const [alertsSnap, ...ownerDocs] = await Promise.all([
    db
      .collection("alerts")
      .where("userId", "in", ownerIds)
      .orderBy("createdAt", "desc")
      .limit(20)
      .get(),
    ...ownerIds.map((ownerId) => db.collection("users").doc(ownerId).get()),
  ]);

  const ownerNames = new Map(
    ownerDocs.map((doc) => [
      doc.id,
      doc.exists ? doc.data().displayName || "Someone" : "Someone",
    ])
  );

  return {
    alerts: alertsSnap.docs.map((doc) => {
      const alert = doc.data();
      return {
        ...alert,
        id: doc.id,
        ownerName: ownerNames.get(alert.userId) || "Someone",
      };
    }),
  };
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
      seizureActionPlan: owner.seizureActionPlan || null,
      rescueMedication: owner.rescueMedication || null,
      callEmergencyAfterMinutes: Number.isInteger(owner.callEmergencyAfterMinutes)
        ? owner.callEmergencyAfterMinutes
        : 5,
      medications: Array.isArray(owner.medications) ? owner.medications : [],
      daysSinceLastSeizure: daysSince(lastLog?.occurredAt),
    },
    callerContactId: contactDoc.id,
    callerContactName: contact.name,
    notifiedCount,
    responders,
  };
});

exports.createCircleInvite = onCall(CALLABLE_OPTIONS, async (request) => {
  if (!(await functionsEnabled(db))) throw new HttpsError("unavailable", "This feature is temporarily disabled.");
  const callerUid = request.auth?.uid;
  if (!callerUid) throw new HttpsError("unauthenticated", "Sign in required.");
  await enforceRateLimit(callerUid, "inviteCreate", 10, 60 * 60 * 1000);

  const contactId = request.data?.contactId;
  if (typeof contactId !== "string" || !contactId.trim()) throw new HttpsError("invalid-argument", "contactId is required.");
  const regenerate = request.data?.regenerate === true;
  const contactRef = db.collection("contacts").doc(contactId);
  const callerDoc = await db.collection("users").doc(callerUid).get();
  const senderName = callerDoc.exists ? (callerDoc.data().displayName || "Someone") : "Someone";

  for (let attempt = 0; attempt < 5; attempt += 1) {
    const inviteCode = String(crypto.randomInt(0, 100000000)).padStart(8, "0");
    const inviteRef = db.collection("invites").doc(hashInviteCode(inviteCode));
    const expiresAt = Date.now() + 24 * 60 * 60 * 1000;
    try {
      return await db.runTransaction(async (tx) => {
        const contactDoc = await tx.get(contactRef);
        if (!contactDoc.exists || contactDoc.data().userId !== callerUid) {
          throw new HttpsError("permission-denied", "Not your contact.");
        }
        if (contactDoc.data().linkedUid) {
          throw new HttpsError("failed-precondition", "This contact is already linked.");
        }

        const existingInvites = await tx.get(
          db.collection("invites").where("contactId", "==", contactId).where("status", "==", "pending")
        );
        const codeDoc = await tx.get(inviteRef);
        const now = Date.now();
        const reusable = existingInvites.docs
          .filter((doc) => {
            const data = doc.data();
            const expiry = data.expiresAt?.toMillis?.() ?? 0;
            return expiry > now && /^[0-9]{8}$/.test(data.code || "");
          })
          .sort((a, b) => b.data().expiresAt.toMillis() - a.data().expiresAt.toMillis())[0];

        if (reusable && !regenerate) {
          const data = reusable.data();
          return { code: data.code, expiresAt: data.expiresAt.toMillis(), reused: true };
        }
        if (codeDoc.exists) throw new HttpsError("already-exists", "Choose another invite code.");

        tx.create(inviteRef, {
          code: inviteCode,
          senderUid: callerUid,
          senderName,
          contactId,
          status: "pending",
          createdAt: FieldValue.serverTimestamp(),
          expiresAt: new Date(expiresAt),
          respondedAt: null,
        });
        for (const oldInvite of existingInvites.docs) {
          tx.update(oldInvite.ref, { status: "superseded", respondedAt: FieldValue.serverTimestamp() });
        }
        tx.update(contactRef, {
          status: "active",
          inviteStatus: "pending",
          inviteExpiresAtMs: expiresAt,
        });
        return { code: inviteCode, expiresAt, reused: false };
      });
    } catch (error) {
      if (error.code !== "already-exists" || attempt === 4) throw error;
    }
  }

  throw new HttpsError("resource-exhausted", "Could not generate an invite code. Please try again.");
});

exports.previewCircleInvite = onCall(CALLABLE_OPTIONS, async (request) => {
  if (!(await functionsEnabled(db))) throw new HttpsError("unavailable", "This feature is temporarily disabled.");
  const callerUid = request.auth?.uid;
  if (!callerUid) throw new HttpsError("unauthenticated", "Sign in required.");
  await enforceRateLimit(callerUid, "invitePreview", 10, 60 * 60 * 1000);
  const code = normalizeInviteCode(request.data?.code);
  if (!code) throw new HttpsError("invalid-argument", "Enter a valid invite code.");
  const inviteDoc = await db.collection("invites").doc(hashInviteCode(code)).get();
  if (!inviteDoc.exists) throw new HttpsError("not-found", "Invite code not found.");
  const invite = inviteDoc.data();
  if (invite.senderUid === callerUid) throw new HttpsError("failed-precondition", "You cannot redeem your own invite.");
  if (invite.status !== "pending" || invite.expiresAt.toMillis() <= Date.now()) throw new HttpsError("failed-precondition", "This invite has expired or was already used.");
  const contactDoc = await db.collection("contacts").doc(invite.contactId).get();
  if (!contactDoc.exists || contactDoc.data().userId !== invite.senderUid || contactDoc.data().linkedUid) {
    throw new HttpsError("failed-precondition", "This invite is no longer available.");
  }
  return { senderName: invite.senderName || "Someone", contactName: contactDoc.data().name || "your contact" };
});

exports.respondToCircleInvite = onCall(CALLABLE_OPTIONS, async (request) => {
  if (!(await functionsEnabled(db))) throw new HttpsError("unavailable", "This feature is temporarily disabled.");
  const callerUid = request.auth?.uid;
  if (!callerUid) throw new HttpsError("unauthenticated", "Sign in required.");
  await enforceRateLimit(callerUid, "inviteResponse", 20, 60 * 60 * 1000);
  const code = normalizeInviteCode(request.data?.code);
  const accept = request.data?.accept;
  if (!code || typeof accept !== "boolean") throw new HttpsError("invalid-argument", "A valid invite code and response are required.");
  const inviteRef = db.collection("invites").doc(hashInviteCode(code));
  const status = await db.runTransaction(async (tx) => {
    const inviteDoc = await tx.get(inviteRef);
    if (!inviteDoc.exists) throw new HttpsError("not-found", "Invite code not found.");
    const data = inviteDoc.data();
    if (data.senderUid === callerUid) throw new HttpsError("failed-precondition", "You cannot redeem your own invite.");
    if (data.status !== "pending" || data.expiresAt.toMillis() <= Date.now()) throw new HttpsError("failed-precondition", "This invite has expired or was already used.");
    const contactRef = db.collection("contacts").doc(data.contactId);
    const contactDoc = await tx.get(contactRef);
    if (!contactDoc.exists || contactDoc.data().userId !== data.senderUid || contactDoc.data().linkedUid) {
      throw new HttpsError("failed-precondition", "This invite is no longer available.");
    }
    const nextStatus = accept ? "accepted" : "declined";
    tx.update(inviteRef, { status: nextStatus, ...(accept ? { recipientUid: callerUid } : {}), respondedAt: FieldValue.serverTimestamp() });
    tx.update(contactRef, accept
      ? { status: "active", linkedUid: callerUid, inviteStatus: "accepted" }
      : { status: "active", inviteStatus: "declined" });
    return nextStatus;
  });
  return { status };
});
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

  try {
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
  } catch (error) {
    if (isStaleMessagingToken(error)) {
      await clearStaleToken(targetDoc.ref, fcmToken);
      return { delivered: false, reason: "no-token" };
    }
    throw error;
  }

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
  if (responding === true) {
    await alertDoc.ref.set(
      {
        acknowledgedAt: FieldValue.serverTimestamp(),
        acknowledgedBy: callerUid,
      },
      { merge: true }
    );
  }
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

const [
    own,
    responses,
    deliveries,
    invites,
    rateLimits,
    linkedContacts,
    wearableCredentials,
    wearablePairings,
  ] = await Promise.all([
    Promise.all(
      ["contacts", "seizureLogs", "alerts", "headsUp", "wearableDevices"].map((collection) =>
        db.collection(collection).where("userId", "==", callerUid).get()
      )
    ),
    docsMatchingAny("alert_responses", [
      ["responderId", callerUid],
      ["alertOwnerId", callerUid],
    ]),
    docsMatchingAny("alert_deliveries", [
      ["responderId", callerUid],
      ["alertOwnerId", callerUid],
    ]),
    docsMatchingAny("invites", [
      ["senderUid", callerUid],
      ["recipientUid", callerUid],
    ]),
    db.collection("rate_limits").where("__name__", ">=", `${callerUid}_`).where("__name__", "<", `${callerUid}_\uf8ff`).get(),

    db.collection("contacts").where("linkedUid", "==", callerUid).get(),
    db.collection("wearable_device_credentials").where("userId", "==", callerUid).get(),
    db.collection("wearable_pairings").where("userId", "==", callerUid).get(),
  ]);

  const deleted = {};
  const ownDocs = own.flatMap((snap) => snap.docs);
  deleted.owned = await deleteDocs(ownDocs);
  deleted.responses = await deleteDocs(responses);
  deleted.deliveries = await deleteDocs(deliveries);
  deleted.invites = await deleteDocs(invites);
  deleted.rateLimits = await deleteDocs(rateLimits.docs);
  deleted.wearableCredentials = await deleteDocs(wearableCredentials.docs);
  deleted.wearablePairings = await deleteDocs(wearablePairings.docs);

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
