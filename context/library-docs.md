# Library Docs

Project-specific usage patterns for third-party packages. Read this before implementing any feature that touches these libraries.

---

## GetX

**Dependency injection:**
- Core services: `Get.putAsync<T>(() async => ...)` in `dependency_injection.dart`, called from `main()` before `runApp`.
- Feature view models: `Get.lazyPut<T>(() => ...)` inside `RootViewModel.onInit` — registered once, reused everywhere.
- Access: `Get.find<T>()` — never import a VM file from another feature folder.

**State:**
- Scalars: `RxBool`, `RxInt`, `RxString`, `Rx<MyEnum>`
- Nullables: `Rxn<T>` (wraps `T?`)
- Lists: `RxList<T>`
- Update with `.value =` assignment or `.obs` mutation methods.
- Rebuild UI with `Obx(() => Widget)`.

**Navigation:**
- `Get.toNamed(AppRoutes.name)` — push named route.
- `Get.offAllNamed(AppRoutes.name)` — clear stack and push (used for auth transitions).
- `Get.back()` — pop.
- `Get.defaultDialog(...)` / `Get.snackbar(...)` — dialogs and toasts.
- Never use `Navigator.of(context)` directly.

**Lifecycle:**
- `onInit()` — subscribe to streams, start timers, fetch initial data.
- `onClose()` — cancel stream subscriptions, dispose controllers, cancel timers.

---

## Firebase Authentication

- Only `FirebaseAuthController` interacts with `FirebaseAuth.instance`.
- `signIn(email, password)` → returns `ResultDto<UserCredential>`.
- `registerUser(email, password)` → returns `ResultDto<UserCredential>`.
- `signOut()` → clears SharedPreferences, signs out, navigates to login.
- Auth state changes are exposed as `Rx<User?>` — observe with `Obx`.
- On registration, the calling VM immediately calls `FirebaseCollectionsService.upsertUser` to create the Firestore profile.

---

## Cloud Firestore (via FirebaseCollectionsService)

- Never call `FirebaseFirestore.instance` directly in a view model or widget.
- Collection names come exclusively from `FirebaseCollectionKeys` constants.
- Write operations use `.set(doc, SetOptions(merge: true))` for upserts.
- Real-time queries return `Stream<QuerySnapshot>` — map to DTOs in the service method before returning to the VM.
- Always scope queries to the current user's `userId` field.
- Delete with `.delete()` after user confirms in a dialog.
- Use `FieldValue.serverTimestamp()` only if you need server-authoritative timestamps; otherwise use `DateTime.now().toIso8601String()` for consistency with the DTO string pattern.

---

## Firebase Cloud Messaging

- `FirebaseMessagingService` is the single point of entry — never call `FirebaseMessaging.instance` directly.
- FCM token is fetched in `FirebaseMessagingService.init()` and stored in the user's Firestore document via `updateFcmToken`.
- Foreground messages are routed to `LocalNotificationsService.showNotification`.
- Background/terminated message handling is registered via `FirebaseMessaging.onBackgroundMessage(_handler)` — the handler must be a top-level function.
- Do NOT send FCM messages from the Flutter app. All notifications are sent by Cloud Functions triggered by Firestore writes.

---

## flutter_local_notifications

- Only `LocalNotificationsService.showNotification(title, body, payload)` should be called.
- Android notification channel is created during `init()` — channel ID and name are constants.
- Notification tap callbacks navigate using `Get.toNamed`.
- Do not create additional notification channels without a clear reason.

---

## geolocator (via LocationService)

- Always call `LocationService.getCurrentPosition()` — returns `Position?` (null on permission denied or timeout).
- Never call `Geolocator.getCurrentPosition()` directly in a view model.
- Permission checks are handled internally — the service returns null rather than throwing if location is unavailable.
- Location is only captured when an alert is being created (SOS start, Heads Up start).

---

## shared_preferences

- Keys are defined as constants in `SharedPrefKeys`.
- Active SOS state (`alertId`) is stored so that if the app is killed during an active alert, `SosViewModel.onInit` can restore state.
- Active Heads Up state (`headsUpId`, `expiresAt`) is similarly persisted.
- Clear keys when the alert is resolved/cancelled.
- Do not store sensitive medical data in SharedPreferences — use Firestore.

---

## permission_handler

- Used in `ProfileViewModel` and `OnboardingViewModel` for notification and location permissions.
- Call `Permission.notification.status` / `Permission.location.status` to check.
- Call `Permission.notification.request()` / `Permission.location.request()` to request.
- If permanently denied, open settings with `AppSettings.openAppSettings()`.
- Always update `notificationsEnabled` / `locationEnabled` Rx booleans after any permission change.

---

## url_launcher

- Only `InviteService.sendSmsInvite({required String phone})` should be called — never use `launchUrl` directly in a view or view model.
- Builds the invite message with the sender's display name (from `FirebaseAuth.instance.currentUser?.displayName`).
- Launches `sms:PHONE?body=ENCODED_MESSAGE` using `launchUrl`.
- Falls back to `Clipboard.setData` + snackbar if the SMS scheme is unavailable.
- Android requires the `<intent android:scheme="sms"/>` query in `AndroidManifest.xml` — already present.
- The app download URL is a constant inside `InviteService` (`https://seizurealert.app`) — update this when the app is published.

---

## flutter_map + latlong2

- Used in `AlertMapWidget` to render a map centred on the alert's coordinates.
- Always provide a fallback widget when `latitude == null || longitude == null`.
- Map tiles use the default OpenStreetMap tile provider.
- Do not add `flutter_map` interactions (pan, zoom) in the alert detail context — the map is display-only.
