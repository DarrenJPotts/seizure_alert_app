# Build Plan

Development roadmap for the Seizure Alert app. Features are grouped into phases. Complete features sequentially — build UI with mock/static data first, wire real data second, then verify before marking done.

---

## Approach

1. Build UI to match the design with static/mock data.
2. Wire the view model and Firestore service.
3. Test the feature end-to-end on device.
4. Update `progress-tracker.md`.

---

## Phase 1 — Foundation

- [x] **01 Project setup** — Firebase init, GetX routing, dependency injection, auth middleware
- [x] **02 Auth — Login** — Email/password sign-in, route to root
- [x] **03 Auth — Sign Up** — Email/password registration, create Firestore user, route to onboarding
- [x] **04 Onboarding** — 3-step flow: display name, first emergency contact, notification + location permissions. Saves UserDto + first ContactDto to Firestore.
- [x] **05 Root scaffold** — Bottom tab nav (Home, Seizure Log, SOS, Contacts, Profile), AppBar with monitoring badge

---

## Phase 2 — Core Safety Features

- [x] **06 SOS alert** — Full-screen SOS button, start/cancel flow, elapsed timer, GPS capture, Firestore alert write, SharedPreferences persistence, haptic feedback
- [x] **07 Heads Up** — Check-in timer with 30/60/120 min options, start/cancel/check-in flow, auto-expiry escalation, countdown display, Firestore headsUp + alert writes, SharedPreferences persistence
- [x] **08 Cloud Functions** — `onAlertCreated` and `onAlertUpdated` triggers: fetch contact circle, resolve FCM tokens, send push notifications with correct copy per alert type

---

## Phase 3 — Data & Log

- [x] **09 Seizure log — List view** — List of seizure entries, newest first, empty state
- [x] **10 Seizure log — Add entry** — Bottom sheet: date/time picker, duration, trigger, location (auto-captured), notes. Saves to Firestore.
- [x] **11 Contacts — List view** — Priority-ordered contact list, relation badge, notification flags visible, swipe-to-delete with confirmation
- [x] **12 Contacts — Add/edit contact** — Bottom sheet: name, phone, relation, priority, SMS/push toggles. Upsert to Firestore.

---

## Phase 4 — Dashboard & Profile

- [x] **13 Home — Dashboard** — Greeting (time-based), days-since-last-seizure hero card, last 7 days count, this month count, 28-day activity grid
- [x] **14 Profile — View** — Display name, medical info (blood type, seizure type, medications, emergency note), permission status cards (notifications, location)
- [x] **15 Profile — Edit** — Bottom sheet: update all profile fields, save to Firestore

---

## Phase 5 — Polish & Reliability

- [x] **16 Alert history** — View past alerts (SOS and Heads Up) on a dedicated screen, with status (resolved, cancelled), timestamp, and location map if available
- [x] **17 Contact responses** — real-time `alert_responses` stream on active SOS + alert history detail
- [x] **18 App invite** — Invite picker (SMS, WhatsApp, clipboard fallback) from add-contact sheet (toggle, default on) + send-invite icon on each contact card (`url_launcher`)
- [x] **19 Notification deep-link** — SOS alerts only: tapping a "sent"-status SOS push opens the Incoming Alert screen. Heads Up / Heads Up Expired notifications still just open the app — no dedicated detail screen exists for those yet, so this remains a gap.
- [ ] **20 Firestore security rules audit** — Review and tighten all rules; verify that alert_responses allow contact-side writes correctly
- [ ] **21 Offline resilience** — Test app behaviour with no network; confirm alerts queue and fire when connectivity returns; show an appropriate offline banner
- [x] **22 Caregiver mode** — Redesigned SOS send-countdown + active-alert "status board"; new "People I watch" list and Incoming Alert detail screen backed by two admin-privileged Cloud Functions (`getPeopleIWatch`, `getAlertDetail`), since `firestore.rules` stays owner-only

---

## Decisions Made During Build

- `RootViewModel.onInit` checks Firestore for a user profile and redirects to `/onboarding` if absent — this is the new-user gate, not a separate auth check.
- Active SOS and Heads Up IDs are persisted in `SharedPreferences` so cold restarts restore state without a Firestore round-trip.
- Cloud Functions send all push notifications — the Flutter app never calls FCM directly.
- All timestamps stored as ISO 8601 strings in Firestore (not Firestore `Timestamp`) for consistency with DTO serialisation.
- `priority` on `ContactDto` is a plain integer; the UI shows contacts ordered ascending by priority. Lower number = higher priority.
- `flutter_map` is included for displaying alert location but is currently only used in `AlertMapWidget` — no feature actively navigates to it yet (planned for Phase 5 alert history).
