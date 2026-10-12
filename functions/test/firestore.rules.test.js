const { after, before, describe, test } = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");
const { doc, getDoc, setDoc } = require("firebase/firestore");

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
});

if (!emulatorAvailable) {
  test("Firestore emulator tests require FIRESTORE_EMULATOR_HOST", () => {
    assert.equal(emulatorAvailable, false);
  });
}
