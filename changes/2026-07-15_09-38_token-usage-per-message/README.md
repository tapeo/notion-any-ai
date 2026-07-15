# Per-message token usage

## Summary

Added a token-usage button next to the copy button on each chat message.
Tapping it opens a dialog showing the token counts reported by the API
for that turn. User messages show input tokens; assistant messages show
output and total tokens. No counts are invented: only values reported by
the API are displayed, and the button is hidden when no usage data is
available.

## How it works

1. The OpenAI streaming client now sends
   `stream_options: {include_usage: true}` in the request body.
2. OpenAI-compatible providers return a final SSE chunk with an empty
   `choices` array and a populated `usage` object. The client parses
   `prompt_tokens`, `completion_tokens`, and `total_tokens` and yields
   them on an `OpenAiChatChunk.usage` field.
3. `ChatNotifier` captures the usage chunk during streaming. After the
   stream completes it attaches the `TokenUsage` to the finalized
   assistant message and to the user message that initiated the turn
   (via the new `userMessageId` parameter on `_runCompletionLoop`).
4. `MessageBubble` renders a `TokenButton` next to `CopyButton` when
   `message.usage != null`. The button shows role-specific fields:
   - User: "Input tokens" (`prompt_tokens`)
   - Assistant: "Output tokens" (`completion_tokens`) and
     "Total tokens" (`total_tokens`)

## Edge cases

- Providers that do not support `include_usage` (Anthropic-compatible,
  some Ollama) will not send a usage chunk. The button simply does not
  appear. No breakage.
- The user-message usage is attached only after the assistant responds,
  since that is when the API reports usage.
- `TokenUsage` fields are nullable; the dialog shows "n/a" for any
  missing value rather than fabricating a number.

## Files

### Created

- `lib/features/chat/models/token_usage.dart`: `TokenUsage` model
  (`promptTokens`, `completionTokens`, `totalTokens`) with JSON helpers.
- `lib/features/chat/widgets/token_button.dart`: `TokenButton` widget
  mirroring `CopyButton`, showing a usage dialog on tap.

### Modified

- `lib/features/chat/models/chat_message.dart`: added `usage` field,
  wired into `copyWith`/`toJson`/`fromJson`/`props`.
- `lib/features/chat/services/openai_chat_client.dart`: added
  `stream_options.include_usage`, `usage` on `OpenAiChatChunk`, parsing
  of the final usage chunk.
- `lib/features/chat/providers/chat_provider.dart`: capture usage from
  the stream, attach to assistant and initiating user message, new
  `_attachUsageToMessage` helper, `userMessageId` parameter on
  `_runCompletionLoop`.
- `lib/features/chat/widgets/message_bubble.dart`: render `TokenButton`
  next to `CopyButton` in `_TextBubble` and `_AssistantText` when usage
  is present.

## Verification

Run `fvm flutter analyze` to confirm no new issues.