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
notifyViaSms  bool
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
