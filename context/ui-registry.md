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

### Insights preview — 2026-10-21

Branch `codex/analytics-preview`. Entry: Home → View insights. Page uses the
standard AppBar, 24px screen padding, and safe bottom/side insets. Metric cards
use `context.cardSurface`, `context.designBorder`, `context.designShadows`,
the design card radius, 20px inner padding, and 12px related-item gaps. Sections
are separated by 24px. Theme text styles supply all typography.

30/90-day choices use monochrome ChoiceChips with selected ink/paper inversion.
Frequency and time-of-day charts have 8px bars, numeric counts, and screen-reader
labels. Text wraps with system scaling. Duration and recovery show sample counts
and Not recorded for missing measurements. Copy consistently says recorded
events; it makes no seizure-risk or unlogged seizure-free claims.

Files: `lib/features/analytics/analytics_view.dart`,
`lib/features/analytics/models/analytics_summary.dart`,
`lib/features/analytics/view_models/analytics_view_model.dart`.

### Dark-mode page audit — 2026-10-21

SOS cancellation dialogs inherit the dialog theme, and white fallback call
buttons use `context.heroSurface` foregrounds. Login/signup use `AppWordmark`
with theme-resolved ink rather than the raster-backed SVG's white background.
See `docs/design/dark-mode-audit.md` for scope and verification limits.

### Mode screen background — 2026-10-21

ModeView inherits `ThemeData.scaffoldBackgroundColor` instead of overriding it
with a fixed light grey. Its page surface now matches the active design and
appearance, including the dark Soft editorial surface.

### Shared duration stepper — 2026-10-20

`lib/core/widgets/duration_stepper_field.dart` now owns the compact numeric
minus/value/plus field used by both Heads Up and Add/Edit entry. Heads Up uses
Hours : Minutes; seizure entries use Minutes : Seconds. Entry duration remains
optional: 00:00 saves as unspecified, while positive values save in seconds.
Existing longer entry durations are preserved without truncation. Limits for new
entry adjustments remain 99 minutes / 59 seconds. The shared field retains the
compact phone layout, narrow fallback, accessible labels and 48px tap targets.

### Heads Up custom duration — 2026-10-20

Custom duration uses two bordered numeric controls in an `HH : MM` layout,
with minus/value/plus on one row per field when space allows. Hours run 0–24
and minutes 0–59. At 24 hours minutes reset to zero and both minute buttons disable.
Zero duration disables Send and shows an actionable hint. Selection is stored as
total minutes in the existing view model; presets and note entry are unchanged.
Controls use themed card surfaces and borders, 4px internal padding and label
gaps, accessible button labels and 48px touch targets. Very narrow fields retain
a stacked button fallback. Two-digit values scale down to fit narrow screens
and large text. On a 360px phone each field, including its label, is under 90px tall.

### Direct Heads Up drawer — 2026-10-20

With no active Heads Up, pulling the SOS Heads Up handle upward or tapping it
opens the main `HeadsUpBottomSheet` directly. The intermediate duration-options
panel stays hidden. A single-opening guard prevents duplicate modal routes
during a drag; dismissal resets the underlying handle to its collapsed extent.
When a Heads Up is active, the existing inline check-in controls remain available.
The main drawer continues using shared Android navigation/keyboard safe areas.

Regression: `test/heads_up_improvements_test.dart` covers pull, tap, repeat
opening, reduced motion, and bottom action clearance above a 48px Android bar.

### Contact card surface — 2026-10-20

ContactCard explicitly fills its surface with `context.cardSurface`, matching
the other cards: white on the pale grey Soft editorial page, charcoal in dark
mode. The swipe-to-remove background stays behind the opaque card.

AlertHistoryCard also explicitly uses `context.cardSurface` for the same
white/charcoal treatment, retaining its existing border, shadow and status badge.

### Main style and Android drawers — 2026-10-20

`AppDesign.defaultStyle` is now **Soft editorial** for fresh installs and normal
release builds. Existing development choices are retained by the style switcher.
This supersedes the earlier experimental Bold-default entries below.

All modal drawers, including Appearance and Design style, use
`AppBottomSheetContent` for one handle, scrolling, and shared inset handling.
It reserves `max(viewInsets.bottom, viewPadding.bottom)` outside content, plus
24px normal inner padding. Side safe areas are protected; keyboard and Android
navigation insets are not added twice. The embedded Heads Up panel uses SafeArea
and adds any unconsumed navigation inset to its collapsed extent.

Regression coverage: `test/settings_sheet_insets_test.dart` and
`test/bottom_sheet_insets_test.dart` exercise 0/24/48px navigation bars, keyboard
opening/closing, side insets, and reachability of the bottom action.

### Optional section spacing — 2026-10-20

Hidden widgets remain children of a `Column` even when they return
`SizedBox.shrink()`, so a spaced parent still inserts gaps. Optional sections
must own their adjacent spacing inside the same visibility condition, or be
omitted from the parent's children with a collection `if`.

- Home's setup card owns its `spacingBefore`, applied only while visible. The
  summary owns one normal section gap. Dismissing setup leaves exactly one gap
  between the greeting and summary in every development style.
- Form errors and contact badges/actions are omitted from their parent lists
  when absent, rather than leaving empty children in spaced columns.
- Alert responses and optional caregiver statistics own their top padding and
  remove it while hidden/loading.
- Keep intentional placeholders (such as calendar leading cells) intact.

Regression: `test/conditional_spacing_test.dart` measures section positions
through dismissal, persisted hiding, and reappearance after a readiness failure.

### Soft editorial — 2026-10-20

Seventh development variant, based on the user's monochrome podcast reference.
Storage name: `softEditorial`. Light page: `#F3F3F3`; cards: white; charcoal header
and hero: `#303030`. Dark page: `#161616`; panels: `#252525`.

- Standard cards: 24 radius; feature panels: 32 radius; 20 internal padding.
- Borders: 1px at 4% ink. Shared raised cards add a shadow with blur 24, y-offset
  8, and black at 7% in light / 18% in dark. Pressed action cards remove shadows.
- Headings: Red Hat Display 600. Body sizes and accessible secondary text remain
  unchanged. Summary number: 64, weight 700, height 1; home section gaps: 32.
- DaysFreeCard uses a charcoal title cap and a rounded white/dark content panel.
- Settings, contact/history cards, readiness cards, and caregiver person panels
  use the same raised-surface treatment. Navigation uses 28 radius and the
  existing selected-item inversion.
- No added illustrations or decorative graphics. The switcher remains gated by
  the existing development flag; the production default stays Bold.

Preview: `docs/design/softEditorial-aesthetic-preview.png`.

### Development design styles — 2026-10-19

Files: `lib/core/themes/app_design.dart`, `lib/core/themes/app_theme.dart`,
`lib/core/widgets/design_style_sheet.dart`.

The experiment now has shared style tokens. These override the historical fixed
values below when a development style is active. New themed surfaces should use
`context.design.cardRadius`, `context.design.featureRadius`,
`context.designBorder`, and `context.cardSurface` rather than hard-coded values.
Use `Theme.of(context).textTheme` for headings and body copy.

| Style | Card / feature radius | Outline | Treatment |
|---|---|---|---|
| Clinical | 12 / 16 | 1px, 12% ink | Quiet headings, 56px summary |
| Bold | 12 / 16 | 2px, solid ink | Heavy headings, 96px summary |
| Swiss | 8 / 8 | 1px, 35% ink | Tight heading tracking, 80px summary |
| Soft minimal | 20 / 24 | 1px, 8% ink | Subtle filled cards, 64px summary |
| Editorial | 4 / 4 | 1px, 20% ink | 40px display heading, 88px summary |
| Instrument panel | 8 / 8 | 1px, 35% ink | Compact section gaps, 60px tabular summary |

All variants use Red Hat Display and the existing semantic light/dark palette.
Home section gaps are 24 by default, 32 for Soft/Editorial, and 16 for Instrument.
Typography scales with system settings; long summary values scale down to fit.
Navigation retains 48px minimum targets and its existing destinations.

The picker is a safe-area, scrollable bottom sheet with 24px padding, six labelled
options, a selected checkmark, independent appearance chips, and a Done button.
It opens by holding the version footer in Profile. The choice persists locally.
Debug builds enable it; release test builds require `ENABLE_DESIGN_SWITCHER=true`.
Normal releases ignore development preferences and keep the Bold branch default.

See `docs/design/design-switcher.md` for build and regeneration commands.

### Bold aesthetic experiment — 2026-10-19

Branch: `codex/bold-app-aesthetic`. Builds on the existing uncommitted design and dark-mode work.

- Shared typography: Red Hat Display, weight 700 for display, headline, titleLarge and titleMedium styles. Body sizes remain unchanged. Headline tracking is -0.8 / -0.5 / -0.3.
- Home greeting: `headlineLarge`; wraps with system text scaling.
- DaysFreeCard: existing 16 radius and semantic hero colors, 24 padding, 16 gaps; `displayLarge` number with scale-down for long values, a subtle divider, and full-contrast supporting text.
- StatChip and QuickActionCard: 2-pixel ink outlines, 12 radius, 16 padding. Quick actions use bold labels and the existing 140ms press inversion with easeInOut.
- Patient and caregiver navigation: 2-pixel ink outlines; selected items use an ink surface with paper icons and dots. Touch targets remain at least 48 pixels.
- Light and dark palettes, clinical wording, SOS behavior, and monochrome live status remain in use.

Preview: `docs/design/bold-aesthetic-preview.png` shows real home widgets with illustrative data, rather than a signed-in screen. Regenerate with `flutter test --dart-define=BOLD_PREVIEW=true test/bold_aesthetic_test.dart`.

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
| Monitoring indicator | `LiveIndicator(size: 14, color: Colors.white)` — see the LiveIndicator entry. Was an 8×8 `Colors.greenAccent` circle; **do not reintroduce it.** |

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

### LiveIndicator / LiveStatusLabel

File: `lib/core/widgets/live_indicator.dart`

**Replaces the `Colors.greenAccent` monitoring dot everywhere.** Motion, not colour, now carries "live".
Adopted from option 2f-ii of the design colour study. Do not reintroduce a coloured status dot.

| Property | Value |
|---|---|
| Box | `size` x `size`, default 14 (ring is drawn *outside* these bounds) |
| Ring | 1px border, `color` at 35% x fade, `BoxShape.circle` |
| Ring animation | scale `.5` to `1.6`, opacity `.9` to `0`, `Curves.easeOut`, 1800ms, repeating |
| Dot | `size * 6/14` solid circle in `color` |
| Ink on light surfaces | `Colors.black` |
| Ink on inverted surfaces | `Colors.white` |
| Reduce motion | ring held static at scale 1, 55% opacity — never collapses to a bare dot |
| Semantics | `ExcludeSemantics` on the indicator; `LiveStatusLabel` exposes `"Live. {label}"` |

`LiveStatusLabel({label, color, textStyle, indicatorSize, gap})` is the indicator plus its text, and is
what call sites should normally use — it handles the ellipsis and the screen-reader announcement.

**In use:** `_MonitoringBadge` (root app bar), `StatusCardWidget` (white on black), `SosStatusBoardHeader`
(white on black), caregiver watch-list status lines, incoming-SOS "LIVE ... AGO" header, respond-screen
"ACTIVE mm:ss" pill and the "on their way" responder row.

**Accessibility note:** because the animation *is* the signal, the reduce-motion branch is a correctness
requirement, not a nicety. It is covered by `test/widgets/live_indicator_test.dart` — keep those tests
passing if you touch this widget.

---

### Elevation

Shadows are near-absent by design. Anything above 5% opacity has to justify itself as *functional*
elevation rather than decoration.

| Surface | Value | Why |
|---|---|---|
| Cards, grouped settings, hero cards | none | Hairline borders carry separation |
| Floating nav bar | `Colors.black` @ 4%, blur 16, offset `(0, 6)` | Lifts the bar off the scroll surface |
| SOS idle drawer | `Colors.black` @ 4%, blur 16, offset `(0, -4)` | Same, upward |
| Elevated SOS control (nav) | `Colors.black` @ 12%, blur 16, offset `(0, 4)` | **Functional** — the one control that must read as raised above the bar |
| SOS button (resting) | `Colors.black` @ 8%, blur 16, offset `(0, 4)` | As above; removed entirely on press |
| Map marker pin | `Colors.black` @ 35%, blur 6, offset `(0, 2)` | **Functional** — a pin has to separate from arbitrary map imagery, which is the one surface whose colour this app does not control |

Nav and drawer shadows were `10%`/`8%` at blur 20 before the minimalist-ui pass. The two exceptions
above are deliberate and documented rather than oversights.

---

### Grouped-card settings language  ← **use this for any list-of-rows screen**

Files: `lib/core/widgets/settings/settings_group.dart`,
`lib/core/widgets/settings/settings_screen_header.dart`

Started life on the Mode screen (design turn 5b) and was promoted to `core/widgets` once Profile and
Seizure Log adopted it. **Three screens share these widgets — a change made for one reshapes the other
two.** Covered by `test/widgets/settings_group_test.dart`.

Page skeleton:

```dart
Scaffold(                       // omit for a shell tab; the shell owns the Scaffold
  backgroundColor: const Color(0xFFF1F1F1),
  body: SafeArea(bottom: false, child: Column(children: [
    SettingsScreenHeader(title: 'Mode', backLabel: 'Profile', onBack: Get.back),
    Expanded(child: ListView(
      padding: EdgeInsets.fromLTRB(twenty, twentyTwo, twenty, twentyFour),
      children: [
        SettingsSection(label: 'This device', children: [...]),
        SizedBox(height: Dimensions.twentySix),
        SettingsSection(label: 'Watching', children: [...]),
      ],
    )),
  ])),
)
```

| Component | Spec |
|---|---|
| `SettingsScreenHeader` | Padding `fromLTRB(twenty, eight, twenty, 0)`. Optional back row (20px `arrow_back` + `titleSmall`, both `Colors.black` @ 55%, `Dimensions.ten` below). Title 28px `w700` `letterSpacing: -0.4` `height: 1.1`, with an optional `trailing` action aligned to its bottom |
| `SettingsScreenPlaceholder` | Centred empty/error state: 48px icon `Colors.black26`, `bodyMedium` @ `black54` message, optional `bodySmall` @ `black45` detail, optional action |
| `SettingsGroupHeader` | Uppercased, `labelSmall` 12px `w600` `letterSpacing: 0.6`, `Colors.black` @ 40%, `Dimensions.two` horizontal padding |
| `SettingsGroup` | White, `Border.all(Colors.black @ 10%)`, radius 16, `Clip.antiAlias`, 1px `Divider` @ 10% between children only |
| `SettingsSection` | `SettingsGroupHeader` + `Dimensions.ten` + `SettingsGroup`. Omit `label` for an uncaptioned card |
| `SettingsSwitchRow` | min-height 72, padding `eighteen`/`sixteen`, 22px icon, `bodyLarge w500` title, 13px @ 45% subtitle. Whole row is the tap target |
| `SettingsNavRow` | Height 64, horizontal `eighteen`, 22px icon, optional trailing text @ 45%, 20px chevron @ 30% |
| `SettingsValueRow` | **min**-height 64 (values wrap to 3 lines), label left, value right-aligned @ 45%, chevron only when `onTap` is set |
| `SettingsTileRow` | Height 70 default, horizontal `sixteen`, optional `leading` widget, title + 13px subtitle, optional `trailing`, chevron when tappable. Pass `semanticLabel` or it reads as several nodes |
| `SettingsActionRow` | Height 64, 34px dashed-look circle (1.5px `black` @ 30%) with `Icons.add`, optional black count pill |
| `SettingsDestructiveRow` | Height 64, `Colors.red.shade400` icon and label. **The only colour in this language** — irreversible deletion only |
| `SettingsMessageRow` | Padding `eighteen`/`twenty`, 14px @ 45% — loading and empty states inside a group |
| `SettingsTag` | Pill, `Colors.black` @ 6% fill, `labelSmall` @ 55% — row `trailing` badges ("Alert sent") |

**Row heights are fixed on purpose.** A screen of several groups keeps one rhythm rather than each row
sizing to its content. `SettingsValueRow` is the deliberate exception — it takes a *minimum*, because
the emergency note and medication list genuinely wrap, and that note is what a caregiver reads
mid-emergency.

**Toggle (`_ModeToggle`)** is hand-drawn rather than a Material `Switch`: 52x30 pill, `AnimatedContainer`
150ms `easeInOut`. On — `Colors.black` fill, 24px white knob, right-aligned. Off — white fill, 1.5px
`Colors.black` @ 20% border, 22px `Colors.black` @ 25% knob, left-aligned. Material's switch brings its
own accent colour, ripple, and thumb elevation, none of which this palette has; reskinning it costs more
code than drawing it.

**Retired by this pattern:** `ProfileSection` / `ProfileItem` (a 130px fixed label column that truncated
"Emergency Note" and squeezed its value into the remainder) and `SeizureLogCard` (a bordered container
per entry, which read as a stack of unrelated cards rather than a record). Do not reintroduce either.

**Not migrated:** `CaregiverView` and `RespondingView` keep bespoke headers — they carry extra chrome in
the title row (a "CAREGIVER" pill, a live `ACTIVE mm:ss` pill) that `SettingsScreenHeader` does not
model. Their metrics match it exactly; if a third such screen appears, widen the shared header instead
of copying again.

The caregiver Alerts and Profile tabs use `SettingsScreenHeader` inside the root shell.
A shell tab must not add a nested `Scaffold` or `AppBar`, because that changes its top inset and title
alignment. The standalone patient Alert History route keeps its route AppBar.

Async settings actions use the row's `loading` state. While busy, the trailing value or toggle becomes
a compact monochrome progress indicator and repeat taps are blocked. Invite-code actions follow the
same rule: retain the action, replace its icon with a spinner, and show `Loading…` until the sheet opens.

---

### Seizure Log Row

File: `lib/features/seizure_log/widgets/seizure_log_row.dart`

A `SettingsTileRow` with a 40px `Colors.black` @ 6% circle and a 20px `Icons.bolt` @ `black54` leading,
the formatted date as title, duration/location as subtitle, and a `SettingsTag('Alert sent')` trailing
when `alertFired`.

Entries are grouped into one `SettingsSection` per month, captioned `"This month · 3 entries"` /
`"February · 1 entry"` / `"December 2025 · 4 entries"`. The month caption is the one place in the app
where a section header carries data rather than just labelling: comparing one month to the last is the
question the log exists to answer, and a flat list never showed it. Formatting helpers
(`formatLogDate`, `logSubtitle`, `formatLogDuration`, `formatLogMonth`) are exported from the same file
and covered by `test/features/seizure_log/seizure_log_format_test.dart`.

---

### CaregiverAvatar

File: `lib/features/caregiver/widgets/caregiver_avatar.dart`

Initials avatar for the caregiver screens. `name: null` means "the signed-in user", so the watch-list
header and the "You" responder row do not each need the profile view model.

| Property | Value |
|---|---|
| Shape | Circle, `background` fill (default `Colors.black`) |
| Text | `initialsOf(name)`, `w700`, `foreground` (default `Colors.white`) |
| Font size | `size * 11/34` — scales so one widget covers the 34px header and 44px card avatars |
| Fallback | `?` when no name resolves — never an empty circle |

---

### Caregiver Watch-List Card

File: `lib/features/caregiver/caregiver_view.dart` (`_PersonCard`)

| State | Treatment |
|---|---|
| Live SOS | Inverted — `Colors.black` fill, no border, white ink, white "Open alert" button |
| Heads Up | White card, quote block: `#F1F1F1` fill, 2px black left border, radius `0 10 10 0` |
| Monitoring | White card, up to two `#F1F1F1` radius-10 stat chips (Seizure-free, Last alert) |

Card: padding `Dimensions.eighteen`, radius 16, `Border.all(Colors.black @ 10%)` when not inverted.
Avatar 44px. Call button: 44px circle, 1.5px border in the current ink, dimmed to 25% with no number.
Cards are ordered SOS, then Heads Up, then monitoring — a caregiver must never scroll to find a live SOS.

---

### Splash

File: `lib/features/splash/widgets/splash_body.dart`

Black launch screen, shared by `SplashView` and `RootView`'s not-ready state so the handover does not
flash. Mark: 104px circle, 2.5px white border, `Icons.emergency` at 46px, one outward pulse ring
(scale `.5` to `1.6`, 2400ms) — deliberately *not* `LiveIndicator`, which means "a live state is running
right now" and would be diluted by decorative reuse. Wordmark 30px `w700` `letterSpacing: -0.6`; tagline
`titleSmall` at 50% white; 26px 2px-stroke spinner; `AGILEBRIDGE` at 11px, `letterSpacing: 1.4`, 30% white.

---

### AppBottomSheet (shared widget)

File: `lib/core/widgets/bottom_sheet/app_bottom_sheet.dart`

Reusable bottom sheet chrome, extracted from the near-identical boilerplate that every bottom sheet in the app had (`add_contact_bottom_sheet.dart`, `add_seizure_log_bottom_sheet.dart`, `edit_profile_bottom_sheet.dart`, `change_password_sheet.dart`, `change_email_sheet.dart`, `delete_account_sheet.dart`, `alert_detail_sheet.dart`, `heads_up_bottom_sheet_widget.dart`, `invite_picker_sheet.dart`). All of these now build on it.

| Property | Value |
|---|---|
| `AppBottomSheet.show({context, builder, radius = Dimensions.twentyFour})` | Wraps `showModalBottomSheet` — `backgroundColor: Colors.white`, `useSafeArea: true`, `isScrollControlled: true`, `shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(radius)))` |
| `AppBottomSheetHandle` | The 36×4 `Colors.black12` drag handle, centred, `BorderRadius.circular(2)` |
| `AppBottomSheetContent({child, scrollable = true})` | Keyboard-avoiding `Padding` (`viewInsets.bottom`) → optional `SingleChildScrollView` → `Padding(all: Dimensions.twentyFour)` → `Column` with the handle, `Dimensions.twentyFour` gap, then `child` |
| Section header | `textTheme.titleMedium` |
| Save button | Primary `ElevatedButton`, full-width, `Colors.black` bg |
| Cancel button | Full-width `TextButton`, `Colors.black` foreground, placed directly below Save |

**How to build a new bottom sheet:** call `AppBottomSheet.show(context: ..., builder: (_) => YourSheet())` for the `show()` static, and make `YourSheet.build()` return `AppBottomSheetContent(child: <your content, wrap in a Form if it needs validation>)`. Don't hand-roll the handle, padding, or `showModalBottomSheet` args again.

**Pattern notes:** Standardised the corner radius to `Dimensions.twentyFour` (24) across every sheet — before this pass it varied between 20, 24, and unset/default depending on the file. Also standardised content padding to `Dimensions.twentyFour` on all sides (some sheets previously used asymmetric `fromLTRB` padding); this matches what `ui-rules.md` already specified. `edit_profile_bottom_sheet.dart` previously kept its drag handle outside the `SingleChildScrollView` (via a `Flexible`-wrapped scroll body) specifically so pull-down-to-dismiss worked from the handle; that variant was dropped in favor of the shared handle-inside-scrollable shape every other sheet already used, since 8 of 9 sheets did it that way and dismiss-by-tapping-the-barrier still works. If drag-to-dismiss-by-handle becomes a hard requirement again, re-introduce a `scrollable: false`-style split rather than reverting just that one sheet.

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
| Confirm dialog | `showDialog<bool>` + `AlertDialog` — title "Remove [item]?", cancel "Cancel" (plain `TextButton`), confirm "Remove" (`TextButton`, `Colors.red` foreground) |

**Pattern notes:** Always await the `showDialog<bool>` result before committing the delete (`confirmDismiss` callback pattern — see `contact_card.dart`'s `_confirmDelete`). This is also the base shape reused for any other yes/no confirmation in the app (e.g. sign-out in `root_view.dart`), swapping the destructive red styling for `Colors.black` when the action isn't destructive.

---

### Monitoring Active Badge (AppBar)

`_MonitoringBadge` in `lib/features/root/root_view.dart`, shown as the `AppBar.title` of the **patient**
shell. The caregiver shell has no app bar.

| Property | Value |
|---|---|
| Implementation | `LiveStatusLabel(label: 'Monitoring active', indicatorSize: 14, gap: Dimensions.eight)` |
| Indicator | Monochrome pulsing ring — see the LiveIndicator entry |
| Label | `textTheme.bodySmall`, `Colors.black` @ 70%, `w500` |

Previously an 8×8 `Colors.greenAccent` dot with a `Colors.black54` label. Both are superseded; build new
live-state headers from `LiveStatusLabel` rather than hand-rolling a dot and a `Text`.

---

### Floating Bottom Navigation Bar

File: `lib/features/root/widgets/floating_bottom_nav_widget.dart`

Two variants, selected by the `caregiver` flag, matching the two shells `RootView` builds.

| Property | Value |
|---|---|
| Height | 70, margin `twentyFour` sides; bottom `SafeArea` minimum `twenty` |
| Background | `Colors.white`, `BorderRadius.circular(35)` |
| Shadow | `Colors.black` @ 4%, blur 16, offset `(0, 6)` |
| Selected icon | `Colors.black` (filled variant) + 6px black dot |
| Unselected icon | `Colors.black38` (patient) / `Colors.black` @ 35% (caregiver) |
| Semantics | every item passes `semanticLabel`; items are icon-only and would otherwise be unlabelled buttons |

**System inset:** The shared navigation widget is wrapped in a bottom `SafeArea` with a `Dimensions.twenty` minimum. Android gesture and three-button navigation insets therefore replace the minimum when larger, keeping both patient and caregiver bars fully above system controls.

**Patient variant (default)** — 5 destinations: home, log, *elevated SOS*, circle, profile. The SOS is a
65px black circle in a `Positioned(top: -25)`, `Icons.emergency` at 32px white, labelled "SOS".

**Caregiver variant (`caregiver: true`)** — 4 destinations spread `spaceEvenly`, **no elevated SOS
button**: watch list (`visibility`), alerts (`notifications`), log (`book`), profile (`person`). Adds a
1px `Colors.black` @ 10% border, since without the SOS the bar reads as flatter. A control that fires an
emergency on the caregiver's own behalf has no meaning on a watching device.

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

File: `lib/features/alert_history/widgets/alert_history_card.dart`
Last updated: 2026-10-09

| Property | Value |
|---|---|
| Container | Standard card (border `Colors.black12`, radius 12, padding `sixteen`) |
| Icon circle | 40×40, `Colors.black.withValues(alpha: 0.06)`, `BoxShape.circle` |
| Icon | 20px, `Colors.black54` — `warning_amber_rounded` (SOS), `timer_outlined` (Heads Up), `timer_off_outlined` (Expired) |
| Type label | `textTheme.bodyMedium`; caregiver mode prefixes the type with `ownerName ·` |
| Timestamp | `textTheme.bodySmall`, `Colors.black45` |
| Status badge | `Colors.black.withValues(alpha: 0.06)` bg, `BorderRadius.circular(20)`, `textTheme.labelSmall` `Colors.black54` — "Active" / "Resolved" / "Cancelled" |
| Chevron | `Icons.chevron_right`, `Colors.black26` |

**Pattern notes:** Patient history shows alerts sent by the signed-in patient. Caregiver history uses the same card but includes the watched person's name and loads through the bounded `getCaregiverAlertHistory` callable. Caregiver records open the status-aware incoming alert view; terminal records expose call and back actions without creating a new response.

---

### Alert Detail Bottom Sheet

File: `lib/features/alert_history/alert_history_view.dart` (`_AlertDetailSheet`)

| Property | Value |
|---|---|
| Shell | `AppBottomSheet.show` + `AppBottomSheetContent` (see **AppBottomSheet (shared widget)** above) |
| Icon circle | 44×44, `Colors.black.withValues(alpha: 0.06)`, `BoxShape.circle` |
| Header type | `textTheme.titleMedium` |
| Status badge | Same as alert card badge |
| Detail rows | 80px fixed label column (`textTheme.bodySmall` `Colors.black45`) + expanded value (`textTheme.bodySmall`) |
| Map | `SizedBox(height: 180)` — `AlertMapWidget` if coordinates present, else `AlertMapPlaceholder` |

---

### Full-Bleed Dark Dialog (SOS Countdown)

File: `lib/features/sos/widgets/sos_button_widget.dart` (`CountdownAlertDialog`)

| Property | Value |
|---|---|
| `Dialog` | `insetPadding: EdgeInsets.zero`, `backgroundColor: Colors.black` — covers the full screen |
| Top label | "SENDING SOS", `textTheme.labelSmall`, `Colors.white.withValues(alpha: 0.45)`, `letterSpacing: 3` |
| Countdown number | explicit `fontSize: 160`, `FontWeight.w700`, `height: 1`, `Colors.white`, `FontFeature.tabularFigures()` (legitimate display element) |
| Subtitle | `textTheme.bodyLarge`, `Colors.white.withValues(alpha: 0.7)` |
| Progress bar | `LinearProgressIndicator`, `minHeight: 4`, track `Colors.white.withValues(alpha: 0.18)`, fill `Colors.white` |
| Cancel button (`_DialogButton`) | resting: white border-transparent / black bg... resting = `Colors.white` bg `Colors.black` text; pressed = `Colors.black` bg, `Colors.white24` border, `Colors.white` text — `textTheme.bodyLarge`, `FontWeight.w700` |
| Caption | `textTheme.bodySmall`, `Colors.white.withValues(alpha: 0.4)` |

**Pattern notes:** This is the dark-screen equivalent of the standard dialog — same 5s auto-confirm `Timer.periodic` logic, purely a visual redesign (Turn 2 design "2a"). Any future full-bleed dark modal should reuse this exact structure rather than inventing a new one.

---

### SOS Status Board Header

File: `lib/features/sos/widgets/sos_status_board_header.dart`

| Property | Value |
|---|---|
| Container | `Colors.black`, full width, padding `EdgeInsets.fromLTRB(twentyFour, twentyFour, twentyFour, twenty)` |
| Status indicator | `LiveIndicator(size: 12, color: Colors.white)` (was an 8×8 `Colors.greenAccent` circle) |
| Undelivered state | `SENDING…`, `NOT CONFIRMED` (no server acknowledgment yet), or `NOT SENT` (write rejected) |
| "SOS ACTIVE" label | `textTheme.labelSmall`, `Colors.white`, `FontWeight.w600`, `letterSpacing: 3` |
| "Cancel" text action | `textTheme.bodyMedium`, `Colors.white.withValues(alpha: 0.7)`, `FontWeight.w600` — plain `GestureDetector`, no button chrome |
| Elapsed timer | explicit `fontSize: 40`, `FontWeight.w700`, `height: 1`, `Colors.white`, tabular figures (display element) |
| Segmented seen-indicator | `Row` of `Expanded` 4px-tall bars, `BorderRadius.circular(Dimensions.circular)`, filled = `Colors.white`, unfilled = `Colors.white.withValues(alpha: 0.18)` — one segment per contact |
| Caption | `textTheme.bodySmall`, `Colors.white.withValues(alpha: 0.6)` — "N of M contacts have seen this" |

**Pattern notes:** Reads live `seenCount`/`totalCount` computed by merging `ContactsViewModel.contacts` against `SosViewModel.alertResponses` (merge key: `contact.id == response.contactId`). Design "2c" status board. Sits above a scrollable "YOUR CIRCLE" section of `ContactStatusRow`s, then the existing `AlertMapWidget`/`AlertMapPlaceholder`.

---

### Contact Status Row

File: `lib/features/sos/widgets/contact_status_row.dart`

| Property | Value |
|---|---|
| Avatar | 40×40 circle — active (seen or responding): `Colors.black` bg, white initials; inactive: `Colors.black.withValues(alpha: 0.06)` bg + `Colors.black12` border, `Colors.black54` initials |
| Name | `textTheme.bodyMedium` |
| Status text | "Responding" (`Colors.black87`) / "Seen" / "Not seen yet" (`Colors.black45`), `textTheme.bodySmall` |
| Trailing action | `IconButton(Icons.call_outlined)` → `tel:` via `url_launcher`, same pattern as `invite_service.dart` |

---

### Caregiver Page Header

File: `lib/features/caregiver/caregiver_view.dart` (`CaregiverView`)

In-body header above the list (AppBar itself carries no title, just the back arrow) — same two-line caption/headline pattern as `GreetingWidget` on Home.

| Property | Value |
|---|---|
| Caption line | `textTheme.bodySmall`, `Colors.black45` — "Caregiver mode" |
| Headline | `textTheme.headlineSmall`, `FontWeight.bold` — "People I watch" |
| Line spacing | `Dimensions.four` |
| Padding | `EdgeInsets.fromLTRB(twentyFour, 0, twentyFour, twenty)` |

**Pattern notes:** Design "2e". `AppBar` stays `Colors.white`/`elevation: 0`/no title — the page identity lives in this body header, not the app bar, matching the mockup's in-canvas header block.

---

### Caregiver "People I Watch" Row

File: `lib/features/caregiver/caregiver_view.dart` (`_PersonRow`, `_Avatar`)

| Property | Value |
|---|---|
| Avatar | 44×44 circle, initials `textTheme.bodySmall` `FontWeight.w700` — monitoring: `Colors.black.withValues(alpha: 0.06)` bg / `Colors.black54` text; active: transparent bg, `Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5)`, white text |
| Monitoring state | Standard card (border `Colors.black12`, radius 12, padding `sixteen`) — avatar + name (`bodyMedium`) + "Monitoring" (`bodySmall`, `Colors.black45`) stacked to the right |
| Active state (SOS/Heads Up) | Inverted card, `Colors.black` bg, radius **16**, padding `twenty` — avatar + [status dot/label row, owner name] stacked to the right |
| Active status dot + label | 8×8 dot (`Colors.redAccent` for SOS, `Colors.orangeAccent` for Heads Up) + "SOS ACTIVE"/"HEADS UP", `textTheme.labelSmall`, `Colors.white`, `letterSpacing: 2` |
| Owner name (active state) | `textTheme.bodyMedium`, `Colors.white`, `FontWeight.w600` |
| Action row (SOS, has `activeAlertId`) | Two `Expanded` buttons, `Dimensions.eight` gap: primary "Call" (`ElevatedButton`, white bg/black fg, radius 10, → `tel:`) + secondary "View details" (`OutlinedButton`, white fg, `Colors.white.withValues(alpha: 0.35)` border, radius 10, → `IncomingAlertView`) |
| Action row (Heads Up) | Single full-width `ElevatedButton` — "Check on them" (→ `tel:` the owner's own number). No secondary action: there's no Heads Up detail screen to link to, so a second button isn't added just to mirror the mockup's layout |

**Pattern notes:** List screen backed by `CaregiverViewModel.loadPeopleIWatch()` (one-shot callable via `CaregiverService`/`getPeopleIWatch`, not a live stream — refreshed via `RefreshIndicator`, not `Obx` push updates). Design "2e". The mockup also shows a live Heads Up countdown + progress bar on the active card and a "RECENT" activity feed below the list — both need new fields (`expiresAt`/`createdAt` on the Heads Up status, a days-seizure-free stat, a recent-activity endpoint) that `getPeopleIWatch` doesn't return today, so they were intentionally left out of this pass rather than faked. Revisit if/when that backend data exists. Monitoring rows also skip the mockup's chevron and "N days seizure-free" line for the same reason — there's no per-person detail screen to link a chevron to yet.

---

### Incoming Alert Screen (dark)

File: `lib/features/caregiver/incoming_alert_view.dart`

| Property | Value |
|---|---|
| `Scaffold.backgroundColor` | `Colors.black` |
| "SOS · N MIN AGO" label | `textTheme.labelSmall`, `Colors.redAccent`, `letterSpacing: 2` |
| Headline "{name} needs help" | `textTheme.headlineSmall`, `Colors.white`, `FontWeight.w700` |
| Distance line | `textTheme.bodySmall`, `Colors.white54` — omitted entirely if location unavailable, never faked |
| Medical ID / Emergency note cards | `Colors.white.withValues(alpha: 0.06)` bg, radius 12 — dark-surface equivalent of the standard card |
| Dark map placeholder (`_DarkMapPlaceholder`) | `Colors.white12` border, `Colors.white.withValues(alpha: 0.03)` fill, `Colors.white38` icon/text — dark counterpart of `AlertMapPlaceholder` |
| Primary action "I'm responding" | Full-width `ElevatedButton`, `Colors.white` bg / `Colors.black` fg, radius 12 |
| Secondary action "Call {name}" | Full-width `OutlinedButton`, `Colors.white` fg, `Colors.white24` border, radius 12 |

**Pattern notes:** Design "2d". Backed by `IncomingAlertViewModel` / `CaregiverService.getAlertDetail`. Opening the screen auto-upserts `AlertResponseDto(seen: true)`; "I'm responding" upserts again with `responding: true`. Both use a deterministic doc id (`'${alertId}_${contactId}'`) so repeated opens/taps update the same `alert_responses` doc rather than creating duplicates.

---

### SOS Idle Screen — Height-Conditional Layout

File: `lib/features/sos/sos_view.dart` (`_buildIdleState` + `_buildNormalIdleState` / `_buildCompactIdleState` / `_buildSosHero` / `_buildRosterAndHeadsUp`)

`_buildIdleState` uses `LayoutBuilder` to pick one of two layouts based on available height (`_compactHeightBreakpoint = 700`) — the SOS hero (`_buildSosHero`) and roster/Heads Up content (`_buildRosterAndHeadsUp`) are shared between both so they never drift apart.

**Normal (height ≥ 700):**

| Property | Value |
|---|---|
| Layout | `Column` — SOS hero fixed at top (`Padding`, no scroll), roster/Heads Up below it in `Expanded(child: SingleChildScrollView(...))` |

**Compact (height < 700):**

File: `lib/features/sos/sos_view.dart` (`_CompactIdleSheet` / `_CompactIdleSheetState`)

| Property | Value |
|---|---|
| Layout | `StatefulWidget` — owns a `DraggableScrollableController` (created in `initState`, disposed in `dispose`) so it can react to drag position and clean up properly; internally a `LayoutBuilder` → `Stack` with the SOS hero in `Positioned.fill(bottom: sheetMinHeight, ...)` behind the sheet |
| Sheet sizing | `initialChildSize`/`minChildSize`: `0.10`, `maxChildSize`: `0.85` (`SosView._sheetMinSize`/`_sheetMaxSize`) |
| Sheet container | `Colors.white`, `BorderRadius.vertical(top: Radius.circular(20))`, `BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: Offset(0, -4))` |
| Collapsed state (always visible) | Drag handle (36×4, `Colors.black12`, `BorderRadius.circular(Dimensions.circular)`, centred, `Dimensions.sixteen` bottom margin) + a plain 1px `Colors.black12` divider — nothing else |
| Revealed content | Roster summary + Heads Up card, wrapped in `AnimatedBuilder(animation: controller, ...)` — renders `SizedBox.shrink()` while `controller.size <= sheetMinSize + 0.02`, otherwise the real content, padded `Dimensions.twentyFour` from the divider |

**Pattern notes:** The SOS button must always stay fully visible per explicit product requirement. On a normal-height screen, a fixed header plus one `Expanded(ScrollView)` already guarantees that with the simplest layout. Below the breakpoint, that same fixed-header layout doesn't leave enough room for the roster/Heads Up content, so the compact layout swaps in a `DraggableScrollableSheet` instead — it only ever renders/hit-tests its *current extent* (not the full screen), so the SOS hero behind it stays visible and tappable at every drag position, unlike a modal bottom sheet. The roster/Heads Up content is additionally hidden until dragged up (rather than just relying on the small collapsed size to crop it) so the collapsed state reads cleanly as "handle + divider only," not a partial peek of the content beneath. The handle/divider/reveal-wrapper all live inside the *same* `SingleChildScrollView` that drives the sheet's drag gesture (via the `scrollController` from the builder) — moving them to a separate non-scrollable widget would break drag-by-handle. `_buildActiveState` above still just uses a fixed header + `Expanded(ScrollView)` unconditionally — it has no "must stay visible" element, so it never needed the compact/sheet variant.

---

### SOS Roster Summary

File: `lib/features/sos/widgets/sos_roster_summary.dart`

Shown on the SOS idle screen, above the Heads Up options card, so the user sees who tapping SOS will reach before they tap. Design "3b".

| Property | Value |
|---|---|
| Avatar | 34×34 circle, `Border.all(color: Colors.white, width: 2)`, overlapping at 24px offsets (`Stack` + `Positioned`) |
| Avatar fill (push-notified contact) | `Colors.black` bg, white initials, `textTheme.labelSmall` `FontWeight.w700` |
| Avatar fill (linked push contact) | `Colors.black` bg, white initials |
| Overflow avatar (`+N`) | Same style, shown when >3 linked push contacts |
| Summary line 1 | `textTheme.bodyMedium` — "N contacts set to receive alerts" |
| Summary line 2 | `textTheme.bodySmall`, `Colors.black45` — "Push notifications only" |
| Empty state | `textTheme.bodySmall`, `Colors.black45` — "You have no contacts to notify yet." (no avatars) |
| Section divider (in `sos_view.dart`) | `Border(top: BorderSide(color: Colors.black12))`, `Dimensions.sixteen` top padding — separates this row from the SOS button above it |

**Pattern notes:** Initials computed the same way as `ContactStatusRow` (first letter of first + last word). Only up to 3 avatars render directly; anything beyond that collapses into a `+N` slot rather than growing unbounded.

---

### SOS Heads Up Options Card

File: `lib/features/sos/widgets/sos_heads_up_options_card.dart`

Replaces the old "Send a Heads Up instead" outlined button on the SOS idle screen with an inline duration picker, so choosing a check-in window is a single tap. Design "3b".

| Property | Value |
|---|---|
| Container | Standard card (border `Colors.black12`, radius 12, padding `sixteen`) |
| Header icon | `Icons.warning_amber_outlined`, 20px, `Colors.black54` |
| Header title | `textTheme.bodyMedium` — "Heads Up" |
| Header subtitle | `textTheme.bodySmall`, `Colors.black45` — "Feeling off but not in danger yet" |
| Duration option | `Expanded`, height 48, `Border.all(color: Colors.black26)`, `BorderRadius.circular(8)`, centred `textTheme.bodyMedium` `FontWeight.w500` — "30 min" / "1 hr" / "2 hrs" |
| Row spacing | `Dimensions.eight` between the three options |

**Pattern notes:** Tapping a duration option sets `HeadsUpViewModel.selectedMinutes` then opens `HeadsUpBottomSheet.show()` — it pre-selects the window rather than sending immediately, so the existing note field and "What happens next" confirmation step in the sheet are never skipped. `sos_view.dart` shows `ActiveHeadsUpCard` instead of this card whenever a Heads Up is already active.

---

### Pending Invite Badge (Contact Card)

File: `lib/features/contacts/widgets/contact_card.dart` (`_PendingBadge`)

| Property | Value |
|---|---|
| Container | `Colors.black.withValues(alpha: 0.06)` bg, `BorderRadius.circular(20)`, `EdgeInsets.symmetric(horizontal: eight, vertical: 2)` |
| Text | "Pending", `textTheme.labelSmall`, `Colors.black54` |
| Placement | Inline next to the contact name (`Row` inside the existing name/subtitle `Column`, name wrapped in `Flexible` + ellipsis so long names don't push the badge off-card) |

**Pattern notes:** Shown only for legacy contacts whose status remains `pending`. New code-based invites do not change contact status until accepted. Same visual language as the Alert History status badge — reuse this exact shape for any future "awaiting something" badge rather than inventing a new one.

---

### Circle Invite Code Screen

File: `lib/features/circle_invite/circle_invite_view.dart`

| Property | Value |
|---|---|
| `Scaffold.backgroundColor` | `Colors.white` — light and calm since accepting an invite is not an emergency |
| `AppBar` | `Colors.white`, `elevation: 0`, back arrow |
| Headline | `textTheme.headlineSmall`, bold — "Enter invite code" |
| Code field | Uppercase text input limited to hex digits, spaces, and hyphens |
| Preview | Standard bordered card identifying the sender and contact role before consent |
| Primary action | Full-width black `ElevatedButton`; Continue before preview, Accept after preview |
| Secondary action | Full-width `OutlinedButton` to decline after preview |

**Pattern notes:** Invites are code-based, not routed from FCM or matched to profile phone numbers. The sender shares the code through SMS or WhatsApp; the signed-in recipient opens this screen from My Circle or Mode settings. Codes expire after 24 hours.

### Contact Invite Actions

Files: `lib/features/contacts/widgets/contact_card.dart`, `lib/features/contacts/widgets/invite_picker_sheet.dart`
Last updated: 2026-10-10

| Contact state | Action |
|---|---|
| Never invited | `Invite` |
| Awaiting response | `View code` |
| Expired | `New code` |
| Declined | `Invite again` |
| Connected | No invite action |

**Pattern notes:** Opening an unexpired pending invite returns its existing code and does not invalidate it. The picker labels SMS and WhatsApp under `Share or resend`; regeneration remains a separate confirmed action because it immediately invalidates the previous code. Pending invite state stays visible until accepted, declined, expired, or regenerated.

### Onboarding Contact Invite

File: `lib/features/onboarding/widgets/onboarding_step_emergency_contact.dart`
Last updated: 2026-10-10

| Property | Value |
|---|---|
| Placement | Always visible below the emergency-contact fields |
| Surface | White, `Colors.black12` border, radius `Dimensions.twelve` |
| Title | `bodyMedium` — “Invite them to join your circle” |
| Supporting text | `bodySmall`, `Colors.black54`; explains what is required or what happens after setup |
| Control | Adaptive monochrome switch; disabled until both name and phone are present |
| Default | Enabled automatically once the contact details are complete; the user can opt out |

**Pattern notes:** The invite choice remains visible before data entry so it cannot be missed behind conditional rendering or the keyboard. Account creation and contact saving complete before the callable creates the invite. The resulting code opens in the shared invite picker after navigation, with SMS, WhatsApp, copy, and regenerate actions.

---
### Setup Check Card

File: `lib/features/home/widgets/setup_check_card.dart`
Last updated: 2026-10-09

| Property | Value |
|---|---|
| Background | `Colors.white` |
| Border | `Colors.black12`, 1 px |
| Border radius | `Dimensions.twelve` |
| Padding | `Dimensions.sixteen` |
| Text — primary | `bodyMedium`, `Colors.black`, `FontWeight.w600` |
| Text — secondary | `bodySmall`, `Colors.black54` |
| Spacing | `Dimensions.four`, `Dimensions.eight`, `Dimensions.twelve` |
| Interaction | Whole card runs the displayed action; `HapticFeedback.selectionClick()` |
| Trailing action | `labelSmall`, `FontWeight.w600`, chevron when actionable |
| Shadow | none |
| Accent usage | Monochrome status icon |

**Pattern notes:** The test action requires notification permission, a current FCM device token, and at least one contact whose invite is accepted, push alerts are enabled, and `linkedUid` is present. The card describes those contacts as connected; only a successful drill confirms that a caregiver device is currently reachable. Disabled permission shows `Open settings` or `Enable`; failed token registration shows `Retry`; contact setup opens Contacts. Device and contact checks have bounded loading states. `linkedUid`, `lastTestStatus`, and `lastTestedAtMs` are populated by Cloud Functions and are intentionally not written by the client. A completed test persists a monochrome `Test successful`, `Device offline`, or `Test failed` state on each linked contact. The setup card summarizes those results and tells the patient to ask an offline caregiver to reopen the app before testing again. Sending replaces the icon with a compact progress indicator and blocks repeat taps. Successful means FCM accepted the message; device settings can still prevent the operating system from displaying it.

### Caregiver Alert Drill Confirmation

File: `lib/features/home/widgets/setup_check_card.dart`
Last updated: 2026-10-10

| Property | Value |
|---|---|
| Surface | Standard `AlertDialog` using the global monochrome dialog theme |
| Title | `Send test alert?` |
| Body | States who receives it and confirms that no emergency alert or seizure record is created |
| Actions | `Cancel` and `Send test` using plain clinical verbs |
| Result | Bottom snackbar reports sent-device counts and the remaining OS-delivery limitation |

**Pattern notes:** Any non-emergency drill that contacts another person requires an explicit confirmation immediately before dispatch. The server controls recipients and copy, enforces App Check and authentication, limits attempts to two per ten minutes, caps unique devices at twenty, and gives the notification a five-minute TTL. The client never supplies a recipient ID, notification body, or emergency status.

---

### Offline Banner

File: `lib/core/widgets/offline_banner.dart`

| Property | Value |
|---|---|
| Background | `Colors.black` |
| Text | `bodyMedium` / `bodySmall`, `Colors.white` / `Colors.white70` |
| Padding | Horizontal `Dimensions.twentyFour`, vertical `Dimensions.twelve` |
| Icon | `Icons.cloud_off_outlined`, white, 20 px |
| Shadow | none |
| Accent usage | Monochrome |

**Pattern notes:** Shown above the root shell's selected screen for both patient and caregiver modes. It appears only when the platform reports no active network interface. Connectivity reports interface availability, while Firestore write acknowledgments determine whether an alert reached the server.

---

### Active Heads Up Card

File: `lib/features/sos/widgets/active_heads_up_card.dart`

| Property | Value |
|---|---|
| Background | White |
| Border | `Colors.black12`, radius 12 |
| Padding | `Dimensions.sixteen` |
| Text | `bodyMedium` title; `bodySmall` timer and delivery state |
| Spacing | `Dimensions.four`, `Dimensions.twelve` |
| Shadow | none |

**Pattern notes:** Delivery text distinguishes sending, server-accepted, queued, failed, and unconfirmed-after-restart states. Server acceptance does not guarantee that an individual contact's push notification reached their device.

---

### Change Email Sheet

File: `lib/features/profile/views/widgets/change_email_sheet.dart`

| Property | Value |
|---|---|
| Shell | `AppBottomSheet.show` + `AppBottomSheetContent` (see **AppBottomSheet (shared widget)** above) |
| Title | `textTheme.titleMedium` — "Change Email" |
| Current email caption | `textTheme.bodySmall`, `Colors.black45` — "Currently: {email}" |
| Fields | New email (`TextInputType.emailAddress`) + password, same `Form TextField` styling as Delete Account Sheet's password field |
| Primary action | "Send confirmation link", full-width `ElevatedButton`, same styling as standard save button |
| Success state | Replaces the form in-place (same sheet, no navigation) — headline "Check your inbox" + explanation that the email doesn't change until the link is confirmed, single "Done" button |

**Pattern notes:** Modeled directly on `DeleteAccountSheet`'s password-confirmation shape (inline error text below the password field, obscure-toggle icon). Doesn't close on submit like other save sheets — `verifyBeforeUpdateEmail` is asynchronous from the app's perspective (user confirms via email, not in-app), so the sheet swaps to a confirmation message instead of popping, to avoid implying the change is already done.

---

### Change Password Sheet

File: `lib/features/profile/views/widgets/change_password_sheet.dart`

| Property | Value |
|---|---|
| Shell | `AppBottomSheet.show` + `AppBottomSheetContent` (see **AppBottomSheet (shared widget)** above) |
| Title | `textTheme.titleMedium` — "Change Password" |
| Fields | Current password, new password, confirm new password — three obscured `TextField`s, same styling as Change Email Sheet's password field (shared visibility-toggle icon between the new/confirm pair) |
| Primary action | "Update password", full-width `ElevatedButton`, standard save-button styling |
| Success state | Replaces the form in-place — "Password updated" + single "Done" button (no navigation away, matches Change Email Sheet's success pattern) |

**Pattern notes:** Same shell as `ChangeEmailSheet` (reauth-then-mutate), but since `updatePassword` takes effect immediately rather than requiring a confirmation link, the success copy is a flat statement rather than an instruction to go check something.

---

### Permission Status Card (Profile)

Used in Profile view to show notification and location permission state.

| Property | Value |
|---|---|
| Container | Standard card (border `Colors.black12`, radius 12, padding `sixteen`) |
| Icon | `Colors.black54`, 20px |
| Label | `textTheme.bodyMedium`, `Colors.black` |
| Status text | `textTheme.bodySmall`, `Colors.black54` |
| Action | `TextButton` with "Enable" / "Open Settings" |

---

### Home Screen Widget

Files: `android/app/src/main/res/layout/seizure_alert_widget.xml`, `lib/core/services/home_widget_service.dart`
Last updated: 2026-10-09

| Property | Value |
|---|---|
| Size | Android 2 × 2; iOS small (`systemSmall`) |
| Background | White tile with a 16 dp radius |
| Status | Small uppercase state above the control with a muted last-updated time below |
| Primary action | Concentric 148 dp circular control: faint outer ring, white centre, 3 dp black border, bold black label |
| States | All clear, Heads Up active, SOS active, setup required, signed out |
| Privacy | No name, contact, location, diagnosis, or medication data |
| Refresh | Event-driven when the app starts, resumes, signs in or out, or changes safety/setup state |

**Pattern notes:** Android RemoteViews and the iOS WidgetKit extension mirror the shape and hierarchy of the main SOS button at a compact native-widget scale. Both use the same privacy-safe keys and deep-link actions. The widget never writes to Firebase or sends an alert directly. `SOS` opens the app's existing 10-second confirmation flow. Cold-start launch data is consumed before live widget clicks are subscribed, and the root shell holds a countdown-open latch, so one tap cannot create stacked countdown dialogs. A cold start shows a monochrome `Checking your circle…` loader until the first contact-stream result arrives; recipient readiness is never inferred from the list's initial empty value. Native widgets cannot reliably run the app's pulsing `LiveIndicator`, so active state is stated explicitly in text. The widget has no timer, worker, or scheduled refresh.

### Home Screen Widget Row (Profile)

File: `lib/features/profile/views/profile_view.dart`

| Property | Value |
|---|---|
| Placement | Settings section |
| Icon | `Icons.widgets_outlined` |
| Label | `Home screen widget` |
| Trailing text | `Add`, changing to `Adding…` while the Android launcher request is open |
| Interaction | Existing `SettingsNavRow` pattern with selection haptic |

**Pattern notes:** Android opens the system launcher confirmation. Unsupported launchers receive a short snackbar directing the user to the launcher widget menu. iOS shows `Available` and explains the standard Home Screen long-press and `+` flow because WidgetKit does not provide an app-driven pin request.

---

### Mode Badge

File: `lib/features/root/widgets/mode_badge.dart`
Last updated: 2026-10-09

| Property | Value |
|---|---|
| Background | `colorScheme.surface`; inverted to `inverseSurface` while pressed |
| Border | `colorScheme.outline`, 1 px |
| Border radius | `Dimensions.circular` pill |
| Text | `labelSmall`, semibold, uppercase, 0.6 letter spacing |
| Icon | `person_outline` for patient; `shield_outlined` for caregiver; `Dimensions.fourteen` |
| Spacing | `Dimensions.ten` horizontal, `Dimensions.six` vertical, `Dimensions.six` icon gap |
| Touch target | Minimum 48 logical pixels high |
| Alignment | Visible pill is shrink-wrapped and anchored to the left edge of its touch target |
| Interaction | 140 ms pressed inversion, selection haptic on gesture start, tooltip and semantic mode-switch label |
| Loading | Replaces the icon with a compact monochrome progress indicator and prevents repeat taps |
| Shadow | none |

**Pattern notes:** The badge always names the active device mode. It appears in the patient AppBar and the caregiver watch-list header, and tapping it switches directly to the other mode. Use this shared component anywhere the active patient/caregiver context needs to be both visible and switchable.

---

### Caregiver Alert Readiness Card

File: `lib/features/caregiver/widgets/caregiver_readiness_card.dart`
Last updated: 2026-10-09

| Property | Value |
|---|---|
| Background | `colorScheme.surface`; inverted to `inverseSurface` while pressed |
| Border | `colorScheme.outlineVariant`, 1 px |
| Border radius | `Dimensions.twelve` |
| Padding | `Dimensions.sixteen` |
| Label | `labelSmall`, semibold, uppercase, 0.6 letter spacing |
| Primary text | `bodyMedium`, semibold |
| Supporting text | `bodySmall`, `colorScheme.onSurfaceVariant` |
| Spacing | `Dimensions.four`, `Dimensions.eight`, `Dimensions.twelve`, and `Dimensions.sixteen` |
| Interaction | Whole card runs the displayed repair action; 140 ms pressed inversion and selection haptic |
| Loading | 24 px monochrome progress indicator and disabled interaction |
| Shadow | none |

**Pattern notes:** The card stays visible above every caregiver watch-list state. Readiness requires notification authorization, a current FCM token, and a successfully refreshed non-empty watch list. Failures name the exact repair action. The ready-state action requests a local test notification through the existing maximum-importance alert channel, so the caregiver can check this device without invoking Firebase or a Cloud Function. The test does not claim to verify end-to-end FCM delivery, and silent-mode behavior remains controlled by the OS. The card reads existing reactive state and creates no timer, polling loop, or additional background request.

---

### Help & Diagnostics Screen

File: `lib/features/support/support_view.dart`
Last updated: 2026-10-10

| Property | Value |
|---|---|
| Background | `Colors.white` |
| Groups | Shared `SettingsSection` and `SettingsGroup` containers |
| Border | Shared settings border using low-opacity black |
| Border radius | Shared settings group radius |
| Primary text | Theme settings-row typography in `Colors.black` |
| Secondary text | Shared settings value typography with muted black |
| Spacing | `Dimensions.twenty` screen gutters and token-based section spacing |
| Interactive state | Selection haptic through `SettingsNavRow`; compact monochrome loader while an action is running |
| Shadow | none |
| Accent usage | none |

**Pattern notes:** Operational and support details use the existing Profile settings vocabulary so they remain calm and familiar. Diagnostics contain only app version, platform, and push readiness. Copying, opening support, and opening the privacy policy disable repeat taps and show a row-level loader until the platform action completes.

---

### Safety Readiness Screen

File: `lib/features/safety_readiness/safety_readiness_view.dart`
Last updated: 2026-10-11

| Property | Value |
|---|---|
| Background | `Colors.white` |
| Status card | White standard card when attention is needed; black inverted hero card when core alerts are ready |
| Border | `Colors.black12`, 1 px |
| Border radius | `Dimensions.sixteen` for the overall status; shared settings-row radius elsewhere |
| Text | Theme `titleMedium`, `bodyMedium`, `bodySmall`, and `labelSmall` with monochrome hierarchy |
| Spacing | `Dimensions.twentyFour` screen padding and section gap; `Dimensions.twenty` hero padding |
| Loading | Compact monochrome progress indicators replace refresh, pair, and remove actions |
| Shadow | none |
| Accent usage | none |

**Pattern notes:** Readiness is a checklist, not a guarantee. It keeps all checks in familiar settings rows, states unavailable services plainly, and uses the inverted card only when the minimum alert path is currently ready.

---

### Safety Plan Screen

File: `lib/features/safety_plan/safety_plan_view.dart`
Last updated: 2026-10-11

| Property | Value |
|---|---|
| Background | `Colors.white` |
| Containers | Shared `SettingsSection` and settings-row components |
| Border | Shared low-opacity black settings border |
| Border radius | Shared settings radius; form fields use theme radius 12 |
| Text | Theme styles with direct clinical labels and supporting copy |
| Spacing | `Dimensions.twentyFour` screen padding and section gap; `Dimensions.sixteen` form padding |
| Interactive state | Selection haptic for save; disabled primary button with white loader while saving |
| Shadow | none |
| Accent usage | Red remains limited to form validation supplied by the app theme |

**Pattern notes:** Safety-plan data uses editable form fields inside settings sections. Daily reminders remain on-device. Destructive reminder removal uses an explicit row whose wording names the medication.

---

### Seizure Calendar Summary

File: `lib/features/seizure_log/widgets/seizure_calendar_summary.dart`
Last updated: 2026-10-11

| Property | Value |
|---|---|
| Background | `Colors.white` |
| Border | `Colors.black12`, 1 px |
| Border radius | `Dimensions.twelve` |
| Text | Theme `titleMedium`, `bodyMedium`, `bodySmall`, and `labelSmall` |
| Spacing | `Dimensions.sixteen` internal padding; `Dimensions.twelve` between calendar and summaries |
| Event marker | Black circle with white date; current empty day uses a black outline |
| Shadow | none |
| Accent usage | none |

**Pattern notes:** Event days remain legible without colour and expose a concise semantic event count. The three summary metrics use the same compact label hierarchy as other clinical stats.

### Invite drawer loading
The invite sheet opens before the invite request completes. Only its bordered code section shows centred monochrome progress or an inline retry message. The contact heading, sharing choices and Done action remain visible. Copy and share actions enable after the code is ready.

### Settings value rows — responsive text
Short label/value pairs stay inline. Pairs that do not fit at the active system text size stack with the value below the label. Both texts wrap fully and the row grows vertically; icon and disclosure stay fixed. Loading uses the same layout and disables taps. Verified at 280dp width with 1x, 2x and 3x text sizes.

### Safety plan warning and emergency information patterns — 13 October 2026
Save/reminder warnings remain inline above the editable form; only an initial-load failure uses a blocking placeholder. Caregiver screens show emergency notes, caregiver instructions, rescue medication and call timing as independent content, without using one text field as a fallback for another.

### Existing feature cleanup — 13 October 2026
Navigation rows share the value-row text-fit layout. Mode contains the device role setting; caregiver lists remain on the caregiver home screen, and notification controls stay in Profile/readiness. Removed the inert auto-answer control and misleading silent-override shortcut. Medical-ID medication copy distinguishes the medication list from local reminders. Home data errors show Retry and no empty statistics. Emergency timing explicitly states that it is manual caregiver guidance.

### Floating bottom navigation and SOS — 13 October 2026
The owner reverted the overhaul trial and prefers the existing Apple-style floating white pill, raised black SOS button and existing screen hierarchy. Keep those as the baseline. Navigation uses Dimensions.eight horizontal and Dimensions.twelve vertical item padding to fit narrow screens. SOS keeps its circular appearance and default diameter, adapts to available width, and scales its display label to fit. Heads Up remains in the draggable sheet with a flexible heading. Do not restore the rejected labelled navigation or inline Heads Up redesign.


### Charcoal dark appearance — 13 October 2026
The owner explicitly requested dark mode using a charcoal reference. Preserve the existing floating Apple-style navigation and screen hierarchy. Dark page background is #181818; raised cards/navigation use #2D2D2D, with white primary text and monochrome opacity hierarchy. Hero surfaces stay charcoal with white text in dark mode and black with white text in light mode. Custom widget roles come from the inherited theme through AppPalette (ink, paper, heroSurface, heroInk); shadows remain black. Existing Red Hat Display typography, Dimensions spacing, shapes and SOS interaction stay intact. Profile > Appearance offers System, Light and Dark and saves locally through the existing ThemeController. System bars follow appearance. Sheets and forms adapt; fixed splash and incoming emergency surfaces retain their deliberate black/white pairing. The Heads Up drawer now restores its earlier 10% collapsed extent at the owner's request; only its collapsed heading scales down to fit, while expanded content uses normal accessibility text scaling.


### Accessibility refinements following Apple-design review — 13 October 2026
Secondary text uses AppPalette.secondaryInk: #595959 in light appearance and #B0B0B0 in dark appearance, with primary ink when the system requests high contrast. These replace low-opacity muted text across custom screens. The smallest shared label style is 12. Floating navigation remains icon-only; its selected dots use ink, ordinary targets have minimum 48x48 hit bounds, and patient navigation uses Dimensions.sixteen side margins below 296dp to accommodate these targets (otherwise Dimensions.twentyFour). The raised SOS keeps its existing appearance. Heads Up retains the 10% collapsed extent and dragging, with a labelled tap/semantic action to expand or collapse; reduced motion changes the extent immediately. No layout overhaul or font-family change.


### Responsive forms and list content — 14 October 2026
Seizure Severity/Awareness choices use full-width expanding dropdowns with intrinsic item heights; a measured text-width check stacks them when two fields cannot fit. Selected labels wrap at the active text size. Shared SettingsTileRow uses a minimum height and Dimensions.twelve vertical padding, with wrapping title/subtitle content. Contact names wrap; status badge sits below the name; notification/invite actions wrap beneath supporting text; avatar stays aligned to the top. Activity legend wraps complete dot/label groups. Calendar heading/count wrap as independent labels, and alert status metadata sits below title/date. Heads Up duration controls use minimum 48 height plus Dimensions.sixteen horizontal/Dimensions.twelve vertical padding, and wrap into rows; they grow with text. Existing monochrome theme, fonts, floating navigation and compact drawer remain.


### Drawer insets, setup swipe and contact icons — 19 October 2026
Shared AppBottomSheetContent reserves keyboard viewInsets, then uses a bottom-only SafeArea around its contents so Android gesture/three-button navigation cannot overlap actions. Standard Dimensions.twentyFour content spacing remains in addition to the system inset. Completed setup checks dismiss with a horizontal swipe using a subtle monochrome hide background; no visible X. The existing hide preference persists; incomplete/readiness-error states stay visible. Contact cards keep the notification indicator at the trailing edge alongside the top contact information, rather than in a separate row below the details. Invite actions retain their wrapping body placement for narrow layouts and large text.

Home greeting action (2026-10-22): View insights sits at the right of the greeting in a Row with Expanded greeting and Dimensions.twelve gap. Narrow widths or enlarged text use an Insights icon button with a View insights tooltip. No action or trailing spacing remains below the activity grid.
## Reminders — 2026-10-22

Profile has a dedicated Reminders row; Safety plan links to the same screen. Theme-aware reminder cards use `context.cardSurface`, `designBorder`, `designShadows`, `cardRadius`, and Dimensions spacing. Reminders/History choices wrap on narrow screens. Each card shows its schedule, next occurrence, and explicit actions for a due occurrence; actions wrap rather than squeezing text. History uses clinical language and does not infer missed doses.

Add/Edit and Snooze use `AppBottomSheet` plus `AppBottomSheetContent` for keyboard and Android navigation-bar insets. The editor scrolls, weekday chips wrap, and type/repeat/date/time controls use the existing monochrome theme. Saving acts immediately with a disabled saving state; removing requires confirmation. Source: `lib/features/reminders/`.
