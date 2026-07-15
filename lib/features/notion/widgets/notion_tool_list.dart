import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_fonts.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/widgets/tool_row.dart';
import '../models/notion_tool_meta.dart';
import '../providers/notion_connection_notifier.dart';
import '../services/notion_tool_registry.dart';
import '../states/notion_connection_state.dart';

class NotionToolList extends ConsumerWidget {
  const NotionToolList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notionConnectionProvider);
    final notifier = ref.read(notionConnectionProvider.notifier);
    final theme = Theme.of(context);

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
    final tools = state.tools.isEmpty
        ? NotionToolRegistry.allTools
        : state.tools;
    return tools
        .where((t) => getToolKind(t.name) == NotionToolKind.read)
        .map((t) => t.name)
        .toList();
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
    final enabledCount = tools.where((t) => enabledSet.contains(t.name)).length;
    final allOn =
        tools.isNotEmpty && tools.every((t) => enabledSet.contains(t.name));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$label ($enabledCount/${tools.length})'.toUpperCase(),
              style: AppFonts.microUpper().copyWith(
                color: AppColors.textTertiary(theme.brightness),
              ),
            ),
            if (enabledCount > 0 && enabledCount < tools.length)
              TextButton(
                onPressed: saving ? null : () => onBulkToggle(tools, true),
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space1,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Enable all ${label.toLowerCase()}',
                  style: AppFonts.labelMedium(),
                ),
              )
            else if (allOn)
              TextButton(
                onPressed: saving ? null : () => onBulkToggle(tools, false),
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space1,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Disable all ${label.toLowerCase()}',
                  style: AppFonts.labelMedium(),
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
            locked: false,
            onToggle: (checked) => onToggle(tool.name, checked),
          ),
        ),
      ],
    );
  }
}
