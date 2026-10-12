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

The monthly `$1` budget for `seizure-alert-app` is configured with 50%, 90%,
and 100% actual-spend alerts. Its Pub/Sub notifications are connected to the
`seizure-alert-budget-alerts` topic for `disableFunctionsAtBudget` in
`functions/index.js` to run. At 100% (about `$1` actual monthly spend), it sets
`system/functionsConfig.enabled` to `false`; function handlers that check this
document stop their work within the 30-second cache window. The budget handler
has retries disabled to avoid repeated billed attempts; inspect its logs if a
notification delivery fails. Re-enable functions manually by setting `enabled`
to `true` after reviewing the spend and cause.

This is a project-wide emergency stop, not a precise billing cap: cost data and
notifications can be delayed, some cost can accrue before the switch takes
effect, and this does not stop Firestore client usage or fixed resource costs.
Cloud Billing publishes status updates to Pub/Sub multiple times per day, so the
budget handler can receive occasional event invocations even when spend is below
the threshold; it has no minimum instance and does not poll or run on a schedule.
Link the budget only in the intended development Firebase project. On the
current `seizure-alert-app` project it disables emergency alert functions too.

### Runtime limits

Second-generation functions have no minimum instances and a five-instance
maximum per function. Callable read/fan-out paths also have per-user rate limits
in `functions/index.js`. Each active Heads Up creates one delayed task for its
expiry; there is no idle scheduler or polling function. The Firestore kill
switch at `system/functionsConfig` disables function work after its cache
expires; it does not block Firestore client reads/writes.

The caregiver alert drill is entirely user initiated. It invokes
`sendCaregiverTestAlert` once, creates no alert or seizure document, records a
server-owned delivery result on each linked contact, and has no
timer or background worker. App Check and authentication are required; the
server selects accepted push-enabled contacts, caps the request at 20 unique
device tokens, and permits two attempts per user in ten minutes. Test pushes
expire after five minutes so a delayed notification cannot be mistaken for a
current drill.

## iOS Home Screen widget

The iOS widget uses WidgetKit and the `home_widget` package. It reads only the
privacy-safe status written by the app and opens the existing SOS countdown
through the `seizurealert://widget/sos` link. Its timeline does not poll or run
on a schedule, so the widget does not create Firebase activity while idle.

Apple requires the shared App Group to be registered before the widget can run
on a physical device or distribution build:

1. In the Apple Developer portal, create the App Group
   `group.com.darren.potts.seizureApp`.
2. Enable that App Group for both App IDs:
   `com.darren.potts.seizureApp` and
   `com.darren.potts.seizureApp.SeizureAlertWidget`.
3. On a Mac, open `ios/Runner.xcworkspace` in Xcode. Select the development team
   and signing profile for both the `Runner` and `SeizureAlertWidget` targets.
4. Confirm that both targets show
   `group.com.darren.potts.seizureApp` under Signing & Capabilities → App Groups.
5. Run the app once, then add **Seizure Alert** from the iOS widget gallery.

An active Apple Developer membership is required to register the App Group and
sign the extension. The native WidgetKit target must receive its final build
verification on macOS with Xcode.

## Android toolchain and support configuration

Android builds use Gradle 9.3.1, Android Gradle Plugin 9.1.0, Kotlin 2.4.0,
and Java 17. The Flutter compatibility flags in `android/gradle.properties`
retain the legacy Kotlin plugin and Android DSL for dependencies that still
require them. Debug and release builds use the same toolchain; release signing
is configured through the existing local key properties or environment values.

`lib/core/constants/support_config.dart` supplies temporary support defaults:
`potts.darren@gmaul.com` and `https://example.com/seizure-alert/privacy`.
The privacy URL is a placeholder. Override them without editing source:

```powershell
flutter build apk --release --dart-define=SUPPORT_EMAIL=your-support-address --dart-define=PRIVACY_URL=https://your-domain/privacy
```

For the Windows Java socket-directory workaround, see
`docs/production/validation-2026-10-12.md`.

## Safety readiness and Garmin companion

The Profile screen includes **Safety readiness**. It checks this phone's
network, push registration, location permission, connected caregivers, recent
caregiver delivery drills, and paired wearables. These checks describe current
setup state and do not claim guaranteed emergency delivery.

The Connect IQ companion source is in `garmin/`. It supports a user-started SOS
with a ten-second cancellation window, Heads Up timers, check-in, safety status,
and battery heartbeat. Pairing uses a short-lived six-digit code. The watch
exchanges that code for a revocable random credential; only a hash of the
credential is stored in Firestore.

Build the watch app with the Garmin Connect IQ SDK and a Garmin developer key.
The SDK is not included in this repository. See `garmin/README.md` for device
targets and build commands. Automatic seizure detection is intentionally out of
scope until it has a separately validated clinical and regulatory path.

## Safety plan, medication reminders, and reports

Users can save caregiver instructions, rescue-medication details, an emergency
call threshold, and daily on-device medication reminders under **Safety plan &
medication**. Reminders use local notifications and do not invoke Firebase while
idle. The optional nearby audible SOS notice is also generated locally.

Seizure records support type, severity, awareness, aura, injuries, recovery
time, and rescue-medication use. The log includes a monthly calendar and 90-day
summary, and can share a user-entered PDF and CSV report through the operating
system share sheet.

Unanswered alert escalation is event-driven. An alert schedules one delayed
task, then at most two further stages when nobody has responded. There is no
polling function, scheduler, or warm instance.
