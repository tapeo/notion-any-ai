# Hidden test in-app review

## Changes

- Added `forcePrompt()` method to `AppReviewService` that bypasses the
  launch-count and already-shown guards, returning a `ReviewPromptResult`
  enum (`shown`, `notAvailable`, `error`) so callers can report the outcome.
- Added a "Test in-app review" tile inside the hidden settings area
  (revealed by tapping the version label 7 times) in
  `lib/features/settings/widgets/clear_app_data_section.dart`, placed
  between the environment switcher and the danger zone card.
- Tile calls `appReviewServiceProvider.forcePrompt()` and shows a SnackBar
  with the result. OS rate-limits may still suppress the actual dialog.

## Files

- `lib/features/app_review/services/app_review_service.dart`
- `lib/features/settings/widgets/clear_app_data_section.dart`