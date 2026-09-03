import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_fonts.dart';
import '../../../app/theme/app_shapes.dart';
import '../../../app/theme/app_spacing.dart';

class EmptyChatState extends StatelessWidget {
  const EmptyChatState({super.key, this.onSuggestion});

  final void Function(String prompt)? onSuggestion;

  static const _suggestions = [
    'Summarize this page for me',
    'Find tasks due this week in my workspace',
    'Draft an update based on my notes',
    'What pages did I work on recently?',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: Image.asset('assets/macos.png'),
                    ),
                    const SizedBox(height: AppSpacing.space5),
                    Text(
                      'What can I help you with?',
                      textAlign: TextAlign.center,
                      style: AppFonts.displaySmall().copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      'Ask anything about your Notion workspace',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary(brightness),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.space6),
                    Wrap(
                      spacing: AppSpacing.space2,
                      runSpacing: AppSpacing.space2,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final suggestion in _suggestions)
                          _SuggestionChip(
                            label: suggestion,
                            onPressed: onSuggestion == null
                                ? null
                                : () => onSuggestion!(suggestion),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    return Material(
      color: AppColors.bgPrimary(brightness),
      shape: AppShapes.md(
        side: BorderSide(color: AppColors.borderDefault(brightness)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space3,
            vertical: AppSpacing.space2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: AppIconSize.sm,
                color: AppColors.accent,
              ),
              const SizedBox(width: AppSpacing.space1 + 2),
              Text(
                label,
                style: AppFonts.labelMedium().copyWith(
                  color: AppColors.textPrimary(brightness),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}