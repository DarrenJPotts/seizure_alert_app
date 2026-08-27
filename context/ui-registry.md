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
| Height | 70, margin `twentyFour` sides / `twenty` bottom |
| Background | `Colors.white`, `BorderRadius.circular(35)` |
| Shadow | `Colors.black` @ 10%, blur 20, offset `(0, 10)` |
| Selected icon | `Colors.black` (filled variant) + 6px black dot |
| Unselected icon | `Colors.black38` (patient) / `Colors.black` @ 35% (caregiver) |
| Semantics | every item passes `semanticLabel`; items are icon-only and would otherwise be unlabelled buttons |

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
| Sheet container | `Colors.white`, `BorderRadius.vertical(top: Radius.circular(20))`, `BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: Offset(0, -4))` |
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
| Avatar fill (SMS-only contact) | `Colors.black.withValues(alpha: 0.08)` bg, `Colors.black54` initials |
| Overflow avatar (`+N`) | Same muted style as SMS-only avatar, shown when >3 contacts |
| Summary line 1 | `textTheme.bodyMedium` — "N contacts will be notified" |
| Summary line 2 | `textTheme.bodySmall`, `Colors.black45` — "N by push · N by SMS · location included" |
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

**Pattern notes:** Shown only when `contact.status == ContactStatus.pending` (an in-app circle invite is outstanding — see Circle Invite screen below). Same visual language as the Alert History status badge — reuse this exact shape for any future "awaiting something" badge rather than inventing a new one.

---

### Circle Invite Screen (accept/decline)

File: `lib/features/circle_invite/circle_invite_view.dart`

| Property | Value |
|---|---|
| `Scaffold.backgroundColor` | `Colors.white` — light, unlike `IncomingAlertView`'s dark screen, because this isn't an emergency |
| `AppBar` | `Colors.white`, `elevation: 0`, no title (back arrow only) |
| Icon | `Icons.group_add_outlined`, 48px, `Colors.black` |
| Headline | `textTheme.headlineSmall`, `FontWeight.bold` — "`{senderName}` wants to add you to their circle" |
| Body copy | `textTheme.bodyMedium`, `Colors.black54` |
| Primary "Accept" | Full-width `ElevatedButton`, `Colors.black` bg / `Colors.white` fg, radius 12 |
| Secondary "Decline" | Full-width `OutlinedButton`, `Colors.black` fg, `Colors.black26` border, radius 10 |
| Already-responded / error state | Centred icon (`Icons.check_circle_outline` / `Icons.error_outline`, 48px, `Colors.black26`) + `bodyMedium` `Colors.black54` message, no buttons |

**Pattern notes:** Design precedent is `IncomingAlertView`/`IncomingAlertBinding` (notification-triggered full-screen route + `Get.arguments`), but inverted to light/calm since accepting a circle invite isn't urgent. `CircleInviteBinding` reads `inviteId` from **either** `Get.arguments` (background/terminated notification tap) **or** `Get.parameters` (foreground tap, where the local notification payload is a bare route string with a query param) — needed because those are two different delivery paths into the same screen.

---

### Circle Invite Banner (Home)

File: `lib/features/home/widgets/circle_invite_banner.dart`

| Property | Value |
|---|---|
| Container | Standard card (border `Colors.black12`, radius 12, padding `sixteen`) |
| Icon circle | 40×40, `Colors.black.withValues(alpha: 0.06)`, `BoxShape.circle` — `Icons.group_add_outlined`, `Colors.black54` |
| Title | `textTheme.bodyMedium` — "Circle invite" |
| Subtitle | `textTheme.bodySmall`, `Colors.black45` — "`{senderName}` wants to add you to their circle" |
| Chevron | `Icons.chevron_right`, `Colors.black26` |

**Pattern notes:** Shown above the greeting on Home only when `HomeViewModel.pendingInvites` (a live `watchPendingInvites` stream) is non-empty — reuses the exact same row shape as the Alert History card. Placed inside the same `Obx` as `GreetingWidget` (not a separate one) so the Column's `spacing` doesn't leave a stray gap when there's no invite to show.

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
