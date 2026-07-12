# Ask user built-in tool

## Summary

Added `ask_user` as a new built-in tool the LLM can call to ask the user
a question when it needs more information. The question renders as an
inline interactive card in the chat message list. The tool blocks until
the user submits an answer or skips, then the result is fed back to the
LLM as a tool result.

## How it works

1. LLM calls `ask_user` with `question` (required), `options` (optional
   list of choices), and `context` (optional helper text).
2. The executor creates a `PendingQuestion` with a `Completer<String>`
   in `pendingQuestionProvider` and awaits.
3. `_ToolCallBubble` detects the pending `ask_user` call and renders an
   `AskUserCard` inline instead of the normal `ToolCallGroup`.
4. User submits or skips. The provider completes the future.
5. The executor returns the answer (or the sentinel
   "User dismissed the question."). The tool result message is appended
   and the completion loop continues.

## Edge cases handled

- Stop button while pending: dismisses the question with sentinel and
  halts the loop.
- Navigate away while pending: `openConversation` and `clearChat` both
  call `stopStreaming`, which dismisses the pending question.
- Multiple `ask_user` per message: the executor rejects a second call
  if one is already pending, returning a tool error.
- Empty answer submit: allowed, returns empty string to the LLM.
- App killed / reopen: the unanswered `ask_user` call shows as
  "unanswered" in the ToolCallGroup (muted icon, no spinner). No
  automatic resume.
- Settings toggle: `ask_user` appears in Built-in tools settings and
  can be enabled/disabled like other tools.

## Files

### Created

- `lib/features/builtin_tools/models/pending_question.dart`:
  `PendingQuestion` model (id, question, options, context).
- `lib/features/builtin_tools/providers/pending_question_provider.dart`:
  `PendingQuestionNotifier` with `ask`, `submitAnswer`, `dismiss`.
- `lib/features/builtin_tools/widgets/ask_user_card.dart`:
  Interactive card widget with free-text or multiple-choice input.

### Modified

- `lib/features/builtin_tools/models/builtin_tool_meta.dart`: added
  `askUserId`, `_askUser` executor, and `BuiltinToolMeta` entry in the
  registry.
- `lib/features/chat/widgets/message_bubble.dart`: `MessageBubble` and
  `_ToolCallBubble` converted to `ConsumerWidget`. `_ToolCallBubble`
  splits pending `ask_user` calls into `AskUserCard` and other calls
  into `ToolCallGroup`.
- `lib/features/chat/widgets/tool_call_group.dart`: added "unanswered"
  state for `ask_user` calls without result (reloaded conversations).
- `lib/features/chat/providers/chat_provider.dart`: `stopStreaming`
  now calls `pendingQuestionProvider.notifier.dismiss()` first.

## Verification

`fvm flutter analyze` passes with no new issues.