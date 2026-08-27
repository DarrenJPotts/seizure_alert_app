# Progress Tracker

Update this file after every completed feature. Any AI agent reading this should immediately know what is done, what is in progress, and what is next.

---

## Current Status

**Phase:** Phase 5 — Polish & Reliability
**Last completed:** 31 POPIA groundwork (consent capture, complete erasure, PI out of logs)
**Next:** 21 Offline resilience, then stale-FCM-token cleanup and critical-alert delivery (see Known Gaps)

> ## ⚠ Deploy order for Features 27 + 28 — read before shipping
>
> Feature 28 changes how *every* cross-user read is authorized. Getting the order wrong locks
> existing caregivers out of the watch list and the incoming-alert screen.
>
> **This is not optional and has already bitten once.** `expireHeadsUpWindows` failed ~4000 times over
> ~3 days because the `headsUp (status, expiresAtMs)` index was declared here but never deployed. Every
> run threw FAILED_PRECONDITION, so no missed check-in escalated in that window, and nothing alerted.
>
> 1. **`firebase deploy --only firestore:indexes`** — wait for the new `contacts (linkedUid, userId)`
>    index to finish building. The functions in step 2 query it; deploying them first makes every
>    caregiver call fail.
> 2. **`firebase deploy --only functions`** — switches authorization to `linkedUid`, adds
>    `submitAlertResponse` and `nudgeResponder`, and starts stamping `linkedUid` on invite accept.
> 3. **Run the backfill immediately afterwards.** Between steps 2 and 3 every caregiver whose invite
>    predates this change sees an empty watch list:
>    ```
>    GOOGLE_APPLICATION_CREDENTIALS=./service-account.json node scripts/backfill-linked-uid.js
>    GOOGLE_APPLICATION_CREDENTIALS=./service-account.json node scripts/backfill-linked-uid.js --apply
>    ```
>    Dry-run first and read the counts. `--strict` restricts links to explicit accepted invites only.
> 4. **Ship the client.**
> 5. **`firebase deploy --only firestore:rules` last**, once the client rollout is substantially
>    complete. These rules deny direct client writes to `alert_responses`; any user still on an older
>    build loses "I'm responding" (reads and SOS are unaffected) until they update.

---

## Progress

### Phase 1 — Foundation

- [x] 01 Project setup
- [x] 02 Auth — Login
- [x] 03 Auth — Sign Up
- [x] 04 Onboarding (3-step: name, first contact, permissions)
- [x] 05 Root scaffold (5-tab nav, monitoring badge)

### Phase 2 — Core Safety Features

- [x] 06 SOS alert (button, start/cancel, elapsed timer, GPS, Firestore, SharedPreferences)
- [x] 07 Heads Up (30/60/120 min timer, start/cancel/check-in, auto-expiry, Firestore)
- [x] 08 Cloud Functions (onAlertCreated + onAlertUpdated → FCM to contact circle)

### Phase 3 — Data & Log

- [x] 09 Seizure log — List view
- [x] 10 Seizure log — Add entry (bottom sheet with date, duration, trigger, location, notes)
- [x] 11 Contacts — List view (swipe-to-delete, priority order)
- [x] 12 Contacts — Add/edit contact (bottom sheet)

### Phase 4 — Dashboard & Profile

- [x] 13 Home — Dashboard (greeting, days-since hero, 7-day count, monthly count, 28-day grid)
- [x] 14 Profile — View (medical info, permission status cards)
- [x] 15 Profile — Edit (bottom sheet, Firestore update; phone number field added, email change via dedicated re-auth flow — see Notes)

### Phase 5 — Polish & Reliability

- [x] 16 Alert history
- [x] 17 Contact responses (real-time alert_responses stream)
- [x] 18 App invite (SMS/WhatsApp/clipboard picker from add-contact sheet + contact card send-invite icon)
- [x] 19 Notification deep-link (SOS alerts only — tapping a "sent"-status SOS push opens Incoming Alert; Heads Up/expired notifications still just open the app, no dedicated screen to deep-link into yet)
- [x] 20 Firestore security rules audit
- [ ] 21 Offline resilience
- [x] 22 Caregiver mode (SOS send-countdown + active-alert screen redesign, "People I watch" list, Incoming Alert detail screen)
- [ ] 31 POPIA groundwork — code side done; notice text, data residency and Information Officer registration outstanding
- [x] 30 Onboarding before sign-up (draft held in the view model, five-step progress bar)
- [x] 29 Grouped-card settings language (shared `core/widgets/settings/`, Profile + Seizure Log restyled)
- [x] 28 Security hardening (linkedUid authorization, invite enumeration, alert-response forgery, rate limiting)
- [x] 27 Splash screen + full caregiver mode (per-device role switch, watch list, incoming SOS, respond/shared view) + monochrome live indicator
- [x] 23 Circle invites (in-app invite for contacts who already have the app — gated `ContactDto.status`, `sendCircleInvite`/`respondToInvite` Cloud Functions, `CircleInviteView` accept/decline screen, Home banner)

---

## Notes

- Feature 31 (POPIA groundwork): **the code side only. This does not make the app POPIA compliant** —
  it makes compliance possible. The outstanding items are not code and are listed at the end.

  **Consent (s26/s27).** Seizure type, medications, blood type and emergency notes are health
  information, which POPIA classes as *special personal information*: processing is prohibited outright
  unless an s27 exception applies, and for an app that is not a healthcare provider that means the data
  subject's explicit consent. There was none — a grep for consent/privacy/terms/policy across `lib/`
  returned nothing.

  There is now a fourth onboarding step (`OnboardingStepConsent`), placed last, before sign-up. The
  checkbox starts unticked, the primary button is disabled until it is ticked, and there is no skip —
  consent has to be a positive act, and since nothing is written before this point, declining costs the
  user only the account they have not created. Consent is recorded on the user document as
  `privacyConsentAt` + `privacyConsentVersion`, because s11(2) puts the burden of *proving* consent on
  the responsible party. `commitDraft` refuses to write at all without it, duplicating the UI gate on
  purpose: that function is the single place the draft is persisted.

  Progress is now six steps rather than five. `PrivacyNotice.version` must be bumped on any material
  change to what is collected, why, or where it goes — a stored consent against an older version is not
  consent to the current terms, and Profile > Privacy shows "Update available" when they diverge.

  **Erasure (s24).** `FirestoreService.deleteAllUserData` is gone. It only deleted documents matching
  `userId == uid`, which silently left behind everything that identifies a user by another field:
  `alert_responses` (responderId / alertOwnerId — including their name and free-text notes), `invites`
  (senderUid / recipientUid), and `rate_limits`. None of those are even queryable from a client under
  `firestore.rules`, so a complete erasure was impossible from where it was written. Replaced by a
  `deleteMyData` callable running under the Admin SDK, called *before* the Firebase Auth user is deleted
  (the callable authenticates as them). There is deliberately no uid parameter — an erasure endpoint
  that took one would be a way to delete other people's records.

  One deliberate non-deletion: contact rows *other* users hold for the departing person keep their name
  and number. That is somebody else's emergency contact list, typed in by them, and silently removing an
  emergency contact from a patient's circle is a safety change rather than a privacy one. What is
  removed is `linkedUid` (so no cross-user read access survives) and `status` goes back to `pending`.
  With the account gone `findUserByPhone` no longer resolves either, so no further notification reaches
  them. **Whether the residual name/number must also go is a policy question for legal advice**, not
  one to settle in code.

  **Personal information in logs (s19).** `functions/index.js` wrote phone numbers to Cloud Logging in
  three places. Cloud Logging is retained by default and readable by anyone with project access, so
  those were copies of personal information sitting outside the database *and* outside the erasure path
  — they would have survived a s24 request. All three now log the contact document id, which is equally
  debuggable and not identifying on its own.

  **Also:** the Profile > Privacy row is back, with a real destination this time (it was removed in
  Feature 29 for doing nothing when tapped). s17/s18 require the notice to be *available*, not merely
  agreed to once.

  Coverage: `test/features/onboarding/onboarding_flow_test.dart` pins the consent gate (starts unticked,
  blocks the last step, withdrawable, and is the only step with no way past it). **`deleteMyData` has no
  automated coverage** — it is a callable, so neither the Dart suite nor fake_cloud_firestore can reach
  it. An emulator test is specified in `test/README.md`.

  **Not done, and not code:**
  - `PrivacyNotice` text is a developer placeholder and says so in the file. It is structured against
    the s18 disclosure headings so nothing structural is missing, but the wording, the named responsible
    party, the retention period and the transborder position all need a lawyer.
  - **Data residency.** Functions have no region set, so `us-central1`; Firestore is presumably US too.
    That engages s72 (transborder flows) and possibly **s57(1)(d)** — prior authorisation from the
    Information Regulator to send special personal information abroad. A Firestore database's location
    is **fixed at creation**, so if SA residency is ever required it means a new project and a
    migration. Decide early; it only gets worse with real users.
  - No age gate (s34/s35). Childhood epilepsy plus caregiver mode is an obvious use case, and processing
    a child's information needs a competent person's consent.
  - No retention policy (s14). Seizure logs and alerts accumulate indefinitely.
  - No data export (s23 right of access).
  - Information Officer registration with the Information Regulator (s55/s56), Google's Cloud Data
    Processing Addendum as the operator agreement (s20/s21), PAIA manual, breach procedure.
  - **s19 exposure still undeployed:** the Feature 28 fixes are written but not shipped. Until they are,
    any signed-in user can read any other user's live GPS and medical ID. If that has been live with
    real users, s22 breach notification may already be engaged — a question for legal, not for here.

- Heads Up sweep outage (ops, not a feature): `expireHeadsUpWindows` had been throwing
  FAILED_PRECONDITION on every run for ~3 days — ~4000 invocations — because its composite index was
  declared in `firestore.indexes.json` but never deployed. For that whole period **no missed check-in
  escalated**, and nothing surfaced it: the function's only failure signal was a log line nobody was
  watching.

  Two changes came out of it.

  **A staleness guard before the backlog fires.** Deploying the index would have let the first
  successful run escalate up to `HEADS_UP_SWEEP_LIMIT` (200) windows at once, pushing "Check-in Missed"
  for windows that closed days ago. That is not a late alert, it is a false alarm, and a caregiver who
  receives a few of those learns to disregard the one channel this app exists to keep credible.
  `isEscalationStale` (`functions/time.js`, tested in `functions/test/heads-up-sweep.test.js`) closes
  any window more than `HEADS_UP_ESCALATION_GRACE_MS` (1 hour) late *without* notifying, and the sweep
  logs the suppressed count at warn. An hour still escalates through any realistic transient outage.
  The check runs before the origin-alert read, so a large backlog costs one write per document rather
  than a read, a transaction and a push.

  **The real lesson is monitoring.** This sweep is the *guarantee* behind Heads Up escalation — Feature
  24 deliberately moved that off the client `Timer` precisely so it could not be missed — and it was
  down for three days undetected. A non-zero suppressed count in the logs now means the sweep was not
  running when it should have been, but that is a symptom to notice, not an alert. **Still to do: a
  Cloud Monitoring log-based alert on ERROR severity for this function.** Without it the same class of
  silent failure recurs.

  Not a scaling problem, despite the invocation count: 1440 runs/day against a 2M/month free tier is
  noise. See the architecture note below.

- Firebase vs Supabase/PocketBase (decision, revisit if the triggers below fire): staying on Firebase.
  The friction in this codebase is not throughput — the data volumes are tiny and Firestore would carry
  them at any realistic user count. It is that Firestore rules cannot express this app's core
  relationship, a many-to-many patient/caregiver graph. Rules only compare fields on the document being
  read, so every cross-user read became an admin-SDK callable: `getPeopleIWatch`, `getAlertDetail`,
  `nudgeResponder`, `submitAlertResponse`. Four functions that exist only to hand-roll authorization —
  and Feature 28 found that hand-rolled authorization was wrong in a way that exposed live location and
  medical data. In Postgres the same rule is one RLS policy with a subquery, enforced by the database.

  Against that: the product *is* push delivery, and neither Supabase nor PocketBase has a push service,
  so FCM stays either way — a migration splits the stack rather than replacing it. Firestore's offline
  persistence is also most of unstarted Feature 21. PocketBase is the wrong shape entirely for a
  safety-critical app: self-hosting single-node SQLite means owning uptime, failover and patching for a
  system whose failure mode is someone not getting help.

  **Revisit if:** cross-user reporting is needed (Firestore is genuinely bad at it), the callable count
  passes roughly ten (the authorization surface stops being reviewable), or function invocations start
  dominating cost.

- Feature 30 (Onboarding before sign-up): the flow now runs **onboarding → sign-up**, not the reverse,
  and a five-step progress bar spans both.

  **Route order.** `SplashViewModel` makes a three-way decision: signed in → shell; signed out but
  `onboardingCompleted` set on this device → sign-in; otherwise → onboarding. `AuthMiddleware` came off
  the onboarding route, because the user is now deliberately unauthenticated for most of it. Onboarding
  carries an "I already have an account" link so a returning user on a fresh install is not trapped.

  **The draft never touches Firestore before an account exists.** `OnboardingViewModel` holds the
  answers; `SignupViewModel.register` calls `OnboardingViewModel.commitAndDisposeDraft()` immediately
  after the account is created, and that is the only place they are persisted. Writing a profile earlier
  would leave a document keyed to no uid behind every abandoned run.

  That forces the view model to be registered **permanent** (`OnboardingBinding`): the last onboarding
  step pushes Signup, and under `SmartManagement.full` a route-scoped controller is disposed on that
  navigation — the user's answers would vanish between typing them and the account being created. It is
  deleted explicitly once committed, and `LoginViewModel` calls `discardDraft()` on a successful sign-in
  so a draft cannot attach itself to an account it was not typed for.

  **Progress bar** (`lib/core/widgets/onboarding_progress.dart`, five steps: Welcome, Your name,
  Emergency contact, Permissions, Create account). It lives in `core/widgets` because the run spans two
  features — a bar that reset at the account screen would tell the user the flow had restarted.
  `OnboardingStep.welcome` has no screen and is counted as done from the first frame, so a new user's
  first sight of the app is a bar with progress on it (the endowed-progress effect, and the actual reason
  for reordering the flow). It is labelled honestly — opening the app *is* that step — and nothing about
  the user's data or obligations is misrepresented by counting it. **Do not extend the trick to a step
  that asks something of the user.**

  **Two paths still write a profile.** `OnboardingMode.preSignup` is the normal one. `completeProfile`
  is the recovery path for a user who is signed in with no Firestore profile — an account made on the old
  build, or a draft commit that failed — reached from `RootViewModel._checkOnboarding`. In that mode the
  final button says "Finish setup" and writes directly instead of routing to Signup. A failed commit
  during sign-up deliberately still lands on the shell: the account is real and the user is signed in, so
  the shell finds no profile and reopens onboarding with the draft intact rather than stranding them.

  The emergency contact is required to advance in onboarding but *optional* in `commitDraft` — a user who
  reaches Signup without one still needs a profile, and refusing to write it would leave them on a screen
  with no way forward.

  Covered by `test/features/onboarding/onboarding_flow_test.dart` (step arithmetic, advance gating, mode
  labelling, bar rendering and its semantics). Not covered: that nothing is written before sign-up, and
  `commitDraft`'s empty-uid guard — both go through `FirebaseAuth.instance`/`FirestoreService`, which
  throw without an initialised Firebase app. That needs the emulator.

- Feature 29 (Grouped-card settings language): the Mode screen's look, extended to Profile and Seizure
  Log at the user's request. The widgets moved from `lib/features/mode/widgets/` to
  `lib/core/widgets/settings/` — three screens share them now, so a change for one reshapes the others.
  Full spec in `ui-registry.md`; covered by `test/widgets/settings_group_test.dart`.

  **Profile.** `ProfileSection`/`ProfileItem` are gone. Their 130px fixed label column truncated
  "Emergency Note" and squeezed the value into what was left — the worst field to do that to, since it
  doubles as the care plan a caregiver reads on arrival. `SettingsValueRow` gives the label its natural
  width and lets the value wrap to three lines. Sections are now Contact info / Medical ID / Settings /
  a destructive group, with the identity block as a card at the top.

  Two behaviour changes worth knowing: the **Privacy** row was removed (it was `tappable: true` with no
  `onTap` — a row that did nothing when pressed), and **Phone** now opens Edit profile rather than being
  inert, which is where the number is actually saved. Delete account moved from a red outlined button to
  a `SettingsDestructiveRow`; the confirm sheet is unchanged.

  **Seizure Log.** `SeizureLogCard` is gone; entries are `SettingsTileRow`s grouped into one section per
  month, captioned "This month · 3 entries". The month caption is the one section header in the app that
  carries data rather than just labelling — comparing a month against the one before it is the question
  this screen exists to answer, and a flat list of dated cards never showed it. Date/duration formatting
  moved to `seizure_log_row.dart` and is now covered by
  `test/features/seizure_log/seizure_log_format_test.dart`, which it never was inside the old card.

  **Adjacent fix — remaining timestamp document ids.** Feature 28 replaced
  `millisecondsSinceEpoch.toString()` ids for alerts and Heads Up; the same pattern was still in
  `SeizureLogViewModel.addEntry`, `ContactsViewModel`, and `OnboardingViewModel`. No security angle —
  those collections are owner-only — but `.doc(id).set()` on a colliding id is an owner-allowed *update*,
  so two writes in the same millisecond silently overwrite the earlier one. Losing a logged seizure from
  a medical record is worth two lines to prevent, and leaving half the codebase on each pattern invites
  the next person to guess wrong.

  **`pubspec.yaml` was broken on arrival and is repaired.** A partially-applied `flutter_native_splash`
  edit had deleted the `dependencies:` key entirely (every package was nested under `environment:`), left
  `sdk: flutter.` with a trailing period under `flutter_test`, and left `color:` empty. Nothing resolved
  — `flutter analyze` reported 221 unresolved-import errors. Restored the key, fixed the typo, and set
  the splash colour to `#000000` so it matches `SplashBody`; that also closes the white-flash gap flagged
  in the Feature 27 notes. **Run `dart run flutter_native_splash:create` to generate the native screens
  — that has not been done yet.**

- Feature 28 (Security hardening): findings from a `/vibe-security` audit of the Feature 27 tree.
  Two of them were introduced by Feature 27; the rest were older and that pass widened their blast
  radius.

  **Critical — cross-user access was authorized by a self-asserted phone number.** `getPeopleIWatch`,
  `getAlertDetail` and `nudgeResponder` all read the caller's own `users/{uid}.phone` and matched it
  against contact documents. Signup is email/password, there is no phone verification anywhere in the
  app, and `firestore.rules` lets a user write their own document — so anyone could set their phone to
  a number they knew was on somebody's contact list and read that person's live SOS coordinates,
  medical ID, emergency note, medications and responder roster. One Firestore write and one function
  call, no brute force.

  Fixed by moving authorization onto `contacts.linkedUid`: the verified uid of the person who accepted
  the invite, stamped by `respondToInvite` under the Admin SDK at the moment they authenticated *and*
  consented. `findLinkedContacts` in `functions/index.js` is now the single authorization primitive;
  `findContactsByPhone` was deleted rather than left lying around, because a dead helper with that name
  is an invitation to reintroduce the bug. `firestore.rules` pins `linkedUid` on contact create and
  update so clients can never write it, and `upsertContact` moved to `SetOptions(merge: true)` so a
  client-side contact edit cannot blank it. Phone matching still does *discovery* in
  `sendCircleInvite` — that is fine; it must simply never again grant read access.

  **High — `sendCircleInvite` never bound `phone` to `contactId`.** Only the contact was checked
  against the caller, so one owned contact could be replayed with any number: an oracle for "does this
  number have an account on an epilepsy app", and a push relay that fired a real notification at each
  hit. Now rejects any `phone` that does not match the contact's own number, plus a 10/hour cap.

  **High — alert responses were forgeable.** The old rules proved the writer was not impersonating
  another *responder*, but `alertId` and `alertOwnerId` were both attacker-supplied strings, so nothing
  tied the writer to the alert. Combined with the ID weakness below, anyone who knew a victim's uid
  could forge "&lt;name&gt; is responding" onto their live SOS — and a false *help is on the way* during a
  seizure is worse than no information, because the real caregivers reading the same roster stand down.
  All writes now go through a `submitAlertResponse` callable that derives `alertOwnerId`, `contactId`
  and `contactName` server-side and bounds the note at 2000 characters; `firestore.rules` denies client
  create/update on the collection, and `FirestoreService.upsertAlertResponse` was removed.

  **High — alert ids were wall-clock milliseconds.** `DateTime.now().millisecondsSinceEpoch.toString()`
  in both `SosViewModel.startSos` and `HeadsUpViewModel`. Roughly 60,000 candidates for a known minute,
  which is what made the forgery above practical. Independently of any attacker it was also a safety
  bug: two people seizing in the same millisecond produced the same document id, and the second
  `create` was denied by the ownership rule — that SOS silently never reached anyone. Both now use
  Firestore-generated ids, which are produced offline and add no latency to the SOS path.

  **Medium — no rate limiting on any callable.** `enforceRateLimit` uses a `rate_limits` collection
  that `firestore.rules` denies to all clients; a counter the caller can reset is not a counter.
  Applied to `nudgeResponder` (3 per 10 min — it sends a high-priority push with sound) and
  `sendCircleInvite` (10 per hour). This also matters for the Feature 25 cost problem: `getAlertDetail`
  is deliberately uncached and costs several reads per call.

  **Medium — push payloads could drive arbitrary navigation.** `Get.toNamed(data['route'])` with no
  allowlist in `firebase_messaging_service.dart`. Not remotely triggerable (sending to these tokens
  needs the project's server credentials) and the branch appeared to be dead, but it is replaced with
  an explicit allowlist.

  Checked and clean: no hardcoded secrets, no tracked `.env`, `key.properties`/`*.jks` correctly
  ignored, `respondToInvite` correctly authorized, owner-scoped collections all scope on uid rather
  than `if request.auth != null`, and no SQL/ORM injection surface. `google-services.json` and
  `firebase_options.dart` being committed is fine — Firebase client config is public by design and the
  security boundary is the rules.

  Still open, deliberately: contact **discovery** by phone is unverified, so a user can still assert a
  phone they do not own. That no longer grants read access, but it does mean a mistyped number can send
  an invite to the wrong person — the recipient has to accept before anything is shared, which is the
  intended safeguard. Firebase Phone Auth would close it properly.

- **Feature 26 status correction.** The entry below describes the M3 redesign as completed and warns that
  `CLAUDE.md` and `context/ui-*.md` no longer match the code. Neither is true of this working tree: there
  is no `lib/core/themes/status_colors.dart`, no `ReadinessCard`, `app_theme.dart` is still the bespoke
  monochrome theme seeded from `AppColorsLight`, and the floating pill nav is still in place. The code is
  on the black-and-white system the design docs describe. Feature 27 was built against the code as it
  actually is. Treat the Feature 26 note as a design proposal, not a record of shipped work.

- Feature 27 (Splash + full caregiver mode): implements turn 5 of the `Seizure Alert - Screens.dc.html`
  Claude Design project, plus option 2f-ii from the turn-2 colour study.

  **Live indicator.** `Colors.greenAccent` is gone. `lib/core/widgets/live_indicator.dart` replaces it
  with an expanding monochrome ring (`LiveIndicator`) and its labelled pairing (`LiveStatusLabel`). The
  green dot was the lowest-contrast element on every screen it appeared on, read as a consumer-app accent
  rather than a clinical status, and carried no meaning for a colour-blind user or in bright sun. Because
  *motion* is now the entire signal, `MediaQuery.disableAnimationsOf` is handled explicitly — with
  reduce-motion on, the ring is drawn static at full extent rather than collapsing to a bare dot. That
  path is covered in `test/widgets/live_indicator_test.dart`; it is a correctness case, not polish.

  **Splash.** `lib/features/splash/` is now the initial route. It also fixes a real cold-start race:
  `AuthMiddleware` reads `FirebaseAuthController.isLoggedIn`, which is seeded asynchronously by
  `userChanges()`, so a signed-in user could be bounced to the login screen on a slow start. The splash
  awaits `authStateChanges().first` before routing. `SplashBody` is shared with `RootView`'s not-ready
  state so the handover does not flash black to white. Minimum display is 800 ms — deliberately short,
  since a caregiver opening this app is often mid-emergency. **The native launch screens are still
  white**, so there is a white flash before the Flutter splash paints; fixing that means editing
  `android/app/src/main/res/values/styles.xml` and the iOS `LaunchScreen.storyboard`, left alone here as
  a platform-config change outside this pass.

  **Caregiver mode** is a per-device switch (`lib/core/services/app_mode_service.dart`, SharedPreferences),
  not an account field: the same account can be signed in on the phone the person carries and on a tablet
  a family member watches from, and only the second should hide the SOS. `RootView` now builds one of two
  shells. The caregiver shell drops the app bar (the watch list draws its own header), drops the elevated
  SOS button, and runs four destinations — watch list, alerts, log, profile. `RootViewModel` resets
  `currentIndex` on every mode switch, because the two shells have different tab counts and a stale index
  would point off the end of the `IndexedStack`.

  **Screens.** `ModeView` (5b, reached from Profile then Mode), `CaregiverView` rewritten as the watch
  list (5c), `IncomingAlertView` rewritten (5d), and a new `RespondingView` (5e).

  **Where the design showed data the app does not have**, the UI omits it rather than inventing it. Each
  of these is a real product gap, not an oversight:
  - *"Meds: On time"* and *"Battery: 72%"* chips (5c): there is no medication-adherence tracking and no
    battery reporting. The card shows Seizure-free and Last alert instead, omitting either if unknown.
  - *"updated 2 min ago"* (5c): there is no presence or heartbeat signal. The status line says "All
    clear", which is what the data supports — nothing has been raised — not that the person was seen.
  - *"Rescue med: Midazolam"* (5d): `UserDto.medications` is an unordered list with no rescue-dose flag.
    Labelled "Medication", showing the first entry. Guessing wrong on that screen would be dangerous.
  - *Care plan* (5e): rendered from the owner's own `emergencyNote`, split per line with any numbering
    they typed stripped (`OwnerProfileDto.carePlanSteps`). If they wrote no note the section shows an
    empty state. It deliberately does **not** fall back to generic seizure first aid — text this app
    invented would be indistinguishable from instructions their neurologist gave them.
  - *"She sent an SOS"* (5d): the app never asks for gender, so the copy uses the person's name.
  - *"Auto-answer calls"* (5b): persisted but **nothing reads it yet**. Auto-answering needs CallKit on
    iOS and a ConnectionService role on Android, neither of which exists here. *Alert override* is wired
    to the OS notification settings pane via `app_settings`, which is genuinely where "ignore silent"
    lives.

  **Cloud Functions.** `getPeopleIWatch` now also returns per-person `headsUpNote`/`headsUpAt`,
  `lastSeizureAt`/`daysSinceLastSeizure`, `lastAlertAt`, and a merged time-ordered `recentActivity` feed
  across everyone watched. The active-SOS query is kept *separate* from the recent-alerts query on
  purpose: deriving both from one "most recent 5" window would drop a live SOS for anyone with five newer
  alerts, and the watch list silently missing a live SOS is the one failure this screen must not have.
  `getAlertDetail` now returns `notifiedCount`, a `responders` roster, `medications`, and
  `daysSinceLastSeizure`. The roster has to come from the callable: `firestore.rules` scopes
  `/alert_responses` to the responder and the alert owner, and a caregiver is neither of those for
  *other* caregivers' rows, so a client listener is denied outright. Widening that rule would expose the
  roster to anyone who could guess an alert id. For the same reason `RespondingView` **polls** every 15s
  rather than streaming. New `nudgeResponder` callable pings a caregiver who has not committed yet; it
  authorizes both the caller and the target as non-pending contacts of the alert owner, so it cannot push
  to an arbitrary uid, and it returns `delivered: false` rather than throwing when the target has no FCM
  token — "phone them instead" is actionable, a red error is not. `daysSince` was extracted to
  `functions/time.js` (mirroring the `phone.js` split) so it is testable without booting firebase-admin;
  covered by `functions/test/time.test.js`.

  "Log what happened" writes a `note` onto the caregiver's own `alert_responses` document rather than the
  owner's `seizureLogs`, which is owner-only under the rules — and it is an observation *by* the
  responder, not the person's own record. No rules change was needed; the existing update rule already
  lets a responder write their own row.

  Not done: turns 2 and 3 of the design — the competing SOS cancel-window and idle-screen options — were
  explicitly scoped out of this pass.

  **Superseded by Feature 28:** the caregiver-mode paths described above originally authorized on the
  caller's phone number and wrote `alert_responses` directly from the client. Both were replaced. Two
  defects in this feature were mine: `nudgeResponder` shipped with no rate limit, and the "Log what
  happened" note field was unbounded.

  **Also fixed after this pass:** the shell crashed on every cold start with
  `"SosViewModel" not found`. Making the splash the initial route meant the shell is now always
  entered via `Get.offAllNamed`, and the `lazyPut` calls in `RootViewModel`'s constructor ran inside
  the page builder — under `SmartManagement.full`, GetX linked them to the *outgoing* route and
  disposed them with it. `RootViewModel` survived because the widget held a direct reference, so the
  shell rendered and only the first `Get.find<SosViewModel>()` threw. They now live in a `RootBinding`
  attached to the route, which GetX invokes at the right point in the lifecycle.

  A second instance of the same class of bug followed: `"CaregiverViewModel" not found` when switching
  modes. GetX links a controller to whatever route is current when it is first **resolved**, not when it
  is registered. Toggling caregiver mode happens on the pushed `/mode` route, which rebuilds the shell
  underneath — so `CaregiverViewModel` was resolved for the first time while `/mode` was on top and got
  linked to it. Popping back disposed the route and deleted the controller, and a plain `lazyPut` drops
  its factory on delete, so the shell's next `Get.find` threw.

  Every shell-lifetime registration in `RootBinding` is therefore `fenix: true`: the factory survives a
  delete and the controller is rebuilt on demand. This is safe because each of these reloads its own
  state in `onInit` — streams resubscribe and `SosViewModel` restores an in-flight SOS from persistence.

  Two duplicate registrations had to go with it, since a second `lazyPut` for the same type **replaces**
  the fenix one and reinstates the bug on the next pop:

  - `/caregiver-mode` and its `CaregiverBinding` were deleted outright. The route was dead — the watch
    list became a shell tab in Feature 27 and nothing navigated there any more.
  - `AlertHistoryBinding` now matches RootBinding's fenix. That route *is* live (patient shell app bar)
    and shares its type with the caregiver shell's Alerts tab, so visiting and popping it would have
    deleted the factory that tab depends on. `ProfileBinding` got the same treatment defensively; there
    is no `/profile` GetPage today, but adding one would otherwise resurrect the crash.

  **The rule for this codebase:** a controller the shell resolves must be registered in exactly one
  place — `RootBinding` — with `fenix: true`. Route bindings may only register controllers scoped to
  that route.

  Guarded by `test/features/root/root_binding_test.dart`, which checks the binding registers everything
  and pins the GetX fenix semantics the fix depends on. Note the mode-switch path itself is not covered
  end to end: resolving these controllers needs a live Firebase, so the tests assert the contract rather
  than replaying the route transition.

- Feature 26 (Material 3 redesign): replaces the bespoke monochrome system. **`CLAUDE.md`, `context/ui-rules.md`, `context/ui-tokens.md`, and `context/ui-registry.md` now describe a design the code no longer implements** — they need rewriting or deleting before anyone follows them again.

  Foundation is `lib/core/themes/app_theme.dart`: `ColorScheme.fromSeed` on a teal seed (`#006A6A`), the real M3 type scale (the old theme carried M2 values — a 96pt `displayLarge`, no letter tracking), the M3 shape scale, and component themes for navigation, buttons, cards, inputs, sheets, dialogs, and snackbars. Dynamic colour is deliberately not used: a wallpaper that tinted the app red would make the SOS state indistinguishable from the resting state.

  Emergency legibility was the core problem the old system had. Black meant primary button, hero card, pressed state, *and* live alert all at once, so the most urgent screen carried the same weight as a stats card. Now the M3 `error` role is reserved for exactly one meaning — live or imminent emergency — and appears on the SOS control, the countdown, and the SOS nav destination. `lib/core/themes/status_colors.dart` is a `ThemeExtension` adding the two roles M3 does not define but this app needs: `safe` (monitoring live) and `caution` (Heads Up counting down). Use `context.status`, `context.scheme`, `context.text`.

  New on Home: `ReadinessCard`. Everything else on that screen is retrospective, and none of it answered "if I seize right now, will anyone find out?" A circle whose invites were never accepted looked identical to a working one. It reads `ContactsViewModel` and counts only contacts that are both `active` and `notifyViaPush` — the same conditions `notifyContacts` applies server-side.

  The custom floating pill nav is gone, replaced by a real `NavigationBar`. SOS stays a destination rather than becoming a FAB: tapping it does not fire an alert, it opens a screen holding the SOS control, Heads Up options, and the roster. A centre-docked FAB also overlapped the destination labels. The SOS destination gets an error-toned pill icon so it reads as different without leaving the component, keeping NavigationBar's indicator animation, labels, ripple, and semantics.

  Accessibility fixes folded in: `Semantics` on the SOS control, the readiness card, and the monitoring badge; the 28-day grid is `ExcludeSemantics` with a summarised count exposed instead (28 unlabelled cells are noise to a screen reader); every hero number is wrapped in `FittedBox` so it no longer clips at large system text scales; muted text now comes from `onSurfaceVariant`, which clears WCAG AA, where the old `Colors.black45` was about 3.4:1 and failed.

  **Dark mode is built and correct but pinned off** (`themeMode: ThemeMode.light` in `main.dart`). About 60 files still hardcode `Colors.black`/`Colors.white` across ~430 occurrences; enabling `ThemeMode.system` today would render those screens black-on-black. Migrating them is the remaining work, and flipping that one line is the last step of it.

  Not yet migrated: seizure log, contacts, profile, onboarding, login, alert history, caregiver, and the shared widgets under `lib/core/widgets/`. They still render correctly in light mode — they just use literal colours rather than scheme roles.

- Feature 25 (Cost): removed `minInstances: 1` from `getPeopleIWatch` and `getAlertDetail`. A reserved Cloud Run instance bills for CPU and memory every second it is alive regardless of traffic, so the two of them cost roughly $5/month at **zero** usage — which was the project's entire monthly budget, hit 50% by the 15th with nobody using the app. Both now scale to zero and pay a 1-3s cold start on first call.

  The cost was known when it was added (Feature 22 required `firebase deploy --force` to acknowledge it); what wasn't obvious was its size relative to a $5 budget. If the budget ever allows re-adding it, `getAlertDetail` is the one to restore first — it is the only path where the cold start is felt by a user who is mid-emergency (a caregiver opening an incoming SOS notification). `getPeopleIWatch` is a browsing screen and already has a 30s client-side cache in `CaregiverService`.

  Worth knowing for future diagnosis: this presented as a *storage* problem, and it isn't one. Artifact Registry already has a 1-day cleanup policy on `projects/seizure-alert-app/locations/us-central1/repositories/gcf-artifacts`, so function container images are not accumulating. When a bill moves with nothing happening, look for reserved capacity before looking at storage.

  `expireHeadsUpWindows` (Feature 24) is not a meaningful cost: ~43k invocations/month against a 2M free tier, ~2,160 GB-s against 400,000 GB-s, and Cloud Scheduler's first 3 jobs are free.

- Feature 24 (Reliability pass): four defects that each caused a **silent** failure of a core safety path.

  **Phone matching.** Every cross-user link — `notifyContacts`, `getPeopleIWatch`, `getAlertDetail`, `sendCircleInvite` — was an exact string query on a raw, as-typed `phone`. A contact saved "082 123 4567" against an account registered "+27 82 123 4567" simply never matched, so that person received no alerts and nothing in either UI said so. Fixed by `PhoneNumber` (`lib/core/helpers/phone_number.dart`) and its JS mirror `functions/phone.js` — the two must stay in sync. `UserDto`/`ContactDto` now derive a `phoneNormalized` E.164 field in `toMap()` (a getter, not a stored field, so no write path can forget it); `phone` is left untouched for display. The functions match on `phoneNormalized` via new `findUserByPhone`/`findContactsByPhone` helpers, which fall back to the raw `phone` query so a partially-migrated database keeps working — **delete that fallback once `functions/scripts/backfill-phone-normalized.js --apply` has run**, it currently doubles the query count on every lookup. `PhoneNumber.defaultDialCode` is hardcoded to `27`; a locally-written number is genuinely ambiguous without it, so this becomes a per-user setting the moment the app ships outside one region. `InviteService` also used its own weaker normaliser for wa.me links, which produced links to nonexistent subscribers for locally-written numbers.

  **Heads Up expiry.** Escalation ran entirely on a client `Timer` in `HeadsUpViewModel`, so it fired only while the app was alive — the exact opposite of the scenario the feature exists for. New `expireHeadsUpWindows` scheduled function (every 1 min) sweeps `status == active && expiresAtMs <= now` and escalates transactionally. Note `expiresAtMs`: `expiresAt` is serialised with `toIso8601String()` on a *local* `DateTime`, so it carries no timezone and the server cannot compare it to its own clock — the new epoch-millis field is what the sweep queries (composite index added). The client no longer writes the expiry at all: if it flipped the status to `expired` first, the document would drop out of the sweep's `status == active` query and could be stranded with no alert ever sent. Cost is up to ~60s latency on a 30–120 min window, in exchange for the escalation being guaranteed. The sweep also copies coordinates from the original `_alert` document, which the old client path never did — the most urgent alert type in the app was reaching contacts with no location. **Heads Up windows already active at deploy time have no `expiresAtMs` and so will not be swept**; range queries skip documents missing the field. They are ≤120 min old, so this self-resolves.

  **Platform config.** `POST_NOTIFICATIONS` was missing, which blocks *all* notifications on Android 13+. `tel` was absent from `<queries>` and `LSApplicationQueriesSchemes`, so `canLaunchUrl` returned false and every "Call" button — the single most important action a caregiver takes — did nothing, silently, on Android 11+ and iOS. All three call sites now go through `CallService` (`lib/core/services/call_service.dart`), which falls back to copying the number to the clipboard and saying so rather than failing mute. Also added: FCM `default_notification_channel_id` meta-data (without it, backgrounded pushes bypass the `Importance.max` channel), `whatsapp`/`https` query entries, iOS `remote-notification` background mode. The channel was named `channel_id` / "Channel name" — user-visible in Android settings — now `seizure_alerts` / "Emergency alerts", and the id is duplicated in the manifest so **keep `LocalNotificationsService.alertChannelId` and the manifest meta-data in sync**.

  **Security rules.** `alert_responses` allowed `read` and `create` to *any* signed-in user — the whole collection was enumerable, and responses could be forged onto strangers' alerts. Scoping needs both parties (responder and patient), so `AlertResponseDto` gained a denormalised `alertOwnerId` and the rules are now plain field comparisons on `responderId`/`alertOwnerId`; a `get()` into `/alerts` would have spent a document read per rule evaluation. This forced a client change too: Firestore evaluates rules against the *query* on a list operation, so `watchAlertResponses` filtering on `alertId` alone gets denied outright — it now also filters `alertOwnerId == uid`. That filter is load-bearing, not redundant. Responses written before this have no `alertOwnerId` and are covered by the same backfill script.

  Not verified locally: `firestore.rules` could not be exercised against the emulator (this environment blocks loopback sockets, so the Firestore emulator cannot start). The rules compile server-side on `firebase deploy --only firestore:rules`, which rejects syntax errors before applying — but the *behaviour* above is reasoned, not tested. Worth an emulator test run before trusting it.

  Deploy order matters: **rules and functions before the client**, so a client still on the old build isn't writing responses that the new rules reject. Then run the backfill.

- Feature 15 follow-up (phone/email editing): `EditProfileBottomSheet` gained a Phone Number field, wired through `ProfileViewModel.updateProfile`. This also fixed a latent bug — `updateProfile` was rebuilding the `UserDto` without `phone`/`fcmToken`, so every profile save silently wiped both fields in Firestore (since `upsertUser` writes a full `toMap()` with `merge: true`, which doesn't help when the map itself contains explicit `null`s). Email is *not* editable in that sheet — Firebase requires re-authentication to change the auth email, so it's a separate flow: `ChangeEmailSheet` (password + new email) → `FirebaseAuthController.changeEmail` reauthenticates then calls `verifyBeforeUpdateEmail`, which only takes effect once the user clicks the confirmation link sent to the new address. Since that means the Firestore `users.email` copy can lag behind `FirebaseAuth.currentUser.email`, `ProfileViewModel.fetchProfile` now reconciles the two on every profile load. Avatar/photo upload was scoped out of this pass — it needs `firebase_storage` + `image_picker` and a configured Storage bucket (Blaze plan), neither of which exist in this project yet (`firebase.json` has no storage config).

- Feature 15 follow-up (UX polish): `EditProfileBottomSheet` now has an explicit "Cancel" button and can be dismissed by pulling down on the handle — see `ui-registry.md`'s Add/Edit Bottom Sheet pattern notes for why the handle had to move outside the scrollable content for drag-to-dismiss to work at all. Sign-out (`root_view.dart`) now shows a confirm dialog ("Sign out?" / Cancel / Sign out) before calling `FirebaseAuthController.signOut()`, matching the existing Remove-contact confirm dialog shape (`showDialog` + `AlertDialog`, `Get.defaultDialog` was never actually used anywhere despite being documented in `ui-registry.md`'s Dismissible List Tile entry — that entry is aspirational/stale on that specific point).

- Feature 15 follow-up (password change): `ChangePasswordSheet` (current password, new password, confirm) reuses the same re-auth-then-mutate shape as email change — `FirebaseAuthController.changePassword` reauthenticates with the current password via `EmailAuthProvider.credential`, then calls `updatePassword`. Unlike email change this takes effect immediately (no confirmation link), so the sheet's success state is just a static "Password updated" confirmation. Reached via a new "Password" row in the Profile Settings section (`Icons.key_outlined`, next to the still-unimplemented "Privacy" stub).

- Feature 23: Adding a contact now checks (via `sendCircleInvite` callable) whether the phone belongs to a registered user. If so, the `ContactDto` is created with `status: pending` — `notifyContacts`/`getPeopleIWatch`/`getAlertDetail` in `functions/index.js` all skip `pending` contacts, so they receive no alerts and don't show up as "people I watch" until they accept. Accept/decline happens on a new `/circle-invite` route (`CircleInviteView`), reachable either by tapping the push notification (`FirebaseMessagingService` routes `data.type == 'circle_invite'` before the existing SOS branch) or from a banner on Home (`HomeViewModel.pendingInvites`, a live `watchPendingInvites` stream). Declining **deletes** the contact on the sender's side (both invite status mutation and the cross-user contact write happen inside `respondToInvite`, which runs under the Cloud Functions Admin SDK — no new Firestore rule was needed for that cross-user write, only a read rule on the new `invites` collection). If the phone doesn't match a registered user, behavior is unchanged from Feature 18 (falls back to `InvitePickerSheet`).

- Feature 17: `AlertResponsesWidget` (`lib/core/widgets/`) is a `StatefulWidget` that subscribes to `watchAlertResponses(alertId)`. Placed in two locations: (1) active SOS screen — below the map, using `sosVm.activeSos.value?.id`; (2) `_AlertDetailSheet` in alert history — using `alert.id`. Empty state shows "Waiting for your circle to respond..."; populated state shows avatar initials + name + "Responding" (black filled) or "Seen" (subtle) badge. Active SOS view was refactored from `Expanded` map to `SingleChildScrollView` + fixed 150px map + responses section, keeping the cancel button pinned at the bottom.

- Feature 16: `AlertHistoryViewModel` streams `watchRecentAlerts` (last 20 alerts, descending). Route `/alert-history` uses `AlertHistoryBinding` for lazy VM registration. Entry point is a history icon button in the root AppBar. Tapping an alert card opens `_AlertDetailSheet` (modal bottom sheet) showing timestamps, optional message/location label, and `AlertMapWidget` / `AlertMapPlaceholder` depending on whether coordinates exist.

- Feature 18: `InviteService` (`lib/core/services/`) is a stateless helper — `sendSmsInvite`/`sendWhatsAppInvite` via `url_launcher`, falling back to a clipboard copy + snackbar if the app isn't installed. The picker UI (`InvitePickerSheet`, `_ChannelRow`) lives in `lib/features/contacts/widgets/invite_picker_sheet.dart` since it's only used by the contacts feature — `InviteService` itself has no UI-showing responsibility. Triggered from `AddContactBottomSheet` (post-save, if the "Send invite" toggle is on) and from a send-invite icon on each `ContactCard`.



- FCM token is fetched and saved to Firestore on every app launch via `FirebaseMessagingService.init()` — this keeps tokens fresh without a manual refresh flow.
- `HeadsUpViewModel` auto-escalates to `headsUpExpired` alert type when the countdown reaches zero — the Cloud Function picks this up and notifies contacts.
- The 28-day activity grid in `HomeViewModel.gridData` returns a 28-element list of booleans; `true` means at least one seizure occurred on that day. The grid renders 4 rows × 7 columns (oldest → newest, left to right, top to bottom).
- `AlertDto.type` drives the Cloud Function notification copy — keep the three string values (`sos`, `headsUp`, `headsUpExpired`) in sync between the Flutter app and `functions/index.js`.
- `firestore.rules` uses `request.auth.uid == resource.data.userId` for ownership checks on contacts, seizureLogs, alerts, and headsUp. The `alert_responses` collection path was fixed to match `FirebaseCollectionKeys.responses` ('alert_responses') — it previously read `/responses/{responseId}`, which never matched the collection the app actually writes to, so every read/write was denied by Firestore's default-deny. The update/delete rule checks a `responderId` field — as of Feature 22, `AlertResponseDto.responderId` exists and is populated by `IncomingAlertViewModel` (the first real caller of `upsertAlertResponse`), so the rule and the write path now agree.
- `lib/core/widgets/alert_map_widget.dart` displays a `flutter_map` centred on alert coordinates. It is wired into `_AlertDetailSheet` (Feature 16, alert history), the redesigned active-SOS status board (Feature 22), and `IncomingAlertView` (Feature 22).

- Feature 22 follow-up (Caregiver mode perf): `getPeopleIWatch` was doing 3 sequential Firestore reads per watched person (owner doc → SOS query → conditional Heads Up query) inside its per-contact `Promise.all` fan-out; `getAlertDetail` was 4 fully sequential reads. Both now parallelize the reads that don't depend on each other's results (`functions/index.js`) — `getPeopleIWatch` always fetches the Heads Up query alongside SOS now (previously conditional on SOS being empty), trading one occasionally-unnecessary read for removing a full round-trip wait. Both callables also got `{ minInstances: 1 }` to eliminate cold starts — **this was reverted in Feature 25, do not re-add it without checking the budget first.** On the Flutter side, `CaregiverService.getPeopleIWatch` now caches its last successful result for 30s (`_cacheTtl`) so navigating away and back to Caregiver mode within that window is instant instead of re-invoking the callable; pull-to-refresh passes `forceRefresh: true` to bypass the cache. `getAlertDetail` is intentionally not cached — it's emergency-detail data that must stay live.

- Feature 22 (Caregiver mode): SOS send-countdown (`CountdownAlertDialog` in `sos_button_widget.dart`) and the active-alert screen (`SosView._buildActiveState`) were redesigned into a full-bleed black "status board" — `SosStatusBoardHeader` (elapsed timer, segmented seen-indicator, "Cancel" text action) + `ContactStatusRow` per contact (initials avatar, Responding/Seen/Not seen yet, tel: call button), backed by a new `SosViewModel.alertResponses` stream (subscribed alongside `activeSos`, cancelled on `cancelSos`/`onClose`). Caregiver mode itself is a new feature folder (`lib/features/caregiver/`): `CaregiverView` ("People I watch", black emphasized cards for SOS/Heads Up with a "View details"/"Check on them" action, plain rows for monitoring) and `IncomingAlertView` (dark alert-detail screen — medical ID, emergency note, distance via `Geolocator.distanceBetween`, "I'm responding" + "Call {name}"). Since `firestore.rules` is strictly owner-only, cross-user reads go through two new admin-privileged Cloud Functions — `getPeopleIWatch` and `getAlertDetail` (`functions/index.js`, both `onCall`, deployed to `us-central1`) — reached via the new `cloud_functions` dependency and `lib/core/services/caregiver_service.dart`. `getAlertDetail` authorizes the caller by matching their phone against the alert owner's `contacts`, and also returns `callerContactId`/`callerContactName` so the client can write a correctly-keyed `AlertResponseDto` without its own risky lookup. Opening `IncomingAlertView` auto-marks the response `seen: true`; tapping "I'm responding" additionally sets `responding: true` — this is the first code path that ever writes to `alert_responses`, so the sender's status board now reflects real data instead of always showing "Not seen yet". `_handleNotificationNavigation` (`firebase_messaging_service.dart`) deep-links a tapped SOS push into `IncomingAlertView`; it checks the new `alertStatus` FCM data field to skip cancelled-alert notifications (which share the same `alertType`).
