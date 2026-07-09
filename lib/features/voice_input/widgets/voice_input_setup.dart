import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/widgets/frosted_icon_button.dart';
import '../../settings/widgets/settings_body.dart';
import '../providers/voice_input_notifier.dart';

class VoiceInputSetup extends ConsumerStatefulWidget {
  const VoiceInputSetup({super.key});

  @override
  ConsumerState<VoiceInputSetup> createState() => _VoiceInputSetupState();
}

class _VoiceInputSetupState extends ConsumerState<VoiceInputSetup> {
  final _formKey = GlobalKey<FormState>();
  final _modelController = TextEditingController();
  final _apiKeyController = TextEditingController();

  bool _obscureApiKey = true;
  bool _initialized = false;

  @override
  void dispose() {
    _modelController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voiceInputProvider);

    if (!_initialized) {
      _initialized = true;
      if (state.model.isNotEmpty) {
        _modelController.text = state.model;
      } else {
        _modelController.text = 'whisper-1';
      }
    }

    return SettingsBody(
      title: 'Voice input',
      icon: Icons.mic_outlined,
      description:
          'Configure a Whisper-compatible transcription provider with '
          'an API key and model. Press and hold the microphone button in '
          'the chat input bar to dictate a message.',
      child: _EditForm(
        formKey: _formKey,
        modelController: _modelController,
        apiKeyController: _apiKeyController,
        obscureApiKey: _obscureApiKey,
        onToggleObscure: _toggleObscure,
        saving: state.saving,
        onSave: _handleSave,
      ),
    );
  }

  void _toggleObscure() {
    setState(() {
      _obscureApiKey = !_obscureApiKey;
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(voiceInputProvider.notifier).save(
          model: _modelController.text,
          apiKey: _apiKeyController.text,
        );
    if (!mounted) return;
    await _showSavedDialog(context);
  }

  Future<void> _showSavedDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Saved'),
        content: const Text('Voice input settings have been saved.'),
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

class _EditForm extends StatelessWidget {
  const _EditForm({
    required this.formKey,
    required this.modelController,
    required this.apiKeyController,
    required this.obscureApiKey,
    required this.onToggleObscure,
    required this.saving,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController modelController;
  final TextEditingController apiKeyController;
  final bool obscureApiKey;
  final VoidCallback onToggleObscure;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: modelController,
            decoration: const InputDecoration(
              labelText: 'Model',
              hintText: 'whisper-1',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            autocorrect: false,
            validator: _validateModel,
          ),
          const SizedBox(height: AppSpacing.space3),
          TextFormField(
            controller: apiKeyController,
            decoration: InputDecoration(
              labelText: 'API key',
              hintText: 'sk-...',
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: FrostedIconButton(
                icon: obscureApiKey
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                onPressed: onToggleObscure,
                diameter: 28,
                iconSize: AppIconSize.sm + 2,
              ),
            ),
            obscureText: obscureApiKey,
            autocorrect: false,
            validator: _validateApiKey,
          ),
          const SizedBox(height: AppSpacing.space4),
          FilledButton.icon(
            onPressed: saving ? null : onSave,
            icon: saving
                ? const SizedBox(
                    width: AppIconSize.md,
                    height: AppIconSize.md,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined, size: AppIconSize.md),
            label: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String? _validateApiKey(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'API key is required';
    return null;
  }

  String? _validateModel(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Model is required';
    return null;
  }
}