# Code Standards

## Engineering Mindset

Read the context files before implementing. Respect the feature boundary — a feature's view model must not reach into another feature's service layer directly, only via `Get.find<T>()`. Complete features sequentially. Implement `try/catch` on all async operations. Prioritise clarity over cleverness.

---

## Dart / Flutter

- Use `const` everywhere the compiler allows it.
- Prefer named constructors and factory constructors for DTOs (`UserDto.fromMap(map)`).
- All `async` functions must have `try/catch`; never let Firebase exceptions bubble up silently.
- Never use `dynamic` — use explicit types or `Object?`.
- Use `late` only when initialisation is guaranteed before first read (e.g. `TextEditingController` in `onInit`).
- Prefer `final` for all fields that are not reassigned.

---

## GetX Conventions

- Every screen has a paired `GetxController` subclass in `view_models/`.
- Observable state uses `Rx<T>` — e.g. `Rx<GenericScreenStates> screenState = GenericScreenStates.initial.obs`.
- Lists use `RxList<T>`, nullable objects use `Rxn<T>`.
- Bind with `Obx(() => ...)`. Never use `setState` or `StatefulWidget` for feature state.
- Initialise subscriptions in `onInit()`, cancel them in `onClose()`.
- Access another feature's VM with `Get.find<OtherViewModel>()`, never by importing its file from a different feature.
- Controllers registered via `Get.lazyPut` in `RootViewModel.onInit` (feature VMs). Core services use `Get.putAsync` in `dependency_injection.dart`.
- `Get.toNamed(AppRoutes.routeName)` for navigation. `Get.offAllNamed` for auth transitions.

---

## File & Folder Naming

| Thing | Convention |
|---|---|
| Folders | `snake_case` |
| Dart files | `snake_case.dart` |
| Classes | `PascalCase` |
| Variables / functions | `camelCase` |
| Constants | `camelCase` (in constants files) |
| Route name strings | `camelCase` stored as `static const` on `AppRoutes` |

One class per file. Widgets live under `widgets/` inside their feature folder unless they are used across multiple features (then `core/widgets/`).

---

## DTO Pattern

All Firestore documents map through a DTO class in `core/dtos/`. DTOs have:
- A plain Dart constructor with named parameters.
- A `UserDto.fromMap(Map<String, dynamic> map)` factory constructor.
- A `toMap()` method returning `Map<String, dynamic>`.
- All fields typed explicitly. Use `as String?` casts from the map, not `dynamic`.

Example pattern:
```dart
factory UserDto.fromMap(Map<String, dynamic> map) => UserDto(
  uid: map['uid'] as String,
  email: map['email'] as String,
  displayName: map['displayName'] as String?,
);

Map<String, dynamic> toMap() => {
  'uid': uid,
  'email': email,
  'displayName': displayName,
};
```

---

## Firestore Service

- All Firestore access goes through `FirebaseCollectionsService` — never call `FirebaseFirestore.instance` directly in a view model or widget.
- Real-time listeners (`snapshots()`) return a `Stream<T>` — assign them in `onInit`, cancel in `onClose`.
- Write operations return `ResultDto<T>` — check `isSuccess` before proceeding.
- Collection name strings come from `FirebaseCollectionKeys` constants only.

---

## Screen State

Use `GenericScreenStates` to drive loading/empty/error UI:
```dart
screenState.value = GenericScreenStates.loading;
// ... await fetch
screenState.value = result.isEmpty ? GenericScreenStates.empty : GenericScreenStates.loaded;
```
Always set a state before and after async operations so the UI never shows stale data.

---

## Error Handling

- Wrap every Firestore and Firebase Auth call in `try/catch`.
- Log errors to the console with a feature prefix: `debugPrint('[ContactsVM] Error adding contact: $e')`.
- Surface user-facing errors as short, actionable `Get.snackbar` messages.
- Never show a raw exception message to the user.

---

## Widgets

- Prefer `StatelessWidget` for all UI components.
- Pass callbacks down from the view model to widgets — widgets do not call `Get.find` directly.
- Use `Dimensions` constants for all padding and spacing — never hardcode pixel values.
- Use text styles from `Theme.of(context).textTheme` — never set raw `fontSize`.

### Widget file placement

**Break up large build methods.** Any widget or private class that exceeds ~50 lines of build logic must be extracted into its own file. Do not let a single view file grow to contain multiple large widget classes inline.

**Feature-specific widgets** go in the feature's `views/widgets/` folder:
```
lib/features/<feature>/views/widgets/<widget_name>.dart
```
Example: a card used only in the seizure log lives at `lib/features/seizure_log/views/widgets/seizure_log_card.dart`.

**Shared widgets** — used by two or more features — go in `lib/core/widgets/`:
```
lib/core/widgets/<widget_name>.dart
```
Example: `AlertMapWidget` and `AlertResponsesWidget` live in `lib/core/widgets/` because multiple features use them.

**Decision rule:** if you are building a widget and asking "where does this go?":
1. Only used in one feature → `lib/features/<feature>/views/widgets/`
2. Used in two or more features, or likely to be → `lib/core/widgets/`
3. Never leave a large widget class private inside its view file when it deserves its own file

---

## Bottom Sheets

Open with:
```dart
showModalBottomSheet(
  context: context,
  backgroundColor: Colors.white,
  useSafeArea: true,
  isScrollControlled: true,
  builder: (_) => const MyBottomSheet(),
);
```
Internal structure: top drag handle (36×4 rounded rect), `Padding(padding: EdgeInsets.all(Dimensions.twentyFour))`, then content.

---

## Comments

Write comments only when the **why** is non-obvious. Never describe what the code does — the code does that. No TODO comments committed.

---

## Dependencies

Packages already in `pubspec.yaml` are the approved set. Do not add new packages without confirming with the user. Any addition must have a clear functional reason that cannot be met by an existing dependency.
