# Fix chat reset on settings change

## Problem

When a user started chatting, then navigated to Settings and opened Notion setup
(or any other settings screen that mutates a watched provider), returning to the
chat screen showed an empty state. All messages were lost.

## Root cause

`ChatNotifier.build()` used `ref.watch()` on five providers:

- `aiProviderProvider`
- `notionConnectionProvider`
- `systemPromptProvider`
- `memoryProvider`
- `builtinToolsProvider`

Any state change in these providers triggered a rebuild of `build()`, which
returns `const ChatState()` (empty), wiping all messages. The `ref.listen` for
`conversationsProvider.activeId` only reloads when the active conversation ID
changes, so toggling Notion settings (which doesn't change activeId) reset the
chat without restoring it.

## Fix

Removed all `ref.watch()` calls and the `late` cached fields from
`ChatNotifier.build()`. The notifier now reads these providers on demand via
`ref.read()` at the point of use (in `sendMessage`, `_runCompletionLoop`,
`_generateTitle`, `_loadNotionContext`, `_effectiveSystemPrompt`, and
`_systemPromptWithPages`).

This prevents settings changes from triggering a chat reset while still using
the latest provider values when sending a message.

## Files changed

- `lib/features/chat/providers/chat_provider.dart`