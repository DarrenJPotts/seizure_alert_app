# UI Tokens

Use these exact values throughout the codebase. Never hardcode colours or raw pixel values in widget code.

---

## Colour Tokens

All colours come from `Colors.*` with opacity variants. There is no custom colour palette file — the design intentionally uses Flutter's built-in black/white system.

| Token | Value | Use |
|---|---|---|
| `Colors.black` | `#000000` | Primary text, inverted surfaces, primary buttons |
| `Colors.black87` | `rgba(0,0,0,0.87)` | High-contrast secondary text |
| `Colors.black54` | `rgba(0,0,0,0.54)` | Secondary text |
| `Colors.black45` | `rgba(0,0,0,0.45)` | Muted / hint text |
| `Colors.black26` | `rgba(0,0,0,0.26)` | Disabled state, secondary button border |
| `Colors.black12` | `rgba(0,0,0,0.12)` | Borders, dividers, bottom sheet handle |
| `Colors.black.withValues(alpha: 0.06)` | — | Subtle fill (hover, tag bg) |
| `Colors.black.withValues(alpha: 0.08)` | — | Slightly stronger fill |
| `Colors.black38` | `rgba(0,0,0,0.38)` | Disabled primary button background |
| `Colors.white` | `#FFFFFF` | Page background, text on inverted surfaces |
| `Colors.greenAccent` | `#69F0AE` | Monitoring dot (live status indicator only) |
| `Colors.red` | — | Error border, error state |
| `Colors.red.shade50` | — | Swipe-to-delete background |
| `Colors.red.shade400` | — | Swipe-to-delete icon |

---

## Spacing Tokens

All spacing comes from `Dimensions` constants defined in `lib/core/constants/dimensions.dart`.

| Constant | Value | Typical use |
|---|---|---|
| `Dimensions.four` | 4 | Tight internal gaps |
| `Dimensions.eight` | 8 | Small gaps between inline elements |
| `Dimensions.twelve` | 12 | Between related items in a list |
| `Dimensions.sixteen` | 16 | Card internal padding, list tile padding |
| `Dimensions.twenty` | 20 | Hero card padding |
| `Dimensions.twentyFour` | 24 | Screen padding (all sides), between sections |
| `Dimensions.twentyEight` | 28 | Large section spacing |
| `Dimensions.thirtyTwo` | 32 | |
| `Dimensions.thirtySix` | 36 | Bottom sheet handle vertical padding |
| `Dimensions.circular` | 99 | Fully circular border radius (chips, pills) |

---

## Border Radius Tokens

| Use | Value |
|---|---|
| Standard card | `BorderRadius.circular(12)` |
| Hero / feature card | `BorderRadius.circular(16)` |
| Primary button | `BorderRadius.circular(12)` |
| Secondary button | `BorderRadius.circular(10)` |
| Form fields | `BorderRadius.circular(12)` |
| Bottom sheet handle | `BorderRadius.circular(99)` |
| Chips / tags | `BorderRadius.circular(Dimensions.circular)` |

---

## Typography Tokens

Font family: **Red Hat Display** (loaded from `assets/fonts/`).

Always use `Theme.of(context).textTheme.*` — never set raw `fontSize` in widget code unless building a one-off display element.

| Token | Use |
|---|---|
| `textTheme.headlineSmall` + `FontWeight.bold` | User greeting name |
| `textTheme.titleMedium` | Page headers, section titles |
| `textTheme.bodyMedium` | Primary body copy, card content |
| `textTheme.bodySmall` | Supporting / secondary copy |
| `textTheme.labelSmall` | Badges, tags, legend labels |

Display-only exceptions (always `FontWeight.w700`, `height: 1`):
- SOS elapsed timer: `fontSize: 48`
- Hero stat number: `fontSize: 36`
- SOS "SOS" label: `fontSize: 28`

---

## Elevation & Shadow

Standard cards use **no shadow** — border (`Colors.black12`) conveys containment.

The SOS button uses a subtle shadow on its resting state, removed on press:
```dart
boxShadow: [
  BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 16, offset: Offset(0, 4)),
]
```

---

## Animation Tokens

| Token | Value |
|---|---|
| Press animation duration | `120–150ms` |
| Press animation curve | `Curves.easeInOut` |
| Press fill | Inverted surface (black ↔ white) |

---

## Monitoring Indicator

The "Monitoring Active" badge in the AppBar:
- Green dot: `Container` 8×8, `BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)`
- Label: `"Monitoring Active"` in `textTheme.labelSmall`, `Colors.black54`
- This is the **only** use of a non-black/white colour in the entire app.
