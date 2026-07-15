// Bordered card grouping one or more tool calls with status + details.
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_fonts.dart';
import '../../../app/theme/app_shapes.dart';
import '../../../app/theme/app_spacing.dart';
import '../../builtin_tools/models/builtin_tool_meta.dart';
import '../models/tool_call.dart';

class ToolCallEntry {
  const ToolCallEntry({required this.toolCall, this.resultContent});

  final ToolCall toolCall;
  final String? resultContent;
}

class ToolCallGroup extends StatelessWidget {
  const ToolCallGroup({super.key, required this.entries});

  final List<ToolCallEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final muted = AppColors.textSecondary(brightness);

    final total = entries.length;
    final doneCount = entries.where((e) => e.resultContent != null).length;
    final allDone = doneCount == total;
    final hasError = entries.any(
      (e) =>
          e.resultContent != null && e.resultContent!.startsWith('Tool error:'),
    );
    final hasUnansweredAskUser = entries.any(
      (e) =>
          e.toolCall.name == BuiltinToolRegistry.askUserId &&
          e.resultContent == null,
    );

    final headerIcon = hasUnansweredAskUser
        ? Icons.help_outline
        : (!allDone
              ? Icons.build_outlined
              : (hasError ? Icons.error_outline : Icons.check_circle_outline));
    final headerColor = hasError
        ? AppColors.error
        : (hasUnansweredAskUser
              ? muted
              : (allDone ? AppColors.success : muted));

    final headerLabel = hasUnansweredAskUser
        ? 'Unanswered'
        : (!allDone
              ? 'Running $doneCount/$total'
              : (hasError ? 'Completed with errors' : 'Completed'));

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.8,
      ),
      child: Material(
        color: AppColors.assistantBubble(brightness),
        shape: AppShapes.sm(),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space3 + 1,
                AppSpacing.space2 + 1,
                AppSpacing.space3 + 1,
                AppSpacing.space2 + 1,
              ),
              child: Row(
                children: [
                  Icon(headerIcon, size: AppIconSize.md, color: headerColor),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: Text(
                      'Tool calls',
                      style: AppFonts.labelSmall().copyWith(color: muted),
                    ),
                  ),
                  Text(
                    headerLabel,
                    style: AppFonts.labelSmall().copyWith(color: headerColor),
                  ),
                  if (!allDone && !hasUnansweredAskUser) ...[
                    const SizedBox(width: AppSpacing.space2),
                    SizedBox(
                      width: AppIconSize.md,
                      height: AppIconSize.md,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.textDisabled(brightness),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: AppColors.borderSubtle(brightness),
            ),
            for (var i = 0; i < entries.length; i++) ...[
              _ToolRow(entry: entries[i]),
              if (i < entries.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.borderSubtle(brightness),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ToolRow extends StatelessWidget {
  const _ToolRow({required this.entry});

  final ToolCallEntry entry;

  bool get _isDone => entry.resultContent != null;
  bool get _isError =>
      entry.resultContent != null &&
      entry.resultContent!.startsWith('Tool error:');
  bool get _isUnansweredAskUser =>
      entry.toolCall.name == BuiltinToolRegistry.askUserId &&
      entry.resultContent == null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final muted = AppColors.textSecondary(brightness);

    final icon = _isUnansweredAskUser
        ? Icons.help_outline
        : (!_isDone
              ? Icons.hourglass_top_outlined
              : (_isError ? Icons.error_outline : Icons.check_circle_outline));
    final iconColor = _isError
        ? AppColors.error
        : (_isUnansweredAskUser
              ? muted
              : (_isDone ? AppColors.success : muted));

    final statusLabel = _isUnansweredAskUser
        ? 'unanswered'
        : (!_isDone ? 'running' : (_isError ? 'error' : 'done'));

    return InkWell(
      onTap: () => showToolCallDetails(context, entry),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3 + 1,
          vertical: AppSpacing.space2 + 1,
        ),
        child: Row(
          children: [
            Icon(icon, size: AppIconSize.md, color: iconColor),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: Text(
                entry.toolCall.name,
                style: AppFonts.titleSmall().copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              statusLabel,
              style: AppFonts.labelSmall().copyWith(color: muted),
            ),
            const SizedBox(width: AppSpacing.space2),
            Icon(Icons.chevron_right, size: AppIconSize.md, color: muted),
          ],
        ),
      ),
    );
  }
}

void showToolCallDetails(BuildContext context, ToolCallEntry entry) {
  final toolCall = entry.toolCall;
  final resultContent = entry.resultContent;

  final theme = Theme.of(context);
  final brightness = theme.brightness;
  final muted = AppColors.textSecondary(brightness);
  final isError =
      resultContent != null && resultContent.startsWith('Tool error:');

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.space4,
          0,
          AppSpacing.space4,
          AppSpacing.space6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(toolCall.name, style: AppFonts.headlineSmall()),
            const SizedBox(height: AppSpacing.space3),
            Text(
              'arguments',
              style: AppFonts.labelLarge().copyWith(color: muted),
            ),
            const SizedBox(height: AppSpacing.space1),
            Flexible(
              child: SizedBox(
                width: double.infinity,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: Material(
                    color: AppColors.bgTertiary(brightness),
                    shape: AppShapes.md(),
                    clipBehavior: Clip.antiAlias,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.space3),
                        child: SelectableText(
                          _prettyArguments(toolCall),
                          style: AppFonts.codeSm(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (resultContent != null) ...[
              const SizedBox(height: AppSpacing.space4),
              Text(
                isError ? 'error' : 'result',
                style: AppFonts.labelLarge().copyWith(
                  color: isError ? AppColors.error : muted,
                ),
              ),
              const SizedBox(height: AppSpacing.space1),
              Flexible(
                child: SizedBox(
                  width: double.infinity,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: Material(
                      color: AppColors.bgTertiary(brightness),
                      shape: AppShapes.md(),
                      clipBehavior: Clip.antiAlias,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.space3),
                          child: SelectableText(
                            _prettyResult(resultContent),
                            style: AppFonts.codeSm(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}

String _prettyArguments(ToolCall toolCall) {
  if (toolCall.arguments.isEmpty) {
    return '{}';
  }
  return const JsonEncoder.withIndent('  ').convert(toolCall.arguments);
}

String _prettyResult(String resultContent) {
  final trimmed = resultContent.trim();
  if (trimmed.isEmpty) {
    return resultContent;
  }
  try {
    final decoded = jsonDecode(trimmed);
    return const JsonEncoder.withIndent('  ').convert(decoded);
  } catch (_) {
    return resultContent;
  }
}
