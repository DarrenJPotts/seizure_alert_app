# Reminders

Open **Profile → Reminders** (also linked from Safety plan). Existing medication reminders migrate as daily medication reminders without changing their name, dose, enabled state, or time.

## User actions

- Add, edit, enable/disable, and remove reminders.
- Choose Medication, Vitamin / supplement, Appointment, or Custom.
- Choose Once, Daily, Selected weekdays, Weekly, or Monthly, a start date, and a local time.
- For weekly vitamins: choose Vitamin / supplement → Weekly → Sun → 09:00 → Save reminder.
- Monthly days 29–31 skip months without that date; the editor explains this.
- When an occurrence is due, mark it taken/completed, skip it, or snooze for 5, 15, 30, or 60 minutes.
- Review recorded actions under History. Unrecorded occurrences are not labelled missed doses.
- Changes save immediately. A separate Save safety plan action is not required.

## Persistence and scheduling

The existing owner-only `users/{uid}.medicationReminders` field stores definitions and the most recent 100 action records per reminder. The legacy field/type name is retained for migration. Removing a reminder removes its history after confirmation. No extra personal-data cache or backend collection is introduced.

Mutations use a Firestore transaction. Per-reminder revisions reject stale edits/actions while preserving additions from other devices. Safety-plan saves update only safety-plan fields, avoiding stale reminder-array overwrites. Authentication is required by the Reminders route, and existing Firestore rules restrict the user document to its owner.

Schedules run locally on each phone, follow the device timezone, and refresh when the app resumes. Native repeat matching handles daily, weekly/selected weekdays, and monthly schedules. Once and snooze notifications do not repeat. Initial future start dates are honoured. Snoozing keeps the regular recurring schedule; completion, skipping, disabling, or removal cancels the outstanding snooze when schedules are replaced. One-off completion/skip disables that reminder.

Reminder notification IDs stay within the existing 100000–799999 range; stale IDs are cancelled without touching SOS notifications. Hash collisions are resolved within a schedule. Account cleanup cancels reminders and clears the cached schedule. Cold reminder-notification launches are routed to Reminders after authentication/profile startup.

Up to 20 reminders and 60 pending reminder schedules are supported, leaving space within the iOS pending-notification limit. History entries describe user-reported actions, not verified medication adherence. Notification delivery uses the existing inexact Android mode and can be delayed by OS settings; on-device delivery has not been verified by the automated tests. Permission/scheduling failures preserve saved reminders and display a retry message.

## Validation

- `flutter test --no-pub` — 688 passing tests after integrating the preview into main.
- `flutter analyze --no-pub` — clean.
- Recurrence tests cover weekly vitamins, selected weekdays, once, short months/leap years, future starts, DST, disabled reminders, snooze, and duplicate completion protection.
- View-model tests cover persistence, transaction conflicts, history bounds, notification failure/retry, account changes, and safety-plan save isolation.
- Platform-channel tests verify native repeat components, notification IDs, timezone refresh, cold launch, and account cleanup.
- UI tests cover 280/390 logical-pixel widths, text scales 1/3, light/dark, editor validation, and creating weekly Sunday vitamins.
- `docs/design/reminders-*.png` are Flutter renders with fictional sample records. Regenerate with `flutter test --no-pub --dart-define=REMINDERS_PREVIEW=true test/reminders_view_test.dart --plain-name "render reminder preview"`.

The autostash from switching `feature/analytics-preview` to `main` was retained. The user explicitly approved bringing Insights and the preview design into main. No merge commit or feature commit was created.
