import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_fonts.dart';
import '../../../app/theme/app_shapes.dart';
import '../../../app/theme/app_spacing.dart';
import '../models/pending_question.dart';

class AskUserCard extends StatefulWidget {
  const AskUserCard({
    super.key,
    required this.question,
    required this.onSubmit,
    required this.onDismiss,
  });

  final PendingQuestion question;
  final void Function(String answer) onSubmit;
  final VoidCallback onDismiss;

  @override
  State<AskUserCard> createState() => _AskUserCardState();
}

class _AskUserCardState extends State<AskUserCard> {
  final TextEditingController _textController = TextEditingController();
  String? _selectedOption;
  bool _showOtherField = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (widget.question.options != null && widget.question.options!.isNotEmpty) {
      if (_showOtherField) {
        return _textController.text.trim().isNotEmpty;
      }
      return _selectedOption != null;
    }
    return true;
  }

  String get _answerValue {
    if (widget.question.options != null && widget.question.options!.isNotEmpty) {
      if (_showOtherField) {
        return _textController.text.trim();
      }
      return _selectedOption ?? '';
    }
    return _textController.text.trim();
  }

  void _handleSubmit() {
    HapticFeedback.selectionClick();
    widget.onSubmit(_answerValue);
  }

  void _handleSkip() {
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final muted = AppColors.textSecondary(brightness);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.8,
      ),
      child: Material(
        color: AppColors.assistantBubble(brightness),
        shape: AppShapes.sm(
          side: BorderSide(color: AppColors.accent.withValues(alpha: 0.4)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space3 + 1,
                AppSpacing.space2 + 1,
                AppSpacing.space3 + 1,
                AppSpacing.space2 + 1,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.help_outline,
                    size: AppIconSize.md,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: Text(
                      'Question from assistant',
                      style: AppFonts.labelSmall().copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: AppColors.borderSubtle(brightness),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space3 + 1,
                AppSpacing.space3,
                AppSpacing.space3 + 1,
                AppSpacing.space3,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.question.question,
                    style: AppFonts.bodyLarge().copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (widget.question.context != null &&
                      widget.question.context!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      widget.question.context!,
                      style: AppFonts.bodySmall().copyWith(color: muted),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space3 + 1,
                0,
                AppSpacing.space3 + 1,
                AppSpacing.space3,
              ),
              child: _buildInput(brightness, muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(Brightness brightness, Color muted) {
    if (widget.question.options != null && widget.question.options!.isNotEmpty) {
      return _buildOptionsInput(brightness, muted);
    }
    return _buildFreeTextInput(brightness, muted);
  }

  Widget _buildOptionsInput(Brightness brightness, Color muted) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...widget.question.options!.map((option) {
          final isSelected = !_showOtherField && _selectedOption == option;
          return _OptionTile(
            label: option,
            isSelected: isSelected,
            onTap: () => setState(() {
              _selectedOption = option;
              _showOtherField = false;
            }),
          );
        }),
        _OptionTile(
          label: 'Other',
          isSelected: _showOtherField,
          onTap: () => setState(() {
            _showOtherField = true;
            _selectedOption = null;
          }),
        ),
        if (_showOtherField) ...[
          const SizedBox(height: AppSpacing.space2),
          _FreeTextField(
            controller: _textController,
            onChanged: (_) => setState(() {}),
            brightness: brightness,
          ),
        ],
        const SizedBox(height: AppSpacing.space3),
        _ActionRow(
          canSubmit: _canSubmit,
          onSubmit: _handleSubmit,
          onSkip: _handleSkip,
        ),
      ],
    );
  }

  Widget _buildFreeTextInput(Brightness brightness, Color muted) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FreeTextField(
          controller: _textController,
          brightness: brightness,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.space3),
        _ActionRow(
          canSubmit: _canSubmit,
          onSubmit: _handleSubmit,
          onSkip: _handleSkip,
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space2,
          vertical: AppSpacing.space2 + 1,
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: AppIconSize.lg,
              color: isSelected
                  ? AppColors.accent
                  : AppColors.textTertiary(brightness),
            ),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: Text(
                label,
                style: AppFonts.bodyMedium().copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FreeTextField extends StatelessWidget {
  const _FreeTextField({
    required this.controller,
    this.brightness,
    this.onChanged,
  });

  final TextEditingController controller;
  final Brightness? brightness;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final b = brightness ?? Theme.of(context).brightness;
    return Material(
      color: AppColors.bgTertiary(b),
      shape: AppShapes.sm(),
      clipBehavior: Clip.antiAlias,
      child: TextField(
        controller: controller,
        minLines: 1,
        maxLines: 4,
        autofocus: true,
        onChanged: onChanged,
        style: AppFonts.bodyMedium(),
        textInputAction: TextInputAction.newline,
        decoration: InputDecoration(
          hintText: 'Type your answer...',
          hintStyle: AppFonts.bodyMedium().copyWith(
            color: AppColors.textTertiary(b),
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space3,
            vertical: AppSpacing.space2 + 1,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.canSubmit,
    required this.onSubmit,
    required this.onSkip,
  });

  final bool canSubmit;
  final VoidCallback onSubmit;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: onSkip,
          child: const Text('Skip'),
        ),
        const SizedBox(width: AppSpacing.space2),
        FilledButton(
          onPressed: canSubmit ? onSubmit : null,
          child: const Text('Submit'),
        ),
      ],
    );
  }
}