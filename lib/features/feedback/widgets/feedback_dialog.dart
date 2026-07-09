import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../services/feedback_service.dart';

Future<void> showFeedbackDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const _FeedbackDialog(),
  );
}

class _FeedbackDialog extends StatefulWidget {
  const _FeedbackDialog();

  @override
  State<_FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<_FeedbackDialog> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _emailController = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _messageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Leave feedback'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tell us what you think, what is missing, or what is broken.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary(theme.brightness),
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            TextFormField(
              controller: _messageController,
              minLines: 4,
              maxLines: 8,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Message',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: _validateMessage,
            ),
            const SizedBox(height: AppSpacing.space3),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'For follow-up only',
                border: OutlineInputBorder(),
              ),
              validator: _validateEmail,
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.space2),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _sending ? null : _handleSend,
          child: _sending
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.onPrimary,
                  ),
                )
              : const Text('Send'),
        ),
      ],
    );
  }

  String? _validateMessage(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Message cannot be empty';
    return null;
  }

  String? _validateEmail(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Email cannot be empty';
    final regex = RegExp(r'^\S+@\S+\.\S+$');
    if (!regex.hasMatch(trimmed)) return 'Enter a valid email address';
    return null;
  }

  Future<void> _handleSend() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _sending = true;
      _error = null;
    });

    final secureStorage = const FlutterSecureStorage();
    final service = FeedbackService(secureStorage: secureStorage);

    final ok = await service.sendFeedback(
      message: _messageController.text.trim(),
      email: _emailController.text.trim(),
    );

    service.dispose();

    if (!mounted) return;

    setState(() {
      _sending = false;
    });

    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks for your feedback!')),
      );
    } else {
      setState(() {
        _error = 'Could not send feedback. Please try again later.';
      });
    }
  }
}