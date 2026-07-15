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
  String _selectedLanguage = 'en';

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
      _selectedLanguage = state.language;
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
        selectedLanguage: _selectedLanguage,
        onLanguageChanged: _handleLanguageChanged,
        hasApiKey: state.hasApiKey,
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
    final apiKey = _apiKeyController.text.trim();
    await ref
        .read(voiceInputProvider.notifier)
        .save(
          model: _modelController.text,
          apiKey: apiKey.isEmpty ? null : apiKey,
          language: _selectedLanguage,
        );
    if (!mounted) return;
    await _showSavedDialog(context);
  }

  void _handleLanguageChanged(String? value) {
    if (value == null) return;
    setState(() {
      _selectedLanguage = value;
    });
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
    required this.selectedLanguage,
    required this.onLanguageChanged,
    required this.hasApiKey,
    required this.saving,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController modelController;
  final TextEditingController apiKeyController;
  final bool obscureApiKey;
  final VoidCallback onToggleObscure;
  final String selectedLanguage;
  final ValueChanged<String?> onLanguageChanged;
  final bool hasApiKey;
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
              hintText: hasApiKey ? 'Leave empty to keep current' : 'sk-...',
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
            validator: (value) => _validateApiKey(value, hasApiKey),
          ),
          const SizedBox(height: AppSpacing.space3),
          DropdownButtonFormField<String>(
            value: selectedLanguage,
            decoration: const InputDecoration(
              labelText: 'Language',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'it', child: Text('Italian')),
              DropdownMenuItem(value: 'fr', child: Text('French')),
              DropdownMenuItem(value: 'de', child: Text('German')),
              DropdownMenuItem(value: 'es', child: Text('Spanish')),
              DropdownMenuItem(value: 'pt', child: Text('Portuguese')),
              DropdownMenuItem(value: 'ja', child: Text('Japanese')),
              DropdownMenuItem(value: 'zh', child: Text('Chinese')),
              DropdownMenuItem(value: 'ko', child: Text('Korean')),
              DropdownMenuItem(value: 'ru', child: Text('Russian')),
              DropdownMenuItem(value: 'ar', child: Text('Arabic')),
              DropdownMenuItem(value: 'hi', child: Text('Hindi')),
              DropdownMenuItem(value: 'nl', child: Text('Dutch')),
              DropdownMenuItem(value: 'pl', child: Text('Polish')),
              DropdownMenuItem(value: 'tr', child: Text('Turkish')),
              DropdownMenuItem(value: 'th', child: Text('Thai')),
              DropdownMenuItem(value: 'vi', child: Text('Vietnamese')),
            ],
            onChanged: onLanguageChanged,
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

  String? _validateApiKey(String? value, bool hasApiKey) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty && !hasApiKey) return 'API key is required';
    return null;
  }

  String? _validateModel(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Model is required';
    return null;
  }
}
