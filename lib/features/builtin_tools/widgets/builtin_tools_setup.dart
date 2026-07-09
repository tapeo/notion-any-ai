import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_fonts.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/widgets/tool_row.dart';
import '../../settings/widgets/settings_body.dart';
import '../models/builtin_tool_meta.dart';
import '../providers/builtin_tools_notifier.dart';

class BuiltinToolsSetup extends ConsumerWidget {
  const BuiltinToolsSetup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(builtinToolsProvider);
    final notifier = ref.read(builtinToolsProvider.notifier);
    final theme = Theme.of(context);

    final tools = BuiltinToolRegistry.all
        .where((t) => !BuiltinToolRegistry.isMemoryTool(t.id))
        .toList();
    final enabledCount = tools.where((t) => state.isEnabled(t.id)).length;

    return SettingsBody(
      title: 'Built-in tools',
      icon: Icons.bolt_outlined,
      description:
          'Enable or disable local tool functions the assistant '
          'can call during chat, such as getting the current date '
          'and time. These do not require a Notion connection.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tools ($enabledCount/${tools.length})'.toUpperCase(),
                style: AppFonts.microUpper().copyWith(
                  color: AppColors.textTertiary(theme.brightness),
                ),
              ),
              if (enabledCount > 0)
                TextButton(
                  onPressed: state.saving ? null : () => notifier.reset(),
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space1,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Reset to defaults',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.space1),
          ...tools.map(
            (tool) => ToolRow(
              name: _formatToolName(tool.name),
              description: tool.description,
              isOn: state.isEnabled(tool.id),
              saving: state.saving,
              onToggle: (checked) => notifier.toggleTool(tool.id, checked),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatToolName(String name) {
  final base = name.replaceAll('_', ' ');
  return base.replaceAllMapped(RegExp(r'\b\w'), (m) => m[0]!.toUpperCase());
}
