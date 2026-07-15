// shadcn-style icon button that shows token usage for a message on tap.
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/widgets/frosted_icon_button.dart';
import '../models/token_usage.dart';
import '../utils/token_format.dart';

class TokenButton extends StatelessWidget {
  const TokenButton({
    super.key,
    required this.usage,
    this.alignment = Alignment.centerLeft,
  });

  final TokenUsage usage;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final iconColor = AppColors.textTertiary(brightness);

    return Align(
      alignment: alignment,
      child: FrostedIconButton(
        icon: Icons.bolt_outlined,
        onPressed: () => _showUsageDialog(context),
        diameter: 28,
        iconSize: AppIconSize.sm,
        iconColor: iconColor,
        tooltip: 'Token usage',
      ),
    );
  }

  void _showUsageDialog(BuildContext context) {
    final rows = <_UsageRow>[
      _UsageRow(
        label: 'Prompt tokens',
        value: usage.promptTokens != null
            ? formatTokenCount(usage.promptTokens!)
            : 'n/a',
      ),
      _UsageRow(
        label: 'Completion tokens',
        value: usage.completionTokens != null
            ? formatTokenCount(usage.completionTokens!)
            : 'n/a',
      ),
      _UsageRow(
        label: 'Total tokens',
        value: usage.totalTokens != null
            ? formatTokenCount(usage.totalTokens!)
            : 'n/a',
      ),
    ];

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Token usage'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.space2),
                rows[i],
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class _UsageRow extends StatelessWidget {
  const _UsageRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
