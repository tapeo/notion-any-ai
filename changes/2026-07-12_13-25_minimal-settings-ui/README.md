# Minimal settings UI

## Summary

Refactored `lib/features/settings/widgets/settings_screen.dart` to a flat, minimal layout.

## Changes

- Removed card containers (`_SettingsSectionGroup`, `_LegalSectionGroup`): no `surfaceCard` fill, no borders, no inner dividers.
- Removed accent-tinted icon chips. Icons now sit directly next to the label as bare outlined icons.
- Added `_GroupLabel` widget: small uppercase text (`AppFonts.microUpper`, `textTertiary`) above each group.
- Unified `_SettingsSectionTile`, `_FeedbackTile`, and `_LegalTile` into a single `_MinimalTile` with a `trailing` icon parameter (chevron for navigation, `open_in_new` for external links).
- Rows are transparent on the page background with a subtle hover fill (`AppColors.hoverFillFor`) and rounded shape on tap.
- Rows separated by `AppSpacing.space1` gaps instead of dividers.
- Three groups: General, Feedback, Legal.
- `ClearAppDataSection` left unchanged (separate file, reveal-gated).
- Removed the star emoji from the "Open source - leave a Star" legal link label to keep text plain.
- No em dashes introduced.

## Files

- `lib/features/settings/widgets/settings_screen.dart` (rewritten)