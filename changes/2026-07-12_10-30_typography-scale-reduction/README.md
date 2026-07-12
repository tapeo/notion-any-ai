# Typography scale reduction

## Why

Text felt too large compared to ChatGPT / Codex. The Lora serif headings and
loose line heights made the UI feel oversized. Switched to the platform default
sans (SF Pro on Apple, Roboto on Android) and tightened the scale.

## Changes

### `lib/app/theme/app_fonts.dart`

- Removed `google_fonts` import and all `GoogleFonts.lora(...)` calls. Display
  and heading styles now use the platform default sans-serif.
- Tightened line heights on body styles:
  - `bodyLg`: 1.6 -> 1.5
  - `bodyMd`: 1.55 -> 1.45
  - `bodySm`: 1.5 -> 1.45
- Reduced display/heading sizes:
  - `displayHero`: 72 -> 56
  - `displayLg`: 56 -> 44
  - `displayMd`: 48 -> 36
  - `headingLg`: 36 -> 30
  - `headingMd`: 30 -> 26
  - `headingSm`: 24 -> 22
- Adjusted letter spacing proportionally on all display/heading tokens.

### `lib/features/chat/widgets/markdown_text.dart`

- Markdown headings reduced in size and weight:
  - H1: 22 w700 -> 20 w600
  - H2: 18 w700 -> 16 w600
  - H3: 16 w600 -> 15 w600
- H4/H5/H6 unchanged.

### `lib/features/chat/widgets/empty_chat_state.dart`

- Welcome heading switched from `headingMd()` (now 26) to `headingLg()` (30)
  to preserve the 30px welcome size.

## Not changed

- Base body size stays 16 (matches ChatGPT).
- `google_fonts` dependency left in `pubspec.yaml` for now (unused, can be
  removed in a separate cleanup).
- Code font (Menlo) unchanged.
- `label*`, `caption`, `micro*` sizes unchanged.