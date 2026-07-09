import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'frosted_icon_button.dart';

/// A toggle row for a single tool, shared by builtin and Notion tool lists.
///
/// Shows the tool name, an info button that opens a dialog with the
/// [description], an optional trailing badge widget (e.g. a "Business plan"
/// label), and a [Switch]. The switch is disabled when [saving] is true or
/// when [locked] is true (in which case it also renders as off).
class ToolRow extends StatelessWidget {
  const ToolRow({
    super.key,
    required this.name,
    required this.description,
    required this.isOn,
    required this.saving,
    required this.onToggle,
    this.locked = false,
    this.badge,
  });

  final String name;
  final String description;
  final bool isOn;
  final bool saving;
  final bool locked;
  final void Function(bool checked) onToggle;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Row(
              spacing: AppSpacing.space2,
              children: [
                FrostedIconButton(
                  onPressed: () => _showDescription(context),
                  icon: Icons.info_outline,
                  diameter: 28,
                  iconSize: AppIconSize.sm,
                ),
                Flexible(
                  child: Text(
                    name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary(theme.brightness),
                    ),
                  ),
                ),
                ?badge,
              ],
            ),
          ),
          Switch(
            value: locked ? false : isOn,
            onChanged: (saving || locked)
                ? null
                : (checked) {
                    HapticFeedback.selectionClick();
                    onToggle(checked);
                  },
          ),
        ],
      ),
    );
  }

  void _showDescription(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(description),
        contentTextStyle: Theme.of(context).textTheme.bodySmall,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
