# Typography rebased on Flutter Material 3 defaults

## Why

The previous scale (see `2026-07-12_10-30_typography-scale-reduction`) kept body
text at 16 to match ChatGPT. That made `AppFonts` diverge from Flutter's own
`TextTheme` defaults, so widgets using `Theme.of(context).textTheme` rendered
smaller than widgets using `AppFonts.*()` directly. Rebased the whole scale on
the Material 3 defaults so the two systems agree.

## Changes

### `lib/app/theme/app_fonts.dart`

Rewrote the token set. Methods renamed to match `TextTheme` slot names, sizes
snapped to M3 defaults.

| new method           | old method      | size | weight | height | letter spacing |
| -------------------- | --------------- | ---- | ------ | ------ | -------------- |
| `displayLarge()`     | `displayHero()` | 57   | w600   | 1.1    | -1.4           |
| `displayMedium()`    | `displayLg()`   | 45   | w600   | 1.15   | -1.0           |
| `displaySmall()`     | `displayMd()`   | 36   | w600   | 1.2    | -0.72          |
| `headlineLarge()`    | `headingLg()`   | 32   | w600   | 1.3    | -0.5           |
| `headlineMedium()`   | `headingMd()`   | 28   | w600   | 1.3    | -0.32          |
| `headlineSmall()`    | `headingSm()`   | 24   | w600   | 1.35   | -0.16          |
| `titleLarge()`       | `labelLg()`     | 22   | w500   | 1.5    | -              |
| `titleMedium()`      | (labelLg)       | 16   | w500   | 1.4    | -              |
| `titleSmall()`       | `labelSm()`     | 14   | w500   | 1.4    | -              |
| `bodyLarge()`        | `bodyLg()`      | 16   | w400   | 1.5    | -              |
| `bodyMedium()`       | `bodyMd()`      | 14   | w400   | 1.45   | -              |
| `bodySmall()`        | `bodySm()`      | 12   | w400   | 1.45   | -              |
| `labelLarge()`       | (labelMd)       | 14   | w500   | 1.4    | -              |
| `labelMedium()`      | -               | 12   | w500   | 1.4    | -              |
| `labelSmall()`       | `micro()`       | 11   | w500   | 1.3    | 0.2            |

Kept as custom extras (not in M3 TextTheme):

| method           | size | weight | height | notes           |
| ---------------- | ---- | ------ | ------ | --------------- |
| `caption()`      | 12   | w400   | 1.4    | snackbar/tooltip |
| `codeMd()`       | 13   | w400   | 1.6    | Menlo           |
| `codeSm()`       | 11   | w400   | 1.5    | Menlo           |
| `microUpper()`   | 11   | w500   | 1.3    | letter 0.8      |

Old `labelLg()` (16/w500) split into `titleLarge()` (22/w500) for the
`titleLarge` TextTheme slot and `titleMedium()` (16/w500) for call sites that
used `labelLg()` as a medium emphasis label. Old `labelMd()` (14/w500) became
`labelLarge()` (14/w500) for button text and similar action labels.

### `lib/main.dart`

- `TextTheme` mapping simplified: each slot uses the `AppFonts` method of the
  same name.
- Button `textStyle` switched from `labelMedium()` to `labelLarge()` (14/w500)
  to match M3 button spec.
- `bodyMedium` color changed from `secondary` to `ink` (M3 default body is
  on-surface).
- Other theme references (`appBarTheme.titleTextStyle`,
  `inputDecorationTheme.*Style`, `snackBarTheme.contentTextStyle`,
  `dialogTheme.*TextStyle`, `tooltipTheme.textStyle`) updated to new method
  names.

### Call sites

Renamed across 13 files under `lib/features/**` and `lib/app/widgets/**`:

- `AppFonts.bodyMd()` -> `AppFonts.bodyMedium()`
- `AppFonts.bodySm()` -> `AppFonts.bodySmall()`
- `AppFonts.bodyLg()` -> `AppFonts.bodyLarge()`
- `AppFonts.labelMd()` -> `AppFonts.labelLarge()`
- `AppFonts.labelLg()` -> `AppFonts.titleMedium()` (call sites) /
  `AppFonts.titleLarge()` (TextTheme slot)
- `AppFonts.labelSm()` -> `AppFonts.titleSmall()`
- `AppFonts.micro()` -> `AppFonts.labelSmall()`
- `AppFonts.headingLg/Md/Sm()` -> `AppFonts.headlineLarge/Medium/Small()`
- `AppFonts.displayHero/Lg/Md()` -> `AppFonts.displayLarge/Medium/Small()`

### Inline `TextStyle(fontSize:)` converted to tokens

- `memory_setup.dart`: text input `fontSize: 14` -> `AppFonts.bodyMedium()`;
  "Disable all" button `fontSize: 12` -> `AppFonts.labelMedium()`.
- `system_prompt_setup.dart`: text input `fontSize: 14` ->
  `AppFonts.bodyMedium()` (added `app_fonts` import).
- `notion_tool_list.dart`: "Enable all"/"Disable all" `fontSize: 12` ->
  `AppFonts.labelMedium()`.
- `notifications_setup.dart`: "Clear all" `fontSize: 12` ->
  `AppFonts.labelMedium()`.
- `builtin_tools_setup.dart`: "Reset to defaults" `fontSize: 12` ->
  `AppFonts.labelMedium()`.

Left as inline: emoji icon sizes in `chat_page_chip.dart` (16) and
`notion_page_picker_sheet.dart` (18), those are icon glyphs not text.

## Not changed

- `markdown_text.dart` has no hardcoded heading sizes (uses `MarkdownBody`
  defaults), nothing to update.
- `google_fonts` dependency still in `pubspec.yaml` (unused, separate cleanup).
- `AppColors`, `AppSpacing`, `AppShapes` untouched.
- Pre-existing deprecation warning in `voice_input_setup.dart:176` unrelated.

## Verification

- `fvm flutter analyze`: 0 errors (1 pre-existing info-level deprecation).