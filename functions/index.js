const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

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

function buildMessage({ token, title, body, alertId, alertType, userId }) {
  return {
    token,
    notification: { title, body },
    data: {
      alertId: String(alertId),
      alertType: String(alertType),
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

    if (!phone) return;

    const userSnap = await db
      .collection("users")
      .where("phone", "==", phone)
      .limit(1)
      .get();

    if (userSnap.empty) return;

    const fcmToken = userSnap.docs[0].data().fcmToken;
    if (!fcmToken) return;

    const message = buildMessage({
      token: fcmToken,
      title: copy.title,
      body: copy.body,
      alertId: alert.id,
      alertType: alert.type,
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
