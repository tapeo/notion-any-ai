# Add hidden "clear all app data" section in settings

## Summary

Added a hidden danger zone section at the bottom of the settings screen, revealed by tapping the version label 7 times. It clears all app data with a confirmation dialog.

## Files

### New

- `lib/features/settings/widgets/clear_app_data_section.dart`
  - `ClearAppDataSection` (ConsumerStatefulWidget)
  - Displays the app version (via PackageInfo) as a small tertiary-colored footer below the legal links
  - 7 taps on the version label reveal a "Clear all app data" danger zone card with error-colored border and icon
  - Tapping the card shows a confirmation AlertDialog (Cancel / red Clear)
  - On confirm, clears all data, re-initializes providers, shows "Data cleared" dialog, hides the section again

### Modified

- `lib/features/settings/widgets/settings_screen.dart`
  - Added import for `clear_app_data_section.dart`
  - Inserted `ClearAppDataSection()` after `_LegalSectionGroup()`

## What gets cleared

- **SharedPreferences**: ai_provider_endpoint, ai_provider_model, voice_input_model, voice_input_language, system_prompt, builtin_tools_enabled, notifications_reminders, notion_enabled, notion_enabled_tools, notion_recent_pages, install_sent
- **FlutterSecureStorage**: ai_provider_api_key, voice_input_api_key, notion_tokens, installation_id
- **File system**: `<appDir>/conversations/` directory (recursive delete), `<appDir>/memory/memory.md` (cleared to empty)
- **Scheduled notifications**: cancelAll via notifications service

After clearing, all Riverpod notifiers are re-initialized to reflect the empty state.

## Reveal mechanism

- Version label at the bottom of settings looks like a standard footer
- Tapping it 7 times reveals the danger zone card
- Reset on dismiss: after clearing or dismissing, tap counter and revealed state reset