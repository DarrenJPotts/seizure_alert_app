# Progress Tracker

Update this file after every completed feature. Any AI agent reading this should immediately know what is done, what is in progress, and what is next.

---

## Current Status

**Phase:** Phase 5 — Polish & Reliability
**Last completed:** 34 Security and development-cost hardening
**Next:** 21 Offline resilience, then stale-FCM-token cleanup and critical-alert delivery (see Known Gaps)

> ## ⚠ Deploy order for Features 27 + 28 — read before shipping
>
> Feature 28 changes how *every* cross-user read is authorized. Getting the order wrong locks
> existing caregivers out of the watch list and the incoming-alert screen.
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
- [ ] 21 Offline resilience — in progress: connection banner, SOS queue feedback, and Heads Up queueing implemented; device verification remains
- [x] 22 Caregiver mode (SOS send-countdown + active-alert screen redesign, "People I watch" list, Incoming Alert detail screen)
- [x] 32 UX pass — emergency-path honesty, haptics, permission recovery, log deletion
- [ ] 31 POPIA groundwork — code side done; notice text, data residency and Information Officer registration outstanding
- [x] 30 Onboarding before sign-up (draft held in the view model, five-step progress bar)
- [x] 29 Grouped-card settings language (shared `core/widgets/settings/`, Profile + Seizure Log restyled)
- [x] 28 Security hardening (linkedUid authorization, invite enumeration, alert-response forgery, rate limiting)
- [x] 27 Splash screen + full caregiver mode (per-device role switch, watch list, incoming SOS, respond/shared view) + monochrome live indicator
- [x] 23 Circle invites (one-time code shared by SMS/WhatsApp; signed-in recipient previews and accepts/declines it; no profile-phone account lookup or automatic in-app invite inbox)
- [x] 33 Home setup check — live count of contacts linked to the app, active, and enabled for push alerts; opens Contacts to fix setup

---

## Notes

- minimalist-ui protocol pass (small): the `/minimalist-ui` skill is a **web** protocol (Tailwind/React,
  editorial serif headings, warm bone canvas, muted pastel accents) and its own execution rules trigger
  on "HTML, React, Tailwind, Vue". This is Flutter, and most of it conflicts head-on with `CLAUDE.md`:
  pastel accents against a palette that is deliberately colourless, a serif display face against a
  single-family Red Hat Display system, `#EAEAEA` against `Colors.black12`, and a ban on pill shapes
  against `Dimensions.circular`. Adopting the pastels would also have reversed the contrast decision
  behind `LiveIndicator` — the whole reason the monitoring green was removed. **Decision: keep the
  monochrome system; apply only the parts both authorities agree on.**

  Applied:
  - **Emoji out of push notification copy** (`functions/index.js`). Four titles carried them —
    `SOS Alert`, `Heads Up`, `Check-in Missed`, and the `nudgeResponder` title. Both the protocol and
    `CLAUDE.md`'s "minimal, clinical, serious / no gamified language" point the same way, and on a lock
    screen mid-emergency a plain title reads more credibly than a siren glyph. Titles also normalised to
    sentence case to match the rest of the app, and the nudge title changed from "Still waiting on you"
    to "Response needed" — the original nagged rather than informed.
  - **Shadows softened below 5%.** Nav bar and SOS drawer went from 10%/8% at blur 20 down to 4% at
    blur 16. Two deliberate exceptions, now documented in `ui-registry.md` under a new **Elevation**
    entry so they do not read as oversights: the elevated SOS control (12%, the one place elevation
    carries meaning, and now matching the value the registry already documented for that control) and
    the map marker pin (35% — a pin must separate from arbitrary map imagery, the one surface whose
    colour this app does not control).

  Audited and already clean: no gradients anywhere in `lib/`; no AI clichés or gamified language (every
  "Elevate" hit was Flutter's `ElevatedButton`); no placeholder names or Lorem; motion already runs on
  transform/opacity only.

  Not applied, and why: pastel accents, editorial serif, warm bone canvas, `#EAEAEA` borders, and the
  ban on pill shapes — all contradict `CLAUDE.md`. Web-only mechanics (`<kbd>` keys, faux macOS window
  chrome, accordions, `IntersectionObserver`, `picsum.photos` imagery) do not apply to a Flutter mobile
  app with no imagery.

- Feature 32 (UX pass): from an interaction review. The theme of the important half is that **the
  emergency path did not tell the truth about its own state**.

  **The alert now says whether it was actually sent.** `createAlert` does `await set(...)`, and
  Firestore only completes that future once the *server* has the write — so offline it never completed.
  The code sat on an unresolved await while the screen showed a live alert: the user believed their
  circle had been told when nothing had left the phone, and neither the success nor the error branch
  ever ran. New `SosDelivery` enum (`sending` / `delivered` / `queued` / `failed`) driven by racing the
  write against an 8s grace; the write is no longer awaited on the SOS path. Only `delivered` gets the
  pulsing live indicator. `queued`/`failed` replace the seen-indicator — which is meaningless when
  nothing was sent — with "nobody has been notified yet" and a **Call a contact instead** button, the
  one action that still works with no data connection. A queued write completing on reconnect clears it
  by itself. Restoring an alert from disk re-issues the write (same deterministic id, idempotent) since
  that is the only way to learn whether the original ever landed.

  **Cancelling a live alert was a bare `Text` in a `GestureDetector`** — roughly 50x20, no confirmation,
  no haptic. One mis-tap stood the whole circle down silently, while removing a *contact* asked for
  confirmation. Now a 48px bordered button, `heavyImpact`, and a confirm dialog. The cancel write gets a
  timeout too, and a failure now says "your circle may still think this alert is active — call them"
  rather than the old, unconditional "your circle has been notified".

  **The countdown was 5s and the back gesture was unguarded.** There was no `PopScope` anywhere in
  `lib/`, and `barrierDismissible: false` does not cover Android back — so back dismissed the dialog
  with the SOS neither sent nor cancelled, a silent no-op on the emergency path. Now 10s (as the design
  specified), `PopScope` mapping back to an explicit cancel, and a haptic tick per second — the cue that
  works when you cannot focus on the screen.

  Smaller items from the same review: haptics on the shared settings rows and nav bar (there were five
  call sites in the whole app against a `CLAUDE.md` rule requiring them); permission rows that became
  dead buttons after a permanent OS denial now switch to "Open settings"; the emergency-contact step is
  skippable, since requiring it blocked account creation outright now that onboarding precedes sign-up;
  seizure log entries can finally be deleted (swipe + confirm — they never could be, despite
  `ui-registry.md` documenting it); bottom snackbars lifted clear of the floating nav and SOS button;
  the SOS drawer handle labelled "Heads Up & your circle", since Heads Up was a primary feature hidden
  behind an unlabelled 36x4 handle; and the caregiver watch list shows how stale it is.

  Also removed `_compactHeightBreakpoint`, dead since the responsive branch was abandoned — the
  analyzer warning that had been standing all session. The tree is now warning-free.

  Not addressed: accessibility is still patchy (the SOS button, activity grid, contact cards and
  alert-history cards have no `Semantics`), hero numerals will still clip at large text scales, and
  `RespondingView` has no freshness indicator. Listed for a follow-up.

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

  Heads Up expiry is now event-driven: one Firestore trigger schedules one delayed Cloud Task per window. There is no idle scheduler invocation while nobody is using the app.

- Feature 24 (Reliability pass): four defects that each caused a **silent** failure of a core safety path.

  **Phone matching.** `PhoneNumber` (`lib/core/helpers/phone_number.dart`) and its JS mirror `functions/phone.js` normalize emergency contact lookups used for alert and caregiver functions. `UserDto`/`ContactDto` derive a `phoneNormalized` E.164 field; `phone` remains for display and external calling. Circle invites use hashed one-time codes and never query user profiles by phone. `PhoneNumber.defaultDialCode` is `27`, so supporting users outside South Africa still needs a per-user region setting. The same helper normalizes numbers for WhatsApp links.

  **Heads Up expiry.** Escalation originally depended on a client timer, then on a minute scheduler. It now uses one delayed Cloud Task per window, created by `onHeadsUpCreated`, so escalation remains server-owned without continuous polling. The task reads the window at expiry, exits if the user already checked in or cancelled, and transactionally creates the deterministic expiry alert. `expiresAtMs` remains the unambiguous UTC scheduling value. The expiry task copies coordinates from the original `_alert` document before creating the notification-triggering alert.

  **Platform config.** `POST_NOTIFICATIONS` was missing, which blocks *all* notifications on Android 13+. `tel` was absent from `<queries>` and `LSApplicationQueriesSchemes`, so `canLaunchUrl` returned false and every "Call" button — the single most important action a caregiver takes — did nothing, silently, on Android 11+ and iOS. All three call sites now go through `CallService` (`lib/core/services/call_service.dart`), which falls back to copying the number to the clipboard and saying so rather than failing mute. Also added: FCM `default_notification_channel_id` meta-data (without it, backgrounded pushes bypass the `Importance.max` channel), `whatsapp`/`https` query entries, iOS `remote-notification` background mode. The channel was named `channel_id` / "Channel name" — user-visible in Android settings — now `seizure_alerts` / "Emergency alerts", and the id is duplicated in the manifest so **keep `LocalNotificationsService.alertChannelId` and the manifest meta-data in sync**.

  **Security rules.** `alert_responses` allowed `read` and `create` to *any* signed-in user — the whole collection was enumerable, and responses could be forged onto strangers' alerts. Scoping needs both parties (responder and patient), so `AlertResponseDto` gained a denormalised `alertOwnerId` and the rules are now plain field comparisons on `responderId`/`alertOwnerId`; a `get()` into `/alerts` would have spent a document read per rule evaluation. This forced a client change too: Firestore evaluates rules against the *query* on a list operation, so `watchAlertResponses` filtering on `alertId` alone gets denied outright — it now also filters `alertOwnerId == uid`. That filter is load-bearing, not redundant. Responses written before this have no `alertOwnerId` and are covered by the same backfill script.

  Not verified locally: `firestore.rules` could not be exercised against the emulator (this environment blocks loopback sockets, so the Firestore emulator cannot start). The rules compile server-side on `firebase deploy --only firestore:rules`, which rejects syntax errors before applying — but the *behaviour* above is reasoned, not tested. Worth an emulator test run before trusting it.

  Deploy order matters: **rules and functions before the client**, so a client still on the old build isn't writing responses that the new rules reject. Then run the backfill.

- Feature 15 follow-up (phone/email editing): `EditProfileBottomSheet` gained a Phone Number field, wired through `ProfileViewModel.updateProfile`. This also fixed a latent bug — `updateProfile` was rebuilding the `UserDto` without `phone`/`fcmToken`, so every profile save silently wiped both fields in Firestore (since `upsertUser` writes a full `toMap()` with `merge: true`, which doesn't help when the map itself contains explicit `null`s). Email is *not* editable in that sheet — Firebase requires re-authentication to change the auth email, so it's a separate flow: `ChangeEmailSheet` (password + new email) → `FirebaseAuthController.changeEmail` reauthenticates then calls `verifyBeforeUpdateEmail`, which only takes effect once the user clicks the confirmation link sent to the new address. Since that means the Firestore `users.email` copy can lag behind `FirebaseAuth.currentUser.email`, `ProfileViewModel.fetchProfile` now reconciles the two on every profile load. Avatar/photo upload was scoped out of this pass — it needs `firebase_storage` + `image_picker` and a configured Storage bucket (Blaze plan), neither of which exist in this project yet (`firebase.json` has no storage config).

- Feature 15 follow-up (UX polish): `EditProfileBottomSheet` now has an explicit "Cancel" button and can be dismissed by pulling down on the handle — see `ui-registry.md`'s Add/Edit Bottom Sheet pattern notes for why the handle had to move outside the scrollable content for drag-to-dismiss to work at all. Sign-out (`root_view.dart`) now shows a confirm dialog ("Sign out?" / Cancel / Sign out) before calling `FirebaseAuthController.signOut()`, matching the existing Remove-contact confirm dialog shape (`showDialog` + `AlertDialog`, `Get.defaultDialog` was never actually used anywhere despite being documented in `ui-registry.md`'s Dismissible List Tile entry — that entry is aspirational/stale on that specific point).

- Feature 15 follow-up (password change): `ChangePasswordSheet` (current password, new password, confirm) reuses the same re-auth-then-mutate shape as email change — `FirebaseAuthController.changePassword` reauthenticates with the current password via `EmailAuthProvider.credential`, then calls `updatePassword`. Unlike email change this takes effect immediately (no confirmation link), so the sheet's success state is just a static "Password updated" confirmation. Reached via a new "Password" row in the Profile Settings section (`Icons.key_outlined`, next to the still-unimplemented "Privacy" stub).

- Feature 23: `createCircleInvite` generates a 128-bit one-time code, stores only its SHA-256 hash, and expires it after 24 hours. The sender shares it through SMS/WhatsApp. A signed-in recipient opens My Circle or Mode → Enter invite code, previews the sender, and explicitly accepts or declines. Preview and redemption are App Check protected, authenticated, and rate-limited; redemption and contact linking happen in one transaction. There is no phone-profile lookup or automatic in-app invite notification. Existing legacy pending invites must be reissued.

  Updated invite design: `createCircleInvite` generates a 128-bit one-time code, stores only its SHA-256 hash, and expires it after 24 hours. The sender shares it through SMS/WhatsApp. A signed-in recipient opens My Circle or Mode → Enter invite code, previews the sender, and explicitly accepts or declines. Preview and redemption are App Check protected, authenticated, and rate-limited; redemption and contact linking happen in one transaction. There is no phone-profile lookup or automatic in-app invite notification. Existing legacy pending invites must be reissued.

- Feature 17: `AlertResponsesWidget` (`lib/core/widgets/`) is a `StatefulWidget` that subscribes to `watchAlertResponses(alertId)`. Placed in two locations: (1) active SOS screen — below the map, using `sosVm.activeSos.value?.id`; (2) `_AlertDetailSheet` in alert history — using `alert.id`. Empty state shows "Waiting for your circle to respond..."; populated state shows avatar initials + name + "Responding" (black filled) or "Seen" (subtle) badge. Active SOS view was refactored from `Expanded` map to `SingleChildScrollView` + fixed 150px map + responses section, keeping the cancel button pinned at the bottom.

- Feature 16: `AlertHistoryViewModel` streams `watchRecentAlerts` (last 20 alerts, descending). Route `/alert-history` uses `AlertHistoryBinding` for lazy VM registration. Entry point is a history icon button in the root AppBar. Tapping an alert card opens `_AlertDetailSheet` (modal bottom sheet) showing timestamps, optional message/location label, and `AlertMapWidget` / `AlertMapPlaceholder` depending on whether coordinates exist.

- Feature 18: `InviteService` (`lib/core/services/`) is a stateless helper — `sendSmsInvite`/`sendWhatsAppInvite` via `url_launcher`, falling back to a clipboard copy + snackbar if the app isn't installed. The picker UI (`InvitePickerSheet`, `_ChannelRow`) lives in `lib/features/contacts/widgets/invite_picker_sheet.dart` since it's only used by the contacts feature — `InviteService` itself has no UI-showing responsibility. Triggered from `AddContactBottomSheet` (post-save, if the "Send invite" toggle is on) and from a send-invite icon on each `ContactCard`.

- FCM token is fetched and saved to Firestore on every app launch via `FirebaseMessagingService.init()` — this keeps tokens fresh without a manual refresh flow.
- `HeadsUpViewModel` clears local state when the countdown reaches zero; the delayed `expireHeadsUpWindow` task owns escalation and contact notification.
- The 28-day activity grid in `HomeViewModel.gridData` returns a 28-element list of booleans; `true` means at least one seizure occurred on that day. The grid renders 4 rows × 7 columns (oldest → newest, left to right, top to bottom).
- `AlertDto.type` drives the Cloud Function notification copy — keep the three string values (`sos`, `headsUp`, `headsUpExpired`) in sync between the Flutter app and `functions/index.js`.
- `firestore.rules` uses `request.auth.uid == resource.data.userId` for ownership checks on contacts, seizureLogs, alerts, and headsUp. The `alert_responses` collection path was fixed to match `FirebaseCollectionKeys.responses` ('alert_responses') — it previously read `/responses/{responseId}`, which never matched the collection the app actually writes to, so every read/write was denied by Firestore's default-deny. The update/delete rule checks a `responderId` field — as of Feature 22, `AlertResponseDto.responderId` exists and is populated by `IncomingAlertViewModel` (the first real caller of `upsertAlertResponse`), so the rule and the write path now agree.
- `lib/core/widgets/alert_map_widget.dart` displays a `flutter_map` centred on alert coordinates. It is wired into `_AlertDetailSheet` (Feature 16, alert history), the redesigned active-SOS status board (Feature 22), and `IncomingAlertView` (Feature 22).

- Feature 33 (Safety expansion, 2026-10-11): added the Safety Readiness screen,
  richer seizure records, monthly calendar and 90-day summary, PDF/CSV sharing,
  caregiver action plans, local medication reminders, a nearby audible alert,
  delivery-state tracking, and bounded priority escalation for unanswered alerts.
  Escalation creates at most three delayed tasks per alert and exits when the
  alert is resolved, cancelled, or acknowledged. All functions retain
  `minInstances: 0` and there is no polling scheduler.

- Feature 34 (Garmin manual companion, 2026-10-11): added a Connect IQ project
  under `garmin/` with six-digit pairing, revocable hashed credentials, current
  safety status, a ten-second manual SOS countdown, Heads Up, check-in, and
  battery heartbeat. Firebase exposes three scale-to-zero HTTPS endpoints and
  owner-only wearable management callables. Automatic seizure detection remains
  outside the implementation scope. Connect IQ compilation and physical-watch
  validation remain release requirements because the SDK is not installed in
  the development environment.

- Feature 22 follow-up (Caregiver mode perf): `getPeopleIWatch` was doing 3 sequential Firestore reads per watched person (owner doc → SOS query → conditional Heads Up query) inside its per-contact `Promise.all` fan-out; `getAlertDetail` was 4 fully sequential reads. Both now parallelize the reads that don't depend on each other's results (`functions/index.js`) — `getPeopleIWatch` always fetches the Heads Up query alongside SOS now (previously conditional on SOS being empty), trading one occasionally-unnecessary read for removing a full round-trip wait. Both callables also got `{ minInstances: 1 }` to eliminate cold starts — **this was reverted in Feature 25, do not re-add it without checking the budget first.** On the Flutter side, `CaregiverService.getPeopleIWatch` now caches its last successful result for 30s (`_cacheTtl`) so navigating away and back to Caregiver mode within that window is instant instead of re-invoking the callable; pull-to-refresh passes `forceRefresh: true` to bypass the cache. `getAlertDetail` is intentionally not cached — it's emergency-detail data that must stay live.

- Feature 22 (Caregiver mode): SOS send-countdown (`CountdownAlertDialog` in `sos_button_widget.dart`) and the active-alert screen (`SosView._buildActiveState`) were redesigned into a full-bleed black "status board" — `SosStatusBoardHeader` (elapsed timer, segmented seen-indicator, "Cancel" text action) + `ContactStatusRow` per contact (initials avatar, Responding/Seen/Not seen yet, tel: call button), backed by a new `SosViewModel.alertResponses` stream (subscribed alongside `activeSos`, cancelled on `cancelSos`/`onClose`). Caregiver mode itself is a new feature folder (`lib/features/caregiver/`): `CaregiverView` ("People I watch", black emphasized cards for SOS/Heads Up with a "View details"/"Check on them" action, plain rows for monitoring) and `IncomingAlertView` (dark alert-detail screen — medical ID, emergency note, distance via `Geolocator.distanceBetween`, "I'm responding" + "Call {name}"). Since `firestore.rules` is strictly owner-only, cross-user reads go through two new admin-privileged Cloud Functions — `getPeopleIWatch` and `getAlertDetail` (`functions/index.js`, both `onCall`, deployed to `us-central1`) — reached via the new `cloud_functions` dependency and `lib/core/services/caregiver_service.dart`. `getAlertDetail` authorizes the caller by matching their phone against the alert owner's `contacts`, and also returns `callerContactId`/`callerContactName` so the client can write a correctly-keyed `AlertResponseDto` without its own risky lookup. Opening `IncomingAlertView` auto-marks the response `seen: true`; tapping "I'm responding" additionally sets `responding: true` — this is the first code path that ever writes to `alert_responses`, so the sender's status board now reflects real data instead of always showing "Not seen yet". `_handleNotificationNavigation` (`firebase_messaging_service.dart`) deep-links a tapped SOS push into `IncomingAlertView`; it checks the new `alertStatus` FCM data field to skip cancelled-alert notifications (which share the same `alertType`).

### 13 October 2026 hardening pass
Profile and email writes now update only edited fields, preserving safety plans/reminders/consent/tokens. Caregiver cache is user scoped and rejects late requests after invalidation. Removed inert auto-answer UI/state, duplicate Mode watch list and misleading alert-override shortcut. Settings navigation uses the tested wrapping value-row layout. Added honest dashboard failure states and safe profile-editor disposal/failure handling. Full details: docs/production/hardening-2026-10-13.md. No feature development or deployment performed.

### Heads Up and Android notification sound � 13 October 2026
Fixed short-screen Heads Up overlap and added custom check-in minutes (1�1,440). Bundled an original 3.9-second ascending paired-tone alert for Android, using a new seizure_alerts_v2 channel because Android channel sounds are immutable. Manifest fallback and foreground notifications use the same channel. Updated FCM Android sound payload; backend deployment remains pending. iOS keeps its existing default sound. Actual volume and DND remain controlled by system settings. Flutter regression suite: 269 passed; Node suite: 26 passed.

### GetX lifecycle hardening � 13 October 2026
Retained/cancelled messaging streams, made messaging/home-widget startup idempotent, moved Heads Up ownership to RootBinding, guarded cached alert restore by active account and disposal, blocked timer resurrection in caregiver screens and disposed safety-plan text controller access, and prevented duplicate home retry subscriptions. Added five async/disposal regression cases; all 274 tests pass with clean analysis. Details: docs/production/getx-lifecycle-2026-10-13.md. Device heap profiling remains unperformed.

### UI overhaul trial — 13 October 2026
Replaced raised navigation with adaptive labelled bars; patient opens Home. SOS/Heads Up share a scrollable page with inline duration/custom minutes and a visible active check-in action. Home prioritises active alerts and recent entries before statistics; completed setup is compact. Caregiver readiness moves below active watch-list cards. Shared entry rows and activity legends wrap at larger text sizes. Removed the obsolete draggable idle sheet. 280 Flutter tests passed; preview captured under .buildlog/ui-overhaul-sos.png. No real alerts sent.


### Current UI direction — 13 October 2026
The owner reverted the UI overhaul trial. Its labelled navigation, inline Heads Up and reordered Home layout are historical proposals, not the current baseline. Preserve the Apple-style floating pill navigation, raised SOS and existing hierarchy. The subsequent focused pass reduces navigation item padding on narrow screens, fits the SOS circle/label to available width, and measures the Heads Up heading for large-text clearance. Validation: clean Flutter analysis and 276 passing tests.


### Dark-mode implementation — 13 October 2026
Enabled the existing persisted ThemeController preference and added Profile > Appearance (System/Light/Dark). Custom UI now resolves monochrome roles from its inherited theme via AppPalette; dark background #181818 and cards #2D2D2D. Navigation and screen hierarchy preserved. Heads Up restored to the earlier 10% collapsed extent per owner request. Theme-aware system bars and scrollable appearance controls included. Clean analysis and 285 passing tests, including preference restoration, live theme switching without losing the open sheet, system brightness, patient/caregiver navigation at 280/390dp, short-screen large text, contrast and compact sheet extent. Rendered Home/SOS/Settings component previews reviewed; physical device testing remains with the owner.


### Apple-design review fixes — 13 October 2026
Implemented the owner's requested contrast, label-size, selection-indicator, navigation-hit-target and accessible Heads Up fixes. Existing floating navigation, font and compact drawer preserved. Validation: clean Flutter analysis, 289 passing tests, including measured secondary-text contrast in both appearances, minimum navigation dimensions, dark selected-dot colour and tap/semantic toggling with reduced motion. Physical screen-reader testing remains a manual check.


### Overflow findings fixed — 14 October 2026
Resolved all seven confirmed overflow/clipping findings. Reproduction matrix now reports zero framework overflows and zero duration-preset clipping in all 270 configurations. Added test/responsive_layout_test.dart with those cases and explicit selected-dropdown/preset intrinsic-height checks. Full suite: 559 passing tests. Static analysis clean; signed arm64 APK built. Representative 320dp/2x dark-mode renders inspected. No backend operations, real alerts or device installation performed.


### Owner screenshot fixes — 19 October 2026
Fixed shared drawer actions behind Android system navigation via bottom SafeArea plus existing keyboard avoidance. Added six modal-route inset tests across 0/24/48dp system bars, keyboard opening/closing, and scrollable/non-scrollable contents. Replaced completed-setup X with horizontal swipe dismissal using the existing persisted preference; incomplete checks cannot dismiss. Added three swipe/persistence checks. Restored trailing contact notification icon alignment and inspected a rendered contact preview with real fonts/icons. Full suite: 568 passing tests, including all 270 responsive scenarios. Analysis clean. Signed arm64 APK prepared for owner testing.
