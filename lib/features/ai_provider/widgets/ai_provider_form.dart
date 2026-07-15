import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/widgets/frosted_icon_button.dart';

class AiProviderForm extends StatelessWidget {
  const AiProviderForm({
    super.key,
    required this.formKey,
    required this.endpointController,
    required this.apiKeyController,
    required this.modelController,
    required this.obscureApiKey,
    required this.onToggleObscure,
    required this.hasApiKey,
    required this.saving,
    required this.onSave,
    this.showSaveButton = true,
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
  final bool showSaveButton;

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
            validator: validateEndpoint,
          ),
          const SizedBox(height: AppSpacing.space3),
          TextFormField(
            controller: apiKeyController,
            decoration: InputDecoration(
              labelText: 'API key (from your AI provider)',
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
            validator: (value) => validateApiKey(value, hasApiKey),
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
            validator: validateModel,
          ),
          if (showSaveButton) ...[
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
        ],
      ),
    );
  }

  static String? validateEndpoint(String? value) {
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

  static String? validateApiKey(String? value, bool hasApiKey) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty && !hasApiKey) return 'API key is required';
    return null;
  }

  static String? validateModel(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Model is required';
    return null;
  }
}
