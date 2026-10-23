# Architecture

## Technology Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.10+, Dart ^3.10.7 |
| State management | GetX 4.7 — `GetxController`, `Rx<T>`, `Obx()` |
| Routing | GetX named routes — `Get.toNamed()`, `Get.offAllNamed()` |
| Dependency injection | GetX — `Get.putAsync`, `Get.lazyPut`, `Get.find<T>()` |
| Database | Cloud Firestore |
| Authentication | Firebase Authentication (email/password) |
| Push notifications | Firebase Cloud Messaging |
| In-app notifications | `flutter_local_notifications` |
| Backend logic | Firebase Cloud Functions (Node.js) |
| Location | `geolocator` |
| Local persistence | `shared_preferences` |
| Maps | `flutter_map` + `latlong2` |

---

## Project Structure

```
lib/
  core/
    constants/
      dimensions.dart           # All spacing values as constants
      firebase_collection_keys.dart  # Firestore collection name strings
      app_constants.dart
      shared_pref_keys.dart
    controllers/
      firebase_auth_controller/
        firebase_auth_controller.dart  # Permanent singleton — auth state, sign in/up/out
    dtos/                        # Data Transfer Objects (Firestore ↔ Dart)
      user_dto.dart
      contact_dto.dart
      seizure_log_dto.dart
      alert_dto.dart
      alert_response_dto.dart
      heads_up_dto.dart          # also contains HeadsUpStatus enum
      result_dto.dart            # Generic result<T> wrapper
    enums/
      generic_screen_states.dart # initial, loading, loaded, error, empty
    services/
      firebase_collections_service.dart  # All Firestore CRUD — singleton via Get
      firebase_messaging_service.dart    # FCM init, token, foreground routing
      local_notifications_service.dart   # Local notification display
      location_service.dart             # Geolocator wrapper
    middlewares/
      auth_middleware.dart        # Redirects unauthenticated users to /login
    routes/
      app_routes.dart             # Route names, GetPage list, initial route
    themes/
      app_theme.dart
      app_colors.dart
    widgets/                     # Shared / cross-feature widgets

  features/
    root/
      root_view.dart             # Main scaffold — IndexedStack + bottom nav
      view_models/               # RootViewModel bootstraps feature VMs
      widgets/
        floating_bottom_nav_widget.dart
    home/
      home_view.dart
      view_models/home_view_model.dart
      widgets/
        status_card_widget.dart
        recent_activity_card_widget.dart
    seizure_log/
      seizure_log_view.dart
      view_models/seizure_log_view_model.dart
      widgets/add_seizure_log_bottom_sheet.dart
    contacts/
      contacts_view.dart
      view_models/contacts_view_model.dart
      widgets/add_contact_bottom_sheet.dart
    sos/
      sos_view.dart
      view_models/sos_view_model.dart
      widgets/sos_button_widget.dart
    heads_up/
      heads_up_view.dart
      view_models/heads_up_view_model.dart
      models/heads_up_dto.dart
      widgets/heads_up_bottom_sheet_widget.dart
    profile/
      views/profile_view.dart
      view_models/profile_view_model.dart
      views/widgets/edit_profile_bottom_sheet.dart
    login/
      views/login_view.dart
      view_models/login_view_model.dart
    signup/
      views/signup_view.dart
      view_models/signup_view_model.dart
    onboarding/
      onboarding_view.dart
      view_models/onboarding_view_model.dart

  main.dart
  dependency_injection.dart      # Get.putAsync for all core services
  firebase_options.dart
```

---

## Data Models (Firestore Collections)

### users
```
uid           String  (document ID)
email         String
displayName   String?
phone         String?
photoUrl      String?
fcmToken      String?
bloodType     String?
seizureType   String?
medications   List<String>
emergencyNote String?
```

### contacts
```
id            String  (auto-generated)
userId        String  (owner UID)
name          String
phone         String
relation      String?
priority      int     (ordering)
notifyViaPush bool
createdAt     String  (ISO 8601)
```

### seizureLogs
```
id              String
userId          String
occurredAt      String  (ISO 8601)
durationSeconds int?
location        String?
latitude        double?
longitude       double?
notes           String?
trigger         String?
alertFired      bool
alertId         String?
```

### alerts
```
id            String
userId        String
type          String  (sos | headsUp | headsUpExpired)
status        String  (sent | resolved | cancelled)
latitude      double?
longitude     double?
locationLabel String?
message       String?
createdAt     String  (ISO 8601)
resolvedAt    String? (ISO 8601)
```

### headsUp
```
id        String
userId    String
createdAt String  (ISO 8601)
expiresAt String  (ISO 8601)
note      String?
status    String  (active | checkedIn | expired | escalated | cancelled)
```

### alert_responses
```
id           String
alertId      String
contactId    String
contactName  String
seen         bool
responding   bool
seenAt       String? (ISO 8601)
respondedAt  String? (ISO 8601)
```

---

## Critical Patterns

**GetX dependency injection order**: Services are registered via `Get.putAsync` in `dependency_injection.dart` before the app starts. Feature view models are registered lazily via `Get.lazyPut` inside `RootViewModel.onInit`.

**Cross-feature data access**: Use `Get.find<T>()` to access another feature's view model. Never import a view model from another feature directly.

**Firestore stream subscriptions**: Always cancel stream subscriptions in `onClose()` on the view model. Use `watchX()` methods in `FirebaseCollectionsService` for real-time listeners.

**Active alert persistence**: Active SOS and Heads Up state is stored in SharedPreferences so it survives cold restarts. On app launch, view models check SharedPreferences before querying Firestore.

**Cloud Function triggers**: Writing an alert document with `status == "sent"` triggers the `onAlertCreated` Cloud Function. Updating `status` to `"cancelled"` triggers `onAlertUpdated`. Never call FCM directly from the app.

**Auth guard**: `AuthMiddleware` runs on every navigation to `root` and `onboarding`. If `FirebaseAuth.instance.currentUser == null`, it redirects to `/login`. After login, `RootViewModel.onInit` checks whether the user has completed onboarding (by fetching their Firestore profile); if no profile exists, it redirects to `/onboarding`.

**Location capture**: Always use `LocationService.getCurrentPosition()` — it handles permission checks and timeouts. Never call `Geolocator` directly in a view model.

## Safety expansion collections

### wearableDevices

Public-to-owner device state: device name, Garmin product identifier, battery,
pairing time, and last-seen time. Clients may read their own records but cannot
write them.

### wearable_pairings

Server-only short-lived pairing challenges. The six-digit code is hashed, can
be consumed once, and is removed by TTL after expiry.

### wearable_device_credentials

Server-only wearable bearer credentials. Firebase stores only the credential
hash and revocation state. Removing a wearable revokes the credential before
deleting its owner-visible device record.

### alert_deliveries

Server-owned delivery state for each alert/contact pair. The owner and linked
responder may read their relevant rows; mobile clients cannot write them.
Statuses distinguish FCM acceptance, unavailable installations, failures, and
later escalation reminders.

## Wearable and escalation boundaries

Garmin HTTPS handlers authenticate the hashed wearable credential and call the
same alert-document path used by the phone. The existing `onAlertCreated`
trigger remains the only push fan-out owner. An active watch SOS is deduplicated
against the user's current sent SOS before a new alert and seizure record are
created.

Unanswered-alert escalation is a Cloud Task chain, not a scheduled poll. Each
stage reloads the alert and responses, exits on resolution or acknowledgement,
and targets the next caregiver priority. The chain is capped at three stages.
All handlers have `minInstances: 0` and the global development billing kill
switch is checked before work proceeds.

Safety plans and medication reminder definitions live on the user document.
Medication alarms are scheduled locally by `LocalNotificationsService`; saving
or firing them creates no recurring Firebase activity. PDF/CSV seizure reports
are generated in memory and handed directly to the operating-system share sheet.


### Current UI direction — 13 October 2026
The owner reverted the UI overhaul trial. Its labelled navigation, inline Heads Up and reordered Home layout are historical proposals, not the current baseline. Preserve the Apple-style floating pill navigation, raised SOS and existing hierarchy. The subsequent focused pass reduces navigation item padding on narrow screens, fits the SOS circle/label to available width, and measures the Heads Up heading for large-text clearance. Validation: clean Flutter analysis and 276 passing tests.


### Dark-mode implementation — 13 October 2026
Enabled the existing persisted ThemeController preference and added Profile > Appearance (System/Light/Dark). Custom UI now resolves monochrome roles from its inherited theme via AppPalette; dark background #181818 and cards #2D2D2D. Navigation and screen hierarchy preserved. Heads Up restored to the earlier 10% collapsed extent per owner request. Theme-aware system bars and scrollable appearance controls included. Clean analysis and 285 passing tests, including preference restoration, live theme switching without losing the open sheet, system brightness, patient/caregiver navigation at 280/390dp, short-screen large text, contrast and compact sheet extent. Rendered Home/SOS/Settings component previews reviewed; physical device testing remains with the owner.
