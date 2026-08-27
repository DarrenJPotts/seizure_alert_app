# Seizure Alert App — Design System

## Philosophy

Minimal, clinical, and serious. This is a medical app used by people with epilepsy and their caregivers. The design prioritises clarity and calm over personality. No gradients, illustrations, bright colours, or gamified language. Every element should feel purposeful and trustworthy.

---

## Colours

The palette is strictly black and white with opacity variants for hierarchy. No colour is used decoratively, and as of the caregiver-mode pass there is no functional colour either: the monitoring green was replaced by `LiveIndicator`, a pulsing monochrome ring in `lib/core/widgets/live_indicator.dart`. Motion carries "live" — it stays legible for colour-blind users and in bright sunlight, where the neon green was the lowest-contrast element on the screen.

| Role | Value |
|---|---|
| Primary text | `Colors.black` |
| Secondary text | `Colors.black54` |
| Muted / hint text | `Colors.black45` |
| Borders | `Colors.black12` |
| Subtle fills | `Colors.black.withValues(alpha: 0.06–0.08)` |
| Disabled / placeholder | `Colors.black26` |
| Page background | `Colors.white` |
| Inverted surfaces (hero cards, buttons) | `Colors.black` with `Colors.white` text |
| Live status indicator | `LiveIndicator` — monochrome pulsing ring, **no colour** |

Never introduce new colours without a clear functional reason.

---

## Typography

Font family: **Red Hat Display** (loaded via `assets/fonts/`).

Use the theme text styles consistently. Do not set raw `fontSize` unless building a one-off display element.

| Style | Use |
|---|---|
| `headlineSmall` bold | User name in greeting |
| `titleMedium` | Page and section headers |
| `bodyMedium` | Primary body copy, card titles |
| `bodySmall` | Secondary / supporting copy |
| `labelSmall` | Badges, tags, legend labels |

Display elements (hero numbers, SOS label) use explicit sizes but always `FontWeight.w700` and `height: 1`.

---

## Spacing

All spacing comes from `Dimensions` constants. Do not use raw numbers.

```
four = 4     eight = 8     twelve = 12    sixteen = 16
twenty = 20  twentyFour = 24  twentyEight = 28
thirtyTwo = 32  thirtySix = 36  circular = 99
```

Standard screen padding: `Dimensions.twentyFour` on all sides.  
Card internal padding: `Dimensions.sixteen` or `Dimensions.twenty`.  
Between sections: `Dimensions.twentyFour`.  
Between related items: `Dimensions.twelve`.

---

## Components

### Cards / Containers

```dart
Container(
  padding: EdgeInsets.all(Dimensions.sixteen),
  decoration: BoxDecoration(
    border: Border.all(color: Colors.black12),
    borderRadius: BorderRadius.circular(12),
  ),
)
```

Inverted (hero) card uses `color: Colors.black` with no border.  
Border radius is **12** for standard cards, **16** for hero/feature cards.

### Buttons

**Primary (ElevatedButton)**
- Background: `Colors.black`, foreground: `Colors.white`
- Disabled background: `Colors.black38`
- Padding: `EdgeInsets.symmetric(vertical: Dimensions.sixteen)`
- Shape: `BorderRadius.circular(12)`

**Secondary (OutlinedButton)**
- Foreground: `Colors.black`
- Side: `BorderSide(color: Colors.black26)`
- Shape: `BorderRadius.circular(10)`

**Text actions (TextButton / TextButton.icon)**
- Foreground: `Colors.black`
- Used for lightweight header actions (e.g. "Add entry")

### Form fields

```dart
InputDecoration(
  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  border / enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: Colors.black12),
  ),
  focusedBorder: ... BorderSide(color: Colors.black, width: 1.5),
  errorBorder:   ... BorderSide(color: Colors.red, width: 1.5),
)
```

### Dismissible list items

Swipe-to-delete uses `Colors.red.shade50` background with `Colors.red.shade400` icon. Always show a confirmation dialog before deletion.

### Bottom sheets

- `backgroundColor: Colors.white`
- `useSafeArea: true`, `isScrollControlled: true`
- Top handle: 36×4 rounded rect in `Colors.black12`
- Internal padding: `Dimensions.twentyFour` on all sides

---

## Interactive States

Press states use `AnimatedContainer` with `duration: 120–150ms, curve: Curves.easeInOut`.  
Pressed fills invert: white → black background, black → white text.  
Shadows are removed on press (`boxShadow: []`).  
Always call `HapticFeedback` on gesture start:
- `heavyImpact()` for high-stakes actions (SOS)
- `selectionClick()` for standard taps

---

## Language & Copy

- Be direct and clinical. Avoid gamified words: no "streak", "achievement", "score".
- Use plain medical language: "days since last seizure", "alert sent", "seizure-free".
- Error messages are short and actionable.
- Confirmation dialogs use plain verbs: "Remove", "Cancel" — not "Yes" / "No".

---

## File Structure

```
lib/
  core/
    constants/     # Dimensions, AppConstants, firebase keys
    dtos/          # Data transfer objects
    enums/         # GenericScreenStates, etc.
    services/      # FirestoreService (singleton via Get)
  features/
    <feature>/
      view_models/ # GetxController subclasses
      widgets/     # Feature-specific widgets
      <feature>_view.dart
```

Each feature owns its view model. Cross-feature data access uses `Get.find<T>()`. The `RootViewModel` bootstraps all feature view models via `Get.lazyPut`.
