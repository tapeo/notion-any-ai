import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/widgets/frosted_icon_button.dart';
import '../../settings/widgets/settings_body.dart';
import '../providers/ai_provider_notifier.dart';

class AiProviderSetup extends ConsumerStatefulWidget {
  const AiProviderSetup({super.key});

  @override
  ConsumerState<AiProviderSetup> createState() => _AiProviderSetupState();
}

class _AiProviderSetupState extends ConsumerState<AiProviderSetup> {
  final _formKey = GlobalKey<FormState>();
  final _endpointController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _modelController = TextEditingController();

  bool _obscureApiKey = true;
  bool _initialized = false;

  @override
  void dispose() {
    _endpointController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiProviderProvider);

    if (!_initialized) {
      _initialized = true;
      _endpointController.text = state.endpoint;
      _modelController.text = state.model;
    }

    return SettingsBody(
      title: 'AI provider',
      icon: Icons.smart_toy_outlined,
      description:
          'Configure a custom OpenAI-compatible provider with endpoint, API key, and model. Used by the chat assistant to generate replies.',
      child: _EditForm(
        formKey: _formKey,
        endpointController: _endpointController,
        apiKeyController: _apiKeyController,
        modelController: _modelController,
        obscureApiKey: _obscureApiKey,
        onToggleObscure: _toggleObscure,
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
        .read(aiProviderProvider.notifier)
        .save(
          endpoint: _endpointController.text,
          model: _modelController.text,
          apiKey: apiKey.isEmpty ? null : apiKey,
        );
    if (!mounted) return;
    await _showSavedDialog(context);
  }

  Future<void> _showSavedDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Saved'),
        content: const Text('AI provider settings have been saved.'),
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
    required this.endpointController,
    required this.apiKeyController,
    required this.modelController,
    required this.obscureApiKey,
    required this.onToggleObscure,
    required this.hasApiKey,
    required this.saving,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController endpointController;
  final TextEditingController apiKeyController;
  final TextEditingController modelController;
  final bool obscureApiKey;
  final VoidCallback onToggleObscure;
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
            controller: endpointController,
            decoration: const InputDecoration(
              labelText: 'Endpoint',
              hintText: 'https://api.openai.com/v1',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            autocorrect: false,
            keyboardType: TextInputType.url,
            validator: _validateEndpoint,
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
          TextFormField(
            controller: modelController,
            decoration: const InputDecoration(
              labelText: 'Model',
              hintText: 'gpt-4o-mini',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            autocorrect: false,
            validator: _validateModel,
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

  String? _validateEndpoint(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Endpoint is required';
    final parsed = Uri.tryParse(trimmed);
    if (parsed == null || !parsed.hasScheme || !parsed.hasAuthority) {
      return 'Enter a valid URL';
    }
    if (parsed.scheme != 'http' && parsed.scheme != 'https') {
      return 'Use http or https';
    }
    return null;
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
