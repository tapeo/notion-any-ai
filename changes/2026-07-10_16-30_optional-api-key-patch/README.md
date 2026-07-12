# Optional API key on save

## What

- `ai_provider_storage.dart`, `voice_input_storage.dart`: `saveConfig` now accepts a nullable `apiKey`; only writes to secure storage when a non-empty value is provided.
- `ai_provider_notifier.dart`, `voice_input_notifier.dart`: `save` now accepts a nullable `apiKey`; preserves existing `hasApiKey` flag when none is provided.
- `ai_provider_setup.dart`, `voice_input_setup.dart`: API key validator is conditional (required only when no key is stored). Hint text switches to "Leave empty to keep current" when a key exists. Save handler passes `null` when the field is empty.

## Why

Users had to re-enter the API key every time they wanted to change only the endpoint, model, or language. Now the API key is required only on first setup and optional on subsequent edits.

## How

- Storage layer skips the secure storage write when `apiKey` is null or empty, leaving the existing stored key intact.
- Notifier layer only flips `hasApiKey` to `true` when a new key is provided, otherwise keeps the current value.
- Widget layer passes `null` instead of an empty string when the field is blank, and the validator only rejects empty input when `!hasApiKey`.