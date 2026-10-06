# Seizure Alert

Flutter app for people with epilepsy and their caregivers.

## Firebase protection and cost controls

### App Check (Android and iOS)

`lib/main.dart` activates App Check before initializing the app's other Firebase
services. Debug builds use the App Check debug providers; release builds use
Play Integrity on Android and App Attest with Device Check fallback on iOS.
Every callable in `functions/index.js` enforces App Check.

Before releasing this configuration:

1. In Firebase Console → App Check, register the Android app with Play Integrity
   and the iOS app with App Attest/Device Check.
2. Run each debug app once, register its generated debug token in App Check, and
   keep debug tokens out of source control.
3. Release the updated mobile app before deploying callable enforcement so
   existing installations have a client that sends App Check tokens.
4. Review App Check metrics, then enable enforcement for Cloud Firestore in the
   Firebase Console. Callable enforcement is configured in the function code.

Web builds do not initialize App Check. Callable functions require App Check,
so web callable access is unavailable until a web provider is configured.

### Billing alerts

The monthly `$10` budget for `seizure-alert-app` is configured with 50%, 90%,
and 100% actual-spend alerts. Its Pub/Sub notifications must be connected to the
`seizure-alert-budget-alerts` topic for `disableFunctionsAtBudget` in
`functions/index.js` to run. At 100%, it sets `system/functionsConfig.enabled`
to `false`; function handlers that check this document stop their work within
the 30-second cache window. Re-enable functions manually by setting `enabled`
to `true` after reviewing the spend and cause.

This is a project-wide emergency stop, not a precise billing cap: cost data and
notifications can be delayed, some cost can accrue before the switch takes
effect, and this does not stop Firestore client usage or fixed resource costs.
Link the budget only in the intended development Firebase project. On the
current `seizure-alert-app` project it disables emergency alert functions too.

### Runtime limits

Second-generation functions have a five-instance maximum per function. Callable
read/fan-out paths also have per-user rate limits in `functions/index.js`. The
Heads Up expiry sweep runs once per minute and processes at most 200 records per
run. The Firestore kill switch at `system/functionsConfig` disables function
work after its cache expires; it does not block Firestore client reads/writes.
