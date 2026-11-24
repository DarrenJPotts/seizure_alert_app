# Seizure Alert App — Design System

## Philosophy

Minimal, clinical, and serious. This is a medical app used by people with epilepsy and their caregivers. The design prioritises clarity and calm over personality. No gradients, illustrations, bright colours, or gamified language. Every element should feel purposeful and trustworthy.

Users may be post-seizure (confused, low motor control) and caregivers may be panicked, one-handed and outdoors in sunlight. Design for that person first.

---

## Colours

The palette is monochrome, in a light and a dark theme. No colour is used decoratively, and there is no functional colour for "live": `LiveIndicator` (`lib/core/widgets/live_indicator.dart`), a pulsing monochrome ring, carries it. Motion stays legible for colour-blind users and in bright sunlight.

**Never hardcode `Colors.black`, `Colors.white`, `Colors.black54` and so on in feature code.** They break dark mode. Use the role getters from `lib/core/themes/app_palette.dart` and `app_design.dart`, or the theme's `ColorScheme`:

| Role | Use | Light | Dark |
|---|---|---|---|
| Primary text, icons | `context.ink` | near-black | near-white |
| Secondary text | `context.secondaryInk` | `#595959` | `#B0B0B0` |
| Page background | `context.design.pageSurface(scheme)` | `#F3F3F3` | `#161616` |
| Cards, panels | `context.paper` / `context.cardSurface` | white | `#252525` |
| Hero surface (SOS header, inverted cards) | `context.heroSurface` + `context.heroInk` | `#303030` + white | `#303030` + white |
| Card border | `context.designBorder` | ink at 4% | ink at 4% |
| Card shadow | `context.designShadows` | | |
| Errors, destructive backgrounds | `colorScheme.error`, `errorContainer` / `onErrorContainer` | | |
| Live status | `LiveIndicator`, no colour | | |

`secondaryInk` switches to full `ink` when the system high-contrast setting is on.

Text must meet WCAG AA: 4.5:1 for body text, 3:1 for large text and for borders that carry meaning. Do not use ink below 60% opacity for text.

### Screens that are always dark

The caregiver alert screen (`incoming_alert_view.dart`) is black in both themes. It defines `_alertSurface` and `_alertInk` and **every** text style on it must set `color: _alertInk` explicitly. Theme text styles default to the theme's ink, which is near-black in light mode and invisible on that screen.

### Dark mode

`ThemeController` (`lib/core/controllers/theme_controller/`) stores the user's choice (system, light, dark); the default is system. `color_schemes.dart` and `colors/` hold both schemes. Check every new screen in both themes.

---

## Typography

Font family: **Red Hat Display** (loaded via `assets/fonts/`), applied through `AppTheme`. Headings are weight 600 (`AppDesign.applyTypography`).

Use the theme text styles. Do not set a raw `fontSize` unless building a one-off display element.

| Style | Use |
|---|---|
| `headlineMedium` | User name in greeting (`AppDesign.greetingStyle`) |
| `titleMedium` | Page and section headers |
| `bodyMedium` | Primary body copy, card titles |
| `bodySmall` | Secondary / supporting copy |
| `labelSmall` | Badges, tags, legend labels |

Display elements (hero numbers, the SOS countdown) use explicit sizes but always `FontWeight.w700` and `height: 1`, and must not overflow at 200% text size.

---

## Spacing and shape

All spacing comes from `Dimensions` constants (`lib/core/constants/dimensions.dart`). Do not use raw numbers.

```
two = 2   three = 3   four = 4   six = 6   eight = 8   ten = 10
twelve = 12   fourteen = 14   sixteen = 16   eighteen = 18   twenty = 20
twentyTwo = 22   twentyFour = 24   twentySix = 26   twentyEight = 28
thirtyTwo = 32   thirtySix = 36   fortyEight = 48   circular = 99
```

Visual constants live on the `AppDesign` theme extension (`context.design`):

| Value | Getter | Amount |
|---|---|---|
| Standard card / button radius | `cardRadius` | 24 |
| Feature / hero card radius | `featureRadius` | 32 |
| Bottom nav radius | `navRadius` | 28 |
| Bottom sheet top radius | `featureRadius + 8` | 40 |
| Card padding | `cardPadding` | 20 |
| Gap between sections | `sectionGap` | 32 |

Use these getters instead of `BorderRadius.circular(16)` and similar literals. Standard screen padding is `Dimensions.twentyFour`.

---

## Components

### Cards

```dart
Container(
  padding: EdgeInsets.all(context.design.cardPadding),
  decoration: BoxDecoration(
    color: context.cardSurface,
    border: context.designBorder,
    boxShadow: context.designShadows,
    borderRadius: BorderRadius.circular(context.design.cardRadius),
  ),
)
```

Hero (inverted) cards use `context.heroSurface` with `context.heroInk` text and no border.

### Buttons

Button styles come from the theme (`AppTheme`); do not restyle them per screen without a reason.

- Primary (`ElevatedButton`): `colorScheme.primary` (`#303030` light, `#F4F4F4` dark), `cardRadius`, minimum 48 dp high.
- Secondary (`OutlinedButton`): `colorScheme.outline` border, `cardRadius`, minimum 48 dp.
- Text actions (`TextButton`): lightweight header actions such as "Add entry".

**Touch targets are at least 48 dp.** Primary actions on emergency screens (Call, Directions, Call emergency services) are at least 52 dp and full width. Never make an important action a bare `GestureDetector` or a text link; use a button so it gets a role, focus and a target size.

### Form fields

Use the theme's `inputDecorationTheme`. Error borders use `colorScheme.error`.

### Snackbars

Use `showAppSnackbar(title, message)` from `lib/core/helpers/app_snackbar.dart`. It uses the theme's inverse surface, so it is readable in both themes and on the black alert screen. Do not call `Get.snackbar` without colours: its default is black text on translucent grey.

### Deleting items

Swipe-to-delete backgrounds use `colorScheme.errorContainer` with an `onErrorContainer` icon. Always show a confirmation dialog before deletion. Swipe must not be the only way to delete: users with limited motor control and screen-reader users need a visible action too.

### Bottom sheets

Use `AppBottomSheet` (`lib/core/widgets/bottom_sheet/`). It applies the theme's sheet colour, the 40 radius, `useSafeArea` and `isScrollControlled`.

---

## States

Every screen that loads data has four states: loading, loaded, empty, and error. Error states always offer a way forward ("Try again", and on emergency screens a call button). Never show "not found" or "no longer available" for a failure that might be temporary, such as being offline.

---

## Interactive States

Press states use `AnimatedContainer` with `duration: 120–150ms, curve: Curves.easeInOut`.
Pressed fills invert. Shadows are removed on press (`boxShadow: []`).
Always call `HapticFeedback` on gesture start:
- `heavyImpact()` for high-stakes actions (SOS, calling the person, calling emergency services)
- `selectionClick()` for standard taps

Respect reduced motion (`MediaQuery.disableAnimations`) for anything that pulses or loops.

---

## Accessibility

- Icon-only buttons need a `tooltip` or `semanticLabel`.
- Live regions (`Semantics(liveRegion: true)`) must not change every second; a ticking clock re-announces constantly. `LiveStatusLabel` takes a separate `semanticsLabel` for this.
- Check layouts at 200% text size.

---

## Language & Copy

- Be direct and clinical. Avoid gamified words: no "streak", "achievement", "score".
- Use plain medical language: "days since last seizure", "alert sent".
- Do not claim more than the app knows. A day with no entry is "No seizure logged", not "Seizure-free". Before an alert is sent, say "Your circle will be alerted when the timer ends", not "help is on the way".
- Error messages are short and actionable.
- Confirmation dialogs use plain verbs that name the action: "Remove", "Cancel SOS and sign out", "Switch" — not "Yes" / "No". Say what the consequence is.
- Sentence case for buttons and titles.

---

## Data conventions

- Moments in time (when a seizure, alert or response happened) are stored as UTC ISO-8601 strings ending in `Z`. Use `toStoredTimestamp` and `parseStoredTimestamp` from `lib/core/helpers/timestamps.dart`; they also read old local values written without an offset. Show times in local time.
- Calendar dates (daily logs, cycle days) are stored as dates, not moments.
- The emergency number dialled from the caregiver screens is `CallService.emergencyNumber` (112).

---

## File Structure

```
lib/
  core/
    constants/     # Dimensions, AppConstants, firebase keys
    dtos/          # Data transfer objects
    enums/         # GenericScreenStates, etc.
    helpers/       # Timestamps, snackbars, phone numbers, schedules
    services/      # FirestoreService (singleton via Get)
    themes/        # AppTheme, AppDesign, AppPalette, colour schemes
  features/
    <feature>/
      view_models/ # GetxController subclasses
      widgets/     # Feature-specific widgets
      <feature>_view.dart
functions/         # Cloud Functions; pure logic in its own modules with tests
```

Each feature owns its view model. Cross-feature data access uses `Get.find<T>()`. The `RootViewModel` bootstraps all feature view models via `Get.lazyPut`.

### Cloud Functions

- Safety-critical functions (alerts, escalation, Heads Up, watch actions, caregiver alert screens) are guarded by the Remote Config flag `sos_functions_enabled` (`functions/safety-flag.js`), never by the budget kill switch.
- Keep logic that can be unit-tested out of `functions/index.js`, which calls `initializeApp()` at load. Run `npm test` in `functions/`.
