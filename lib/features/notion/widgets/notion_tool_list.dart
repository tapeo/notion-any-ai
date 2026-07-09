import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_fonts.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/widgets/tool_row.dart';
import '../models/notion_tool_meta.dart';
import '../providers/notion_connection_notifier.dart';
import '../states/notion_connection_state.dart';

class NotionToolList extends ConsumerWidget {
  const NotionToolList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notionConnectionProvider);
    final notifier = ref.read(notionConnectionProvider.notifier);
    final theme = Theme.of(context);

    ref.listen<int?>(businessPlanPromptSelector, (previous, next) {
      if (next != null && next != previous) {
        _showBusinessPlanPrompt(context);
      }
    });

    if (state.toolsLoading) {
      return Row(
        children: [
          const SizedBox(
            width: AppIconSize.sm,
            height: AppIconSize.sm,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.space2),
          Text(
            'Loading Notion tools...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary(theme.brightness),
            ),
          ),
        ],
      );
    }

    if (state.toolsError != null) {
      return Text(
        state.toolsError!,
        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error),
      );
    }

    if (state.tools.isEmpty) {
      return Text(
        'No Notion tools available.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary(theme.brightness),
        ),
      );
    }

    final effectiveWhitelist = state.enabledTools ?? _defaultWhitelist(state);
    final enabledSet = Set<String>.from(effectiveWhitelist);

    final readTools = state.tools
        .where((t) => getToolKind(t.name) == NotionToolKind.read)
        .toList();
    final writeTools = state.tools
        .where((t) => getToolKind(t.name) == NotionToolKind.write)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (readTools.isNotEmpty)
          _ToolSection(
            kind: NotionToolKind.read,
            tools: readTools,
            enabledSet: enabledSet,
            saving: state.saving,
            onToggle: (name, checked) => notifier.toggleTool(name, checked),
            onBulkToggle: (tools, enable) =>
                notifier.bulkToggleTools(tools, enable),
          ),
        if (readTools.isNotEmpty && writeTools.isNotEmpty)
          const SizedBox(height: AppSpacing.space3),
        if (writeTools.isNotEmpty)
          _ToolSection(
            kind: NotionToolKind.write,
            tools: writeTools,
            enabledSet: enabledSet,
            saving: state.saving,
            onToggle: (name, checked) => notifier.toggleTool(name, checked),
            onBulkToggle: (tools, enable) =>
                notifier.bulkToggleTools(tools, enable),
          ),
      ],
    );
  }

  List<String> _defaultWhitelist(covariant NotionConnectionState state) {
    if (state.tools.isEmpty) {
      return const [
        'notion_search',
        'notion_fetch',
        'notion_query',
        'notion_get',
        'notion_list',
        'notion_retrieve',
        'notion_read',
      ];
    }
    return state.tools
        .where(
          (t) =>
              getToolKind(t.name) == NotionToolKind.read &&
              !requiresBusinessPlan(t.name),
        )
        .map((t) => t.name)
        .toList();
  }

  void _showBusinessPlanPrompt(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Business plan required'),
        content: const Text(
          'This Notion tool is only available on the Notion business plan. '
          'Upgrade your Notion workspace to use it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _ToolSection extends StatelessWidget {
  const _ToolSection({
    required this.kind,
    required this.tools,
    required this.enabledSet,
    required this.saving,
    required this.onToggle,
    required this.onBulkToggle,
  });

  final NotionToolKind kind;
  final List<NotionToolMeta> tools;
  final Set<String> enabledSet;
  final bool saving;
  final void Function(String name, bool checked) onToggle;
  final void Function(List<NotionToolMeta> tools, bool enable) onBulkToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = kind == NotionToolKind.read ? 'Read' : 'Write';
    final toggleable = tools
        .where((t) => !requiresBusinessPlan(t.name))
        .toList();
    final enabledCount = toggleable
        .where((t) => enabledSet.contains(t.name))
        .length;
    final allToggleableOn =
        toggleable.isNotEmpty &&
        toggleable.every((t) => enabledSet.contains(t.name));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$label ($enabledCount/${toggleable.length})'.toUpperCase(),
              style: AppFonts.microUpper().copyWith(
                color: AppColors.textTertiary(theme.brightness),
              ),
            ),
            if (enabledCount > 0 && enabledCount < toggleable.length)
              TextButton(
                onPressed: saving ? null : () => onBulkToggle(toggleable, true),
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space1,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Enable all ${label.toLowerCase()}',
                  style: const TextStyle(fontSize: 12),
                ),
              )
            else if (allToggleableOn)
              TextButton(
                onPressed: saving
                    ? null
                    : () => onBulkToggle(toggleable, false),
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space1,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Disable all ${label.toLowerCase()}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.space1),
        ...tools.map(
          (tool) => ToolRow(
            name: formatToolName(tool.name),
            description: tool.description,
            isOn: enabledSet.contains(tool.name),
            saving: saving,
            locked: requiresBusinessPlan(tool.name),
            onToggle: (checked) => onToggle(tool.name, checked),
            badge: requiresBusinessPlan(tool.name)
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space1,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.borderSubtle(theme.brightness),
                      borderRadius: BorderRadius.circular(AppSpacing.space1),
                    ),
                    child: Text(
                      'Business plan',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary(theme.brightness),
                        fontSize: 10,
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
