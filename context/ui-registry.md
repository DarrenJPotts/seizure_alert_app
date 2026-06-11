# UI Registry

Living document. Updated after every widget is built. Read this before building any new widget — match existing patterns exactly before inventing new ones.

---

## How to Use

Before building any widget:
1. Check if a similar widget already exists here.
2. If yes — match its exact decoration, spacing, and style tokens.
3. If no — build it following `ui-rules.md` and `ui-tokens.md`, then add it here.

After building any widget — update this file with the widget name, file path, and exact decoration values.

---

## Widgets

### Standard Card Container

Reusable decoration pattern — not a dedicated widget file, used inline everywhere.

| Property | Value |
|---|---|
| Background | `Colors.white` (implicit — page bg) |
| Border | `Border.all(color: Colors.black12)` |
| Border radius | `BorderRadius.circular(12)` |
| Padding | `EdgeInsets.all(Dimensions.sixteen)` |
| Shadow | none |

---

### Hero / Inverted Card Container

Used for the days-since-last-seizure stat on the Home screen.

| Property | Value |
|---|---|
| Background | `Colors.black` |
| Border | none |
| Border radius | `BorderRadius.circular(16)` |
| Padding | `EdgeInsets.all(Dimensions.twenty)` |
| Text colour | `Colors.white` |
| Shadow | none |

---

### SOS Button Widget

File: `lib/features/sos/widgets/sos_button_widget.dart`

| Property | Value |
|---|---|
| Shape | Circle via `BoxDecoration(shape: BoxShape.circle)` |
| Resting background | `Colors.black` |
| Pressed background | `Colors.white` |
| Resting text | `Colors.white`, `FontWeight.w700`, `fontSize: 28`, `height: 1` |
| Pressed text | `Colors.black` |
| Resting shadow | `BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 16, offset: Offset(0, 4))` |
| Pressed shadow | `[]` (removed) |
| Animation | `AnimatedContainer`, `duration: 150ms`, `curve: Curves.easeInOut` |
| Haptic | `HapticFeedback.heavyImpact()` on `GestureDetector.onTapDown` |

**Pattern notes:** The button switches between a large black circle (resting) and white circle with black border (pressed) using `AnimatedContainer`. Size is fixed — do not resize on press.

---

### Status Card Widget

File: `lib/features/home/widgets/status_card_widget.dart`

Used on the Home screen for the "Monitoring Active" / "Last Seizure" hero stat.

| Property | Value |
|---|---|
| Background | `Colors.black` |
| Border radius | `BorderRadius.circular(16)` |
| Padding | `EdgeInsets.all(Dimensions.twenty)` |
| Stat number style | `FontWeight.w700`, `fontSize: 36`, `height: 1`, `color: Colors.white` |
| Stat label style | `textTheme.bodySmall`, `Colors.white54` |
| Monitoring dot | 8×8 `Colors.greenAccent` circle, `BoxShape.circle` |

---

### Recent Activity Card Widget

File: `lib/features/home/widgets/recent_activity_card_widget.dart`

Shows a recent seizure log entry summary.

| Property | Value |
|---|---|
| Container | Standard card (border `Colors.black12`, radius 12, padding `sixteen`) |
| Date/time | `textTheme.bodySmall`, `Colors.black54` |
| Duration | `textTheme.bodyMedium`, `Colors.black` |
| Notes | `textTheme.bodySmall`, `Colors.black45`, max 2 lines, overflow ellipsis |

---

### Add / Edit Bottom Sheet

Applies to: `add_seizure_log_bottom_sheet.dart`, `add_contact_bottom_sheet.dart`, `edit_profile_bottom_sheet.dart`

| Property | Value |
|---|---|
| Background | `Colors.white` |
| `useSafeArea` | `true` |
| `isScrollControlled` | `true` |
| Top handle | 36×4 `Container`, `Colors.black12`, `BorderRadius.circular(99)`, centred, `Dimensions.sixteen` vertical padding |
| Content padding | `EdgeInsets.all(Dimensions.twentyFour)` |
| Section header | `textTheme.titleMedium` |
| Save button | Primary `ElevatedButton`, full-width, `Colors.black` bg |

---

### Primary ElevatedButton

| Property | Value |
|---|---|
| Background (enabled) | `Colors.black` |
| Background (disabled) | `Colors.black38` |
| Foreground | `Colors.white` |
| Padding | `EdgeInsets.symmetric(vertical: Dimensions.sixteen)` |
| Shape | `RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))` |
| Width | `double.infinity` (wrapped in `SizedBox`) |

---

### Secondary OutlinedButton

| Property | Value |
|---|---|
| Foreground | `Colors.black` |
| Border | `BorderSide(color: Colors.black26)` |
| Shape | `RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))` |

---

### Form TextField

| Property | Value |
|---|---|
| Content padding | `EdgeInsets.symmetric(horizontal: 16, vertical: 14)` |
| Border (all states) | `OutlineInputBorder(borderRadius: BorderRadius.circular(12))` |
| Enabled border colour | `Colors.black12` |
| Focused border colour | `Colors.black`, `width: 1.5` |
| Error border colour | `Colors.red`, `width: 1.5` |
| Hint style | `Colors.black26` |
| Label / hint text | Sentence case |

---

### Dismissible List Tile (Contacts / Seizure Log)

| Property | Value |
|---|---|
| Swipe direction | `DismissDirection.endToStart` |
| Background | `Colors.red.shade50` |
| Icon | `Icons.delete_outline`, `Colors.red.shade400` |
| Confirm dialog | `Get.defaultDialog` — title "Remove [item]?", confirm "Remove", cancel "Cancel" |

**Pattern notes:** Always call `Get.defaultDialog` before committing the delete. If the user cancels, call `setState`/update to restore the item to the list.

---

### Monitoring Active Badge (AppBar)

Shown in the `AppBar.title` or `AppBar.actions` area of `RootView`.

| Property | Value |
|---|---|
| Dot | 8×8 `Container`, `BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)` |
| Label | `"Monitoring Active"`, `textTheme.labelSmall`, `Colors.black54` |
| Layout | `Row` with `Dimensions.four` gap between dot and label |

---

### Floating Bottom Navigation Bar

File: `lib/features/root/widgets/floating_bottom_nav_widget.dart`

| Property | Value |
|---|---|
| Background | `Colors.white` |
| Border | `Border.all(color: Colors.black12)` |
| Border radius | `BorderRadius.circular(Dimensions.circular)` (pill-shaped) |
| Selected icon/label | `Colors.black` |
| Unselected icon/label | `Colors.black26` |
| Haptic on tap | `HapticFeedback.selectionClick()` |

---

### Heads Up Timer Display

File: `lib/features/heads_up/heads_up_view.dart`

| Property | Value |
|---|---|
| Countdown text | `FontWeight.w700`, `fontSize: 48`, `height: 1`, `Colors.black` |
| "Time remaining" label | `textTheme.bodySmall`, `Colors.black54` |
| Status chip | Small `Container`, `Colors.black.withValues(alpha: 0.06)`, `BorderRadius.circular(Dimensions.circular)`, `textTheme.labelSmall` |

---

### Alert Responses Widget

File: `lib/core/widgets/alert_responses_widget.dart`

| Property | Value |
|---|---|
| Section header | `textTheme.titleMedium` — "Your circle" |
| Empty state | `textTheme.bodySmall`, `Colors.black45` — "Waiting for your circle to respond..." |
| Avatar | 36×36, `BoxShape.circle`, `Colors.black.withValues(alpha: 0.06)`, initials in `textTheme.labelSmall` `Colors.black54` `FontWeight.w600` |
| Name | `textTheme.bodyMedium` |
| "Responding" badge | `Colors.black` bg, `Colors.white` text, `BorderRadius.circular(20)` |
| "Seen" badge | `Colors.black.withValues(alpha: 0.06)` bg, `Colors.black54` text, `BorderRadius.circular(20)` |
| Row spacing | `Dimensions.eight` between response rows |

**Pattern notes:** `StatefulWidget` — subscribes to `FirestoreService.watchAlertResponses(alertId)` in `initState`, cancels in `dispose`. Placed in `core/widgets/` since it is used from both the active SOS screen and the alert history detail sheet. Shows nothing while loading (returns `SizedBox.shrink()`). Initials computed from first letter of first and last word of `contactName`.

---

### Alert History Card

File: `lib/features/alert_history/alert_history_view.dart` (`_AlertCard`)

| Property | Value |
|---|---|
| Container | Standard card (border `Colors.black12`, radius 12, padding `sixteen`) |
| Icon circle | 40×40, `Colors.black.withValues(alpha: 0.06)`, `BoxShape.circle` |
| Icon | 20px, `Colors.black54` — `warning_amber_rounded` (SOS), `timer_outlined` (Heads Up), `timer_off_outlined` (Expired) |
| Type label | `textTheme.bodyMedium` |
| Timestamp | `textTheme.bodySmall`, `Colors.black45` |
| Status badge | `Colors.black.withValues(alpha: 0.06)` bg, `BorderRadius.circular(20)`, `textTheme.labelSmall` `Colors.black54` — "Active" / "Resolved" / "Cancelled" |
| Chevron | `Icons.chevron_right`, `Colors.black26` |

---

### Alert Detail Bottom Sheet

File: `lib/features/alert_history/alert_history_view.dart` (`_AlertDetailSheet`)

| Property | Value |
|---|---|
| Background | `Colors.white` |
| `useSafeArea` / `isScrollControlled` | both `true` |
| Handle | 36×4, `Colors.black12`, `BorderRadius.circular(circular)` |
| Icon circle | 44×44, `Colors.black.withValues(alpha: 0.06)`, `BoxShape.circle` |
| Header type | `textTheme.titleMedium` |
| Status badge | Same as alert card badge |
| Detail rows | 80px fixed label column (`textTheme.bodySmall` `Colors.black45`) + expanded value (`textTheme.bodySmall`) |
| Map | `SizedBox(height: 180)` — `AlertMapWidget` if coordinates present, else `AlertMapPlaceholder` |

---

### Permission Status Card (Profile)

Used in Profile view to show notification and location permission state.

| Property | Value |
|---|---|
| Container | Standard card (border `Colors.black12`, radius 12, padding `sixteen`) |
| Icon | `Colors.black54`, 20px |
| Label | `textTheme.bodyMedium`, `Colors.black` |
| Status text | `textTheme.bodySmall`, `Colors.black54` (or `Colors.greenAccent` text if granted) |
| Action | `TextButton` with "Enable" / "Open Settings" |
