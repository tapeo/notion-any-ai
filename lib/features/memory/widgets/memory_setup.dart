import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_fonts.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/widgets/frosted_icon_button.dart';
import '../../builtin_tools/models/builtin_tool_meta.dart';
import '../../builtin_tools/providers/builtin_tools_notifier.dart';
import '../../conversations/services/reveal_in_file_manager.dart';
import '../../settings/widgets/settings_body.dart';
import '../providers/memory_notifier.dart';
import '../providers/memory_storage_provider.dart';

class MemorySetup extends ConsumerStatefulWidget {
  const MemorySetup({super.key});

  @override
  ConsumerState<MemorySetup> createState() => _MemorySetupState();
}

class _MemorySetupState extends ConsumerState<MemorySetup> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _controller;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(memoryProvider);
    final theme = Theme.of(context);

    if (!_editing) {
      _controller.text = state.content;
    }

    final memoryTools = BuiltinToolRegistry.all
        .where((t) => BuiltinToolRegistry.isMemoryTool(t.id))
        .toList();
    final builtinState = ref.watch(builtinToolsProvider);
    final builtinNotifier = ref.read(builtinToolsProvider.notifier);
    final enabledCount = memoryTools
        .where((t) => builtinState.isEnabled(t.id))
        .length;

    return SettingsBody(
      title: 'Memory',
      icon: Icons.psychology_outlined,
      description:
          'Shared persistent memory the assistant reads and '
          'updates via tools. The full content is injected into '
          'every conversation. Edit it here or let the assistant '
          'add, search, and delete sections on its own.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _controller,
              maxLines: 16,
              minLines: 8,
              style: AppFonts.bodyMedium(),
              decoration: const InputDecoration(
                labelText: 'Memory',
                hintText: 'Shared persistent memory. Sections use ## Title.',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
                isDense: true,
              ),
              autocorrect: false,
              onChanged: (_) => _editing = true,
            ),
            const SizedBox(height: AppSpacing.space3),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: state.saving ? null : _handleSave,
                  icon: state.saving
                      ? const SizedBox(
                          width: AppIconSize.md,
                          height: AppIconSize.md,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined, size: AppIconSize.md),
                  label: const Text('Save'),
                ),
                const SizedBox(width: AppSpacing.space2),
                OutlinedButton.icon(
                  onPressed: state.saving ? null : _handleClear,
                  icon: const Icon(Icons.delete_outline, size: AppIconSize.md),
                  label: const Text('Clear'),
                ),
                if (Platform.isMacOS ||
                    Platform.isLinux ||
                    Platform.isWindows) ...[
                  const SizedBox(width: AppSpacing.space2),
                  TextButton.icon(
                    onPressed: _revealFile,
                    icon: const Icon(
                      Icons.folder_open_outlined,
                      size: AppIconSize.md,
                    ),
                    label: const Text('Reveal file'),
                  ),
                ],
              ],
            ),
            if (state.content.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.space1),
                child: Text(
                  '${state.content.length} characters',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary(theme.brightness),
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.space5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Memory tools ($enabledCount/${memoryTools.length})'
                      .toUpperCase(),
                  style: AppFonts.microUpper().copyWith(
                    color: AppColors.textTertiary(theme.brightness),
                  ),
                ),
                if (enabledCount > 0)
                  TextButton(
                    onPressed: () => _disableAll(memoryTools),
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space1,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Disable all',
                      style: AppFonts.labelMedium(),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.space1),
            ...memoryTools.map(
              (tool) => _MemoryToolRow(
                tool: tool,
                isOn: builtinState.isEnabled(tool.id),
                saving: builtinState.saving,
                onToggle: (id, checked) =>
                    builtinNotifier.toggleTool(id, checked),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    _editing = true;
    await ref.read(memoryProvider.notifier).save(_controller.text);
    _editing = false;
    if (!mounted) return;
    _showSavedDialog(context);
  }

  Future<void> _handleClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear memory?'),
        content: const Text(
          'All memory content will be permanently removed. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    _editing = true;
    await ref.read(memoryProvider.notifier).clear();
    _controller.text = '';
    _editing = false;
  }

  Future<void> _revealFile() async {
    final storage = ref.read(memoryStorageProvider);
    final file = storage.memoryFile;
    if (!file.existsSync()) {
      await storage.ensureDir();
      await storage.save('');
    }
    await revealInFileManager(file);
  }

  Future<void> _disableAll(List<BuiltinToolMeta> tools) async {
    final notifier = ref.read(builtinToolsProvider.notifier);
    for (final tool in tools) {
      if (ref.read(builtinToolsProvider).isEnabled(tool.id)) {
        await notifier.toggleTool(tool.id, false);
      }
    }
  }

  void _showSavedDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text('Memory has been saved.'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _MemoryToolRow extends StatelessWidget {
  const _MemoryToolRow({
    required this.tool,
    required this.isOn,
    required this.saving,
    required this.onToggle,
  });

  final BuiltinToolMeta tool;
  final bool isOn;
  final bool saving;
  final void Function(String id, bool checked) onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    _formatToolName(tool.name),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                FrostedIconButton(
                  onPressed: () => _showDescription(context, tool),
                  icon: Icons.info_outline,
                  diameter: 28,
                  iconSize: AppIconSize.sm,
                ),
              ],
            ),
          ),
          Switch(
            value: isOn,
            onChanged: saving
                ? null
                : (checked) {
                    HapticFeedback.selectionClick();
                    onToggle(tool.id, checked);
                  },
          ),
        ],
      ),
    );
  }

  void _showDescription(BuildContext context, BuiltinToolMeta tool) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(tool.description),
        contentTextStyle: Theme.of(context).textTheme.bodySmall,
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

String _formatToolName(String name) {
  final base = name.replaceAll('_', ' ');
  return base.replaceAllMapped(RegExp(r'\b\w'), (m) => m[0]!.toUpperCase());
}
