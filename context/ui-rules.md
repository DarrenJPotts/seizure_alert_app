# UI Rules

## Core Philosophy

This is a medical app used by people with epilepsy and their caregivers. The design is minimal, clinical, and serious. No gradients, no illustrations, no bright colours, no gamified language. Every element should feel purposeful and trustworthy.

---

## Colour

The palette is strictly black and white with opacity variants for hierarchy. Colour is never decorative. The single exception is the monitoring indicator green, which communicates live status.

| Role | Value |
|---|---|
| Primary text | `Colors.black` |
| Secondary text | `Colors.black54` |
| Muted / hint text | `Colors.black45` |
| Borders | `Colors.black12` |
| Subtle fills | `Colors.black.withValues(alpha: 0.06–0.08)` |
| Disabled / placeholder | `Colors.black26` |
| Page background | `Colors.white` |
| Inverted surfaces (hero cards, primary buttons) | `Colors.black` with `Colors.white` text |
| Monitoring dot only | `Colors.greenAccent` |

Never introduce new colours without a clear functional reason approved in advance.

---

## Typography

Font family: **Red Hat Display** — loaded from `assets/fonts/`.

Use `Theme.of(context).textTheme` styles consistently. Do not set raw `fontSize` unless building a one-off display element.

| Style | Use |
|---|---|
| `headlineSmall` + `FontWeight.bold` | User name in greeting |
| `titleMedium` | Page and section headers |
| `bodyMedium` | Primary body copy, card titles |
| `bodySmall` | Secondary / supporting copy |
| `labelSmall` | Badges, tags, legend labels |

Display elements (hero numbers, SOS elapsed timer, SOS label) use explicit sizes but always `FontWeight.w700` and `height: 1`.

---

## Spacing

All spacing comes from `Dimensions` constants. Never use raw numbers.

```dart
Dimensions.four       // 4
Dimensions.eight      // 8
Dimensions.twelve     // 12
Dimensions.sixteen    // 16
Dimensions.twenty     // 20
Dimensions.twentyFour // 24
Dimensions.twentyEight // 28
Dimensions.thirtyTwo  // 32
Dimensions.thirtySix  // 36
Dimensions.circular   // 99 (fully rounded)
```

Standard screen padding: `Dimensions.twentyFour` on all sides.
Card internal padding: `Dimensions.sixteen` or `Dimensions.twenty`.
Between sections: `Dimensions.twentyFour`.
Between related items: `Dimensions.twelve`.

---

## Cards & Containers

**Standard card:**
```dart
Container(
  padding: EdgeInsets.all(Dimensions.sixteen),
  decoration: BoxDecoration(
    border: Border.all(color: Colors.black12),
    borderRadius: BorderRadius.circular(12),
  ),
)
```

**Hero / inverted card:**
```dart
Container(
  padding: EdgeInsets.all(Dimensions.twenty),
  decoration: BoxDecoration(
    color: Colors.black,
    borderRadius: BorderRadius.circular(16),
  ),
)
```
Hero cards use `Colors.white` text and no border.

---

## Buttons

**Primary (ElevatedButton):**
- Background: `Colors.black` / foreground: `Colors.white`
- Disabled background: `Colors.black38`
- Padding: `EdgeInsets.symmetric(vertical: Dimensions.sixteen)`
- Shape: `RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))`
- Full-width by default: wrap in `SizedBox(width: double.infinity)`

**Secondary (OutlinedButton):**
- Foreground: `Colors.black`
- Side: `BorderSide(color: Colors.black26)`
- Shape: `RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))`

**Text actions (TextButton / TextButton.icon):**
- Foreground: `Colors.black`
- Used for lightweight header actions (e.g. "Add entry")

---

## Form Fields

```dart
InputDecoration(
  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: Colors.black12),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: Colors.black12),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: Colors.black, width: 1.5),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: Colors.red, width: 1.5),
  ),
)
```

---

## Dismissible List Items

Swipe-to-delete uses `Colors.red.shade50` background with `Colors.red.shade400` icon. Always show a confirmation dialog before deletion.

Confirm dialog uses plain verbs: **"Remove"** / **"Cancel"** — never "Yes" / "No".

---

## Bottom Sheets

```dart
showModalBottomSheet(
  context: context,
  backgroundColor: Colors.white,
  useSafeArea: true,
  isScrollControlled: true,
  builder: (_) => ...
)
```

Internal structure:
1. Top handle: 36×4 rounded rect, `Colors.black12`, centred with `Dimensions.sixteen` vertical padding.
2. Content padding: `Dimensions.twentyFour` on all sides.

---

## Interactive States

- Use `AnimatedContainer` with `duration: Duration(milliseconds: 120–150)`, `curve: Curves.easeInOut`.
- Pressed fills invert: `Colors.white` bg → `Colors.black` bg + `Colors.white` text.
- Remove `boxShadow` on press (`boxShadow: []`).
- Call `HapticFeedback` on gesture start:
  - `HapticFeedback.heavyImpact()` — high-stakes actions (SOS button)
  - `HapticFeedback.selectionClick()` — standard taps

---

## Language & Copy

- Direct and clinical. No gamified vocabulary: no "streak", "achievement", "score", "points".
- Plain medical language: "days since last seizure", "alert sent", "seizure-free".
- Error messages are short and actionable.
- Confirmation dialogs use plain verbs: "Remove", "Cancel".
- Snackbar messages are one sentence, no punctuation theatrics.

---

## Key Constraints

- No gradients anywhere.
- No illustrations or decorative images.
- No shadows on standard cards (borders only).
- No raw pixel values — always `Dimensions.*`.
- No `fontSize` in widget code — always use `textTheme` styles.
- No new colours without a clear functional justification.
