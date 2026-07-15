// Collapsible section showing the assistant's live reasoning stream.
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import 'copy_button.dart';
import 'markdown_text.dart';

class ReasoningSection extends StatefulWidget {
  const ReasoningSection({
    super.key,
    required this.reasoning,
    required this.isStreaming,
  });

  final String reasoning;
  final bool isStreaming;

  @override
  State<ReasoningSection> createState() => _ReasoningSectionState();
}

class _ReasoningSectionState extends State<ReasoningSection> {
  bool _expanded = true;

  @override
  void initState() {
    super.initState();
    _expanded = widget.isStreaming;
  }

  @override
  void didUpdateWidget(covariant ReasoningSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_expanded && oldWidget.isStreaming && !widget.isStreaming) {
      _expanded = false;
    }
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final muted = AppColors.textTertiary(brightness);

    final headerLabel = widget.isStreaming ? 'Thinking...' : 'Thought';

    final headerRow = InkWell(
      onTap: _toggle,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space1,
          vertical: AppSpacing.space1 - 2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _expanded ? Icons.expand_less : Icons.expand_more,
              size: 16,
              color: muted,
            ),
            const SizedBox(width: AppSpacing.space1 - 2),
            Text(
              headerLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: muted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );

    if (!_expanded) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.space1),
        child: headerRow,
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space2),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard(brightness),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.textTertiary(brightness).withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.space1,
              right: AppSpacing.space1,
              top: AppSpacing.space1 - 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: _toggle,
                  borderRadius: BorderRadius.circular(6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.expand_less, size: 16, color: muted),
                      const SizedBox(width: AppSpacing.space1 - 2),
                      Text(
                        headerLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: muted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!widget.isStreaming && widget.reasoning.isNotEmpty)
                  CopyButton(
                    text: widget.reasoning,
                    alignment: Alignment.centerRight,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space2,
              AppSpacing.space1 - 2,
              AppSpacing.space2,
              AppSpacing.space2,
            ),
            child: Opacity(
              opacity: 0.85,
              child: MarkdownText(data: widget.reasoning, isUser: false),
            ),
          ),
        ],
      ),
    );
  }
}
