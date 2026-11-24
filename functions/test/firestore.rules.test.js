const { after, before, describe, test } = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");
const { doc, getDoc, setDoc, updateDoc, deleteDoc, collection, getDocs, query, where, orderBy } = require("firebase/firestore");

const emulatorAvailable = Boolean(process.env.FIRESTORE_EMULATOR_HOST);
const suite = emulatorAvailable ? describe : describe.skip;

suite("Firestore authorization", () => {
  let environment;

  before(async () => {
    environment = await initializeTestEnvironment({
      projectId: "demo-seizure-alert",
      firestore: {
        rules: fs.readFileSync(
          path.resolve(__dirname, "..", "..", "firestore.rules"),
          "utf8"
        ),
      },
    });

    await environment.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, "users", "patient"), {
        email: "patient@example.invalid",
      });
      await setDoc(doc(db, "alert_responses", "response"), {
        alertOwnerId: "patient",
        responderId: "caregiver",
        alertId: "alert",
      });
    });
  });

  after(async () => {
    await environment?.cleanup();
  });

  test("users can read only their own profile", async () => {
    const owner = environment.authenticatedContext("patient").firestore();
    const stranger = environment.authenticatedContext("stranger").firestore();
    await assertSucceeds(getDoc(doc(owner, "users", "patient")));
    await assertFails(getDoc(doc(stranger, "users", "patient")));
  });

  test("cycle health data is accessible only to its owner", async () => {
    const owner = environment.authenticatedContext("patient").firestore();
    const caregiver = environment.authenticatedContext("caregiver").firestore();
    const anonymous = environment.unauthenticatedContext().firestore();
    await assertSucceeds(setDoc(doc(owner, "users", "patient"), {
      cycleTracking: { enabled: true, revision: 1, entries: [{
        id: "period", start: "2026-10-14T00:00:00.000", end: "2026-10-18T00:00:00.000",
        flow: "medium", symptoms: "Fictional sample", notes: "Private"
      }] }
    }, { merge: true }));
    await assertSucceeds(getDoc(doc(owner, "users", "patient")));
    await assertFails(getDoc(doc(caregiver, "users", "patient")));
    await assertFails(getDoc(doc(anonymous, "users", "patient")));
    await assertFails(setDoc(doc(caregiver, "users", "patient"), {
      cycleTracking: { enabled: false }
    }, { merge: true }));
  });

  test("daily records enforce ownership, shape, revision and deletion boundaries", async () => {
    const owner = environment.authenticatedContext("patient").firestore();
    const caregiver = environment.authenticatedContext("caregiver").firestore();
    const anonymous = environment.unauthenticatedContext().firestore();
    const path = "users/patient/dailyLogs/2026-10-23";
    const data = { date: "2026-10-23", revision: 1, updatedAt: "2026-10-23T09:00:00Z", noSeizuresReported: false, sideEffects: "", notes: "Private", sleepMinutes: 420, mood: "low" };
    await assertSucceeds(setDoc(doc(owner, path), data));
    await assertSucceeds(getDoc(doc(owner, path)));
    for (const db of [caregiver, anonymous]) {
      await assertFails(getDoc(doc(db, path)));
      await assertFails(setDoc(doc(db, path), {...data, revision: 2}));
      await assertFails(deleteDoc(doc(db, path)));
      await assertFails(getDocs(collection(db, "users/patient/dailyLogs")));
    }
    await assertSucceeds(getDocs(query(collection(owner, "users/patient/dailyLogs"), where("date", ">=", "2026-10-01"), where("date", "<=", "2026-10-31"), orderBy("date", "desc"))));
    await assertFails(setDoc(doc(owner,path), data));
    for (const invalid of [{sleepMinutes:1441}, {mood:"excellent"}, {notes:"x".repeat(501)}, {extra:"secret"}, {date:"2026-10-22"}]) {
      await assertFails(setDoc(doc(owner,path), {...data, revision:2, ...invalid}));
    }
    await assertSucceeds(setDoc(doc(owner,path), {...data, revision:2, mood:"good"}));
    await assertSucceeds(deleteDoc(doc(owner,path)));
    const orphanOwner = environment.authenticatedContext("orphan").firestore();
    await assertFails(setDoc(doc(orphanOwner,"users/orphan/dailyLogs/2026-10-23"),data));
  });

  test("clients cannot assign linkedUid", async () => {
    const owner = environment.authenticatedContext("patient").firestore();
    await assertFails(
      setDoc(doc(owner, "contacts", "contact"), {
        userId: "patient",
        name: "Caregiver",
        phone: "082 123 4567",
        phoneNormalized: "+27821234567",
        linkedUid: "stranger",
      })
    );
  });

  test("alert responses are readable only by both participants", async () => {
    const owner = environment.authenticatedContext("patient").firestore();
    const caregiver = environment.authenticatedContext("caregiver").firestore();
    const stranger = environment.authenticatedContext("stranger").firestore();
    await assertSucceeds(getDoc(doc(owner, "alert_responses", "response")));
    await assertSucceeds(
      getDoc(doc(caregiver, "alert_responses", "response"))
    );
    await assertFails(getDoc(doc(stranger, "alert_responses", "response")));
  });

  test("clients cannot write alert responses or rate limits", async () => {
    const caregiver = environment.authenticatedContext("caregiver").firestore();
    await assertFails(
      setDoc(doc(caregiver, "alert_responses", "forged"), {
        alertOwnerId: "patient",
        responderId: "caregiver",
        alertId: "alert",
      })
    );
    await assertFails(
      setDoc(doc(caregiver, "rate_limits", "caregiver_test"), { count: 0 })
    );
  });

  const alert = (id, extra = {}) => ({
    id,
    userId: "patient",
    type: "sos",
    status: "sent",
    createdAt: "2026-11-23T08:00:00.000Z",
    ...extra,
  });

  test("patients create SOS and Heads Up alerts, never missed check-ins", async () => {
    const owner = environment.authenticatedContext("patient").firestore();
    await assertSucceeds(setDoc(doc(owner, "alerts", "sos-1"), alert("sos-1")));
    await assertSucceeds(
      setDoc(doc(owner, "alerts", "hu-1"), alert("hu-1", { type: "headsUp" }))
    );
    await assertFails(
      setDoc(
        doc(owner, "alerts", "missed-1"),
        alert("missed-1", { type: "headsUpExpired" })
      )
    );
  });

  test("nobody else can create, read or change a patient's alert", async () => {
    const stranger = environment.authenticatedContext("stranger").firestore();
    await assertFails(setDoc(doc(stranger, "alerts", "forged"), alert("forged")));
    await environment.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), "alerts", "sos-2"), alert("sos-2"));
    });
    await assertFails(getDoc(doc(stranger, "alerts", "sos-2")));
    await assertFails(updateDoc(doc(stranger, "alerts", "sos-2"), { status: "cancelled" }));
  });

  test("a closed alert cannot be reopened or changed", async () => {
    const owner = environment.authenticatedContext("patient").firestore();
    await environment.withSecurityRulesDisabled(async (context) => {
      await setDoc(
        doc(context.firestore(), "alerts", "closed-1"),
        alert("closed-1", { status: "cancelled", resolvedAt: "2026-11-23T08:05:00.000Z" })
      );
    });
    await assertFails(updateDoc(doc(owner, "alerts", "closed-1"), { status: "sent" }));
  });

  test("a missed check-in can only be closed by the patient saying they are OK", async () => {
    const owner = environment.authenticatedContext("patient").firestore();
    await environment.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, "alerts", "missed-2"), alert("missed-2", { type: "headsUpExpired", resolvedAt: null }));
      await setDoc(doc(db, "alerts", "missed-3"), alert("missed-3", { type: "headsUpExpired", resolvedAt: null }));
    });
    await assertFails(
      updateDoc(doc(owner, "alerts", "missed-2"), { status: "cancelled" })
    );
    await assertFails(
      updateDoc(doc(owner, "alerts", "missed-2"), {
        status: "resolved",
        resolvedAt: "2026-11-23T09:00:00.000Z",
        locationLabel: "Edited",
      })
    );
    await assertSucceeds(
      updateDoc(doc(owner, "alerts", "missed-3"), {
        status: "resolved",
        resolvedAt: "2026-11-23T09:00:00.000Z",
      })
    );
  });

  test("each device can register its own push token, only on its own profile", async () => {
    const owner = environment.authenticatedContext("patient").firestore();
    const stranger = environment.authenticatedContext("stranger").firestore();
    await assertSucceeds(
      updateDoc(doc(owner, "users", "patient"), {
        fcmToken: "tablet",
        "fcmTokens.phone": 1,
        "fcmTokens.tablet": 2,
      })
    );
    await assertFails(
      updateDoc(doc(stranger, "users", "patient"), { "fcmTokens.attacker": 3 })
    );
  });
});

if (!emulatorAvailable) {
  test("Firestore emulator tests require FIRESTORE_EMULATOR_HOST", () => {
    assert.equal(emulatorAvailable, false);
  });
}
