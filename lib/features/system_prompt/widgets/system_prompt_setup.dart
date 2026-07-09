import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../settings/widgets/settings_body.dart';
import '../providers/system_prompt_notifier.dart';
import '../states/system_prompt_state.dart';

class SystemPromptSetup extends ConsumerStatefulWidget {
  const SystemPromptSetup({super.key});

  @override
  ConsumerState<SystemPromptSetup> createState() => _SystemPromptSetupState();
}

class _SystemPromptSetupState extends ConsumerState<SystemPromptSetup> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _controller;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: SystemPromptState.defaultPrompt);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(systemPromptProvider);

    if (!_editing) {
      _controller.text = state.prompt.isEmpty
          ? SystemPromptState.defaultPrompt
          : state.prompt;
    }

    return SettingsBody(
      title: 'System prompt',
      icon: Icons.edit_note_outlined,
      description:
          'Customize the instructions sent at the start of every '
          'conversation to control how the assistant behaves.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _controller,
              maxLines: 6,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'System prompt',
                hintText:
                    'Instructions sent at the start of every conversation.',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
                isDense: true,
              ),
              autocorrect: false,
              validator: _validatePrompt,
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
                  onPressed: state.saving ? null : _handleReset,
                  icon: const Icon(
                    Icons.restart_alt_outlined,
                    size: AppIconSize.md,
                  ),
                  label: const Text('Reset to default'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    _editing = true;
    await ref.read(systemPromptProvider.notifier).save(_controller.text);
    _editing = false;
    if (!mounted) return;
    await _showSavedDialog(context);
  }

  Future<void> _showSavedDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Saved'),
        content: const Text('System prompt has been saved.'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleReset() async {
    _editing = true;
    await ref.read(systemPromptProvider.notifier).reset();
    _controller.text = SystemPromptState.defaultPrompt;
    _editing = false;
  }

  String? _validatePrompt(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'System prompt cannot be empty';
    return null;
  }
}
