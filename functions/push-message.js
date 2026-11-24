/**
 * Builds FCM messages. Split out of index.js (which calls initializeApp() at
 * load) so the payload can be unit-tested; see test/push-message.test.js.
 *
 * Urgent pushes (an open SOS, a missed check-in, their re-pings, and the
 * caregiver test alert that checks this path) are sent to iOS as
 * time-sensitive. Without that, a caregiver's iPhone in a Focus or Sleep mode
 * delivers the SOS silently. Time-sensitive delivery also needs the
 * `com.apple.developer.usernotifications.time-sensitive` entitlement in
 * ios/Runner/Runner.entitlements.
 */

const URGENT_ALERT_TYPES = ["sos", "headsUpExpired"];

function isUrgentPush(alertType, alertStatus) {
  if (alertType === "test") return true;
  return alertStatus === "sent" && URGENT_ALERT_TYPES.includes(alertType);
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

  const urgent = isUrgentPush(alertType, alertStatus);
  const aps = {
    sound: "default",
    contentAvailable: true,
    "interruption-level": urgent ? "time-sensitive" : "active",
  };
  if (urgent) aps["relevance-score"] = 1;

  const message = {
    token,
    notification: { title, body },
    data,
    android: {
      priority: "high",
      notification: { sound: "seizure_alert" },
    },
    apns: {
      headers: { "apns-priority": "10", "apns-push-type": "alert" },
      payload: { aps },
    },
  };

  if (Number.isFinite(ttlMs) && ttlMs > 0) {
    message.android.ttl = ttlMs;
    message.apns.headers["apns-expiration"] = String(
      Math.floor(Date.now() / 1000) + Math.ceil(ttlMs / 1000)
    );
  }

  return message;
}

module.exports = { buildMessage, isUrgentPush };
