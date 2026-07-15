import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/widgets/settings_body.dart';
import '../providers/ai_provider_notifier.dart';
import 'ai_provider_form.dart';

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
      child: AiProviderForm(
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
