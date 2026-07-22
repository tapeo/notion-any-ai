# In-app review prompt

Added the native in-app review prompt (StoreKit on iOS, Play In-App Review on Android) triggered on the 3rd app launch, once per install.

## Why

The app had no review prompt. Users who launch the app repeatedly never get nudged to rate it. The native prompt is rate-limited by the OS (Apple ~3 prompts/year, Google ~1 per 120 days), so firing it once after the user has returned to the app twice is a reasonable positive moment.

## What changed

| action | file |
| --- | --- |
| add dep | `pubspec.yaml` `in_app_review: ^2.0.12` |
| create | `lib/features/app_review/services/app_review_service.dart` |
| create | `lib/features/app_review/providers/app_review_provider.dart` |
| edit | `lib/main.dart` (import `app_review_provider`, call `trackLaunch()` + `maybePrompt()` in the `addPostFrameCallback` block of `_MainAppState.initState`) |

## How it works

- `AppReviewService` wraps `InAppReview.instance` and `SharedPreferences`.
- `trackLaunch()` increments `app_review_launch_count` in prefs.
- `maybePrompt()` checks: not already shown, count >= 3, and `isAvailable()` before calling `requestReview()`. On success sets `app_review_shown = true`.
- `MainApp._MainAppState.initState` calls both inside the existing `WidgetsBinding.instance.addPostFrameCallback` block, after the other feature inits.
- All platform exceptions are swallowed (best-effort, review is non-critical). Logging via `debugPrint` (stripped in release) and `dart:developer log` for the catch path.

## Behavior

- 1st launch: count = 1, no prompt.
- 2nd launch: count = 2, no prompt.
- 3rd launch: count = 3, `maybePrompt()` fires `requestReview()` if `isAvailable()` and not already shown.
- 4th+ launches: `app_review_shown` is true, early return, no repeat prompt.
- If `isAvailable()` returns false on the 3rd launch (e.g. simulator, no store), the flag is not set and it tries again on the next launch. Once it succeeds, it stops trying.

## Decisions

- Plain service + `Provider`, not a `Notifier`. The UI doesn't need reactive state, only fire-and-forget calls. Matches `InstallService` and `FeedbackService` style already in the codebase.
- Launch-count trigger (not message-count). Simpler, no `ref.listenManual` wiring, no chat-state imports. Matches the bitpong/pola/memoanki reference patterns.
- `_minLaunches = 3` is a starting value. Tune based on retention data.
- No custom "Enjoying the app?" dialog. System prompt only, keeps it simple and avoids burning the OS quota on users who might say no to a custom dialog.

## Verification

- `fvm flutter analyze`: clean (1 pre-existing info warning in `voice_input_setup.dart`, unrelated).
- Manual test on iOS simulator: `isAvailable()` returns false in simulator, service handles it silently. Real device test pending.