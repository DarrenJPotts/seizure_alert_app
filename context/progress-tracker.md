# Progress Tracker

Update this file after every completed feature. Any AI agent reading this should immediately know what is done, what is in progress, and what is next.

---

## Current Status

**Phase:** Phase 5 — Polish & Reliability
**Last completed:** 17 Contact responses
**Next:** 18 Notification deep-link

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
- [x] 15 Profile — Edit (bottom sheet, Firestore update)

### Phase 5 — Polish & Reliability

- [x] 16 Alert history
- [x] 17 Contact responses (real-time alert_responses stream)
- [ ] 18 Notification deep-link
- [ ] 19 Firestore security rules audit
- [ ] 20 Offline resilience

---

## Notes

- Feature 17: `AlertResponsesWidget` (`lib/core/widgets/`) is a `StatefulWidget` that subscribes to `watchAlertResponses(alertId)`. Placed in two locations: (1) active SOS screen — below the map, using `sosVm.activeSos.value?.id`; (2) `_AlertDetailSheet` in alert history — using `alert.id`. Empty state shows "Waiting for your circle to respond..."; populated state shows avatar initials + name + "Responding" (black filled) or "Seen" (subtle) badge. Active SOS view was refactored from `Expanded` map to `SingleChildScrollView` + fixed 150px map + responses section, keeping the cancel button pinned at the bottom.

- Feature 16: `AlertHistoryViewModel` streams `watchRecentAlerts` (last 20 alerts, descending). Route `/alert-history` uses `AlertHistoryBinding` for lazy VM registration. Entry point is a history icon button in the root AppBar. Tapping an alert card opens `_AlertDetailSheet` (modal bottom sheet) showing timestamps, optional message/location label, and `AlertMapWidget` / `AlertMapPlaceholder` depending on whether coordinates exist.



- FCM token is fetched and saved to Firestore on every app launch via `FirebaseMessagingService.init()` — this keeps tokens fresh without a manual refresh flow.
- `HeadsUpViewModel` auto-escalates to `headsUpExpired` alert type when the countdown reaches zero — the Cloud Function picks this up and notifies contacts.
- The 28-day activity grid in `HomeViewModel.gridData` returns a 28-element list of booleans; `true` means at least one seizure occurred on that day. The grid renders 4 rows × 7 columns (oldest → newest, left to right, top to bottom).
- `AlertDto.type` drives the Cloud Function notification copy — keep the three string values (`sos`, `headsUp`, `headsUpExpired`) in sync between the Flutter app and `functions/index.js`.
- `firestore.rules` uses `request.auth.uid == resource.data.userId` for ownership checks on contacts, seizureLogs, alerts, and headsUp. The `alert_responses` collection allows any authenticated user to create a response (contacts responding to an alert they received), but only the owner can update/delete.
- `lib/core/widgets/alert_map_widget.dart` exists as an untracked file — it displays a `flutter_map` centred on alert coordinates. It is not yet wired into any screen (planned for Feature 16 alert history).
