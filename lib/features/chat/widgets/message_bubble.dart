// Bubble for a single chat message, aligned and styled per role.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_shapes.dart';
import '../../../app/theme/app_spacing.dart';
import '../../builtin_tools/models/builtin_tool_meta.dart';
import '../../builtin_tools/providers/pending_question_provider.dart';
import '../../builtin_tools/widgets/ask_user_card.dart';
import '../models/chat_error.dart';
import '../models/chat_message.dart';
import '../models/chat_role.dart';
import '../models/tool_call.dart';
import '../providers/chat_provider.dart';
import 'copy_button.dart';
import 'markdown_text.dart';
import 'reasoning_section.dart';
import 'token_button.dart';
import 'tool_call_group.dart';

class MessageBubble extends ConsumerWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.allMessages,
    this.playEntrance = false,
  });

  final ChatMessage message;
  final List<ChatMessage> allMessages;
  final bool playEntrance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (message.role == ChatRole.tool) {
      return _ToolResultBubble(message: message, allMessages: allMessages);
    }
    if (message.role == ChatRole.assistant &&
        message.toolCalls != null &&
        message.toolCalls!.isNotEmpty) {
      return _ToolCallBubble(message: message, allMessages: allMessages);
    }
    return _TextBubble(message: message, playEntrance: playEntrance);
  }
}

class _TextBubble extends StatelessWidget {
  const _TextBubble({required this.message, this.playEntrance = false});

  final ChatMessage message;
  final bool playEntrance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.role == ChatRole.user;
    final alignment = isUser ? MainAxisAlignment.end : MainAxisAlignment.start;
    final hasContent = message.content != null && message.content!.isNotEmpty;
    final hasReasoning =
        message.reasoning != null && message.reasoning!.isNotEmpty;
    final isStreaming = hasReasoning && !hasContent;

    final reasoningWidget = hasReasoning
        ? ReasoningSection(
            reasoning: message.reasoning!,
            isStreaming: isStreaming,
          )
        : null;

    final contentWidget = isUser
        ? SelectableText(
            message.content ?? '',
            style: TextStyle(color: AppColors.userBubbleText(theme.brightness)),
          )
        : !hasContent && !hasReasoning
        ? Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const _TypingIndicator(),
              const SizedBox(width: AppSpacing.space2),
              Text(
                'Thinking…',
                style: TextStyle(
                  color: AppColors.textTertiary(theme.brightness),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          )
        : hasContent
        ? MarkdownText(data: message.content!, isUser: false)
        : const SizedBox.shrink();

    final messageWidget = isUser
        ? ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            child: Material(
              color: AppColors.userBubble(theme.brightness),
              shape: AppShapes.sm(),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.space3 + 1,
                  AppSpacing.space2 + 1,
                  AppSpacing.space3 + 1,
                  AppSpacing.space2 + 1,
                ),
                child: contentWidget,
              ),
            ),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space1,
              vertical: AppSpacing.space1,
            ),
            child: contentWidget,
          );

    final child = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space2 - 2,
      ),
      child: Row(
        mainAxisAlignment: alignment,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                ?reasoningWidget,
                messageWidget,
                if (hasContent) ...[
                  const SizedBox(height: AppSpacing.space1 - 2),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.space1,
                      right: AppSpacing.space1,
                      top: AppSpacing.space1,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CopyButton(
                          text: message.content!,
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                        ),
                        if (message.usage != null && !isUser) ...[
                          const SizedBox(width: AppSpacing.space1),
                          TokenButton(
                            usage: message.usage!,
                            alignment: Alignment.centerLeft,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (isUser) {
      return _EntranceAnimator(playEntrance: playEntrance, child: child);
    }
    return child;
  }
}

class _EntranceAnimator extends StatefulWidget {
  const _EntranceAnimator({required this.playEntrance, required this.child});

  final bool playEntrance;
  final Widget child;

  @override
  State<_EntranceAnimator> createState() => _EntranceAnimatorState();
}

class _EntranceAnimatorState extends State<_EntranceAnimator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(
      begin: 0.96,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    if (widget.playEntrance) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.scale(
            scale: _scale.value,
            alignment: Alignment.bottomRight,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

// Red-tinted error bubble shown when an assistant response fails.
class ErrorBubble extends ConsumerWidget {
  const ErrorBubble({super.key, required this.error});

  final ChatError error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isSending = ref.watch(chatProvider.select((s) => s.isSending));
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space1 - 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              decoration: ShapeDecoration(
                color: brightness == Brightness.dark
                    ? const Color(0x33E03E3E)
                    : const Color(0x1FE03E3E),
                shape: AppShapes.sm(
                  side: BorderSide(
                    color: AppColors.error.withValues(alpha: 0.4),
                  ),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space3,
                AppSpacing.space2,
                AppSpacing.space3,
                AppSpacing.space2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 18,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          error.text,
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space1),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton.icon(
                              onPressed: isSending
                                  ? null
                                  : () => ref
                                      .read(chatProvider.notifier)
                                      .retryLastFailed(),
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('Retry'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.error,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.space2,
                                  vertical: 0,
                                ),
                                minimumSize: const Size(0, 32),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.space1),
                            TextButton.icon(
                              onPressed: error.detail == null
                                  ? null
                                  : () => _showErrorDetails(context, error),
                              icon: const Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                              ),
                              label: const Text('Details'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.error,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.space2,
                                  vertical: 0,
                                ),
                                minimumSize: const Size(0, 32),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _showErrorDetails(BuildContext context, ChatError error) {
  showDialog<void>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      return AlertDialog(
        title: const Text('Error details'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  error.text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: AppSpacing.space3),
                Text(
                  'Details',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary(theme.brightness),
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                SelectableText(
                  error.detail ?? 'No additional details available.',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: AppColors.textSecondary(theme.brightness),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

// Animated three-dot typing indicator shown while the assistant placeholder is empty.
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final dotColor = AppColors.textTertiary(brightness);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.space1 + 1),
          _Dot(index: i, controller: _controller, color: dotColor),
        ],
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.index,
    required this.controller,
    required this.color,
  });

  final int index;
  final AnimationController controller;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final start = index * 0.2;
    final tween = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(start, start + 0.6, curve: Curves.easeInOut),
      ),
    );
    return AnimatedBuilder(
      animation: tween,
      builder: (context, child) {
        final scale = 0.6 + tween.value * 0.4;
        final opacity = 0.3 + tween.value * 0.7;
        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
        );
      },
    );
  }
}

class _ToolCallBubble extends ConsumerWidget {
  const _ToolCallBubble({required this.message, required this.allMessages});

  final ChatMessage message;
  final List<ChatMessage> allMessages;

  String? _resultFor(String toolCallId) {
    for (final msg in allMessages) {
      if (msg.role == ChatRole.tool && msg.toolCallId == toolCallId) {
        return msg.content;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingQuestion = ref.watch(
      pendingQuestionProvider.select((s) => s.pending),
    );
    final notifier = ref.read(pendingQuestionProvider.notifier);

    final askUserEntries = <Widget>[];
    final otherEntries = <ToolCallEntry>[];

    for (final call in message.toolCalls!) {
      final result = _resultFor(call.id);
      if (call.name == BuiltinToolRegistry.askUserId &&
          result == null &&
          pendingQuestion != null) {
        askUserEntries.add(
          AskUserCard(
            question: pendingQuestion,
            onSubmit: notifier.submitAnswer,
            onDismiss: notifier.dismiss,
          ),
        );
      } else {
        otherEntries.add(ToolCallEntry(toolCall: call, resultContent: result));
      }
    }

    final children = <Widget>[];

    final hasReasoning =
        message.reasoning != null && message.reasoning!.isNotEmpty;
    final hasContent =
        message.content != null && message.content!.trim().isNotEmpty;
    if (hasReasoning) {
      children.add(
        ReasoningSection(reasoning: message.reasoning!, isStreaming: false),
      );
    }

    if (hasContent) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.space1),
          child: _AssistantText(message: message),
        ),
      );
    }

    if (otherEntries.isNotEmpty) {
      children.add(ToolCallGroup(entries: otherEntries));
    }

    children.addAll(askUserEntries);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space1 - 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantText extends StatelessWidget {
  const _AssistantText({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space1,
            vertical: AppSpacing.space1,
          ),
          child: MarkdownText(data: message.content ?? '', isUser: false),
        ),
        const SizedBox(height: AppSpacing.space1 - 2),
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.space1,
            top: AppSpacing.space1,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CopyButton(
                text: message.content ?? '',
                alignment: Alignment.centerLeft,
              ),
              if (message.usage != null) ...[
                const SizedBox(width: AppSpacing.space1),
                TokenButton(
                  usage: message.usage!,
                  alignment: Alignment.centerLeft,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ToolResultBubble extends StatelessWidget {
  const _ToolResultBubble({required this.message, required this.allMessages});

  final ChatMessage message;
  final List<ChatMessage> allMessages;

  bool get _hasMatchingCall {
    final id = message.toolCallId;
    if (id == null) {
      return false;
    }
    for (final msg in allMessages) {
      if (msg.role != ChatRole.assistant || msg.toolCalls == null) {
        continue;
      }
      for (final call in msg.toolCalls!) {
        if (call.id == id) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_hasMatchingCall) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space1 - 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: ToolCallGroup(
              entries: [
                ToolCallEntry(
                  toolCall: ToolCall(
                    id: message.toolCallId ?? message.id,
                    name: message.name ?? 'tool',
                    arguments: const {},
                  ),
                  resultContent: message.content,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
