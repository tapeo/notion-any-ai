// Attach button and selected page chips shown in a single row.
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_fonts.dart';
import '../../../app/theme/app_shapes.dart';
import '../../../app/theme/app_spacing.dart';
import '../../notion/models/notion_page_ref.dart';
import 'chat_page_chip.dart';

class ChatPageSelectorRow extends StatelessWidget {
  const ChatPageSelectorRow({
    super.key,
    required this.selectedPages,
    required this.onAttach,
    required this.onRemovePage,
  });

  final List<NotionPageRef> selectedPages;
  final VoidCallback onAttach;
  final void Function(NotionPageRef page) onRemovePage;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.space2,
      runSpacing: AppSpacing.space2,
      children: [
        _AttachButton(onPressed: onAttach),
        ...selectedPages.map(
          (page) => ChatPageChip(page: page, onClear: () => onRemovePage(page)),
        ),
      ],
    );
  }
}

class _AttachButton extends StatelessWidget {
  const _AttachButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = AppColors.textTertiary(theme.brightness);
    final textColor = AppColors.textTertiary(theme.brightness);
    return Material(
      color: AppColors.bgPrimary(theme.brightness),
      shape: AppShapes.sm(
        side: BorderSide(color: AppColors.borderDefault(theme.brightness)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space3,
            vertical: AppSpacing.space2 + 1,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, color: iconColor, size: AppIconSize.md),
              const SizedBox(width: AppSpacing.space2),
              Text(
                'Notion',
                style: AppFonts.labelLarge().copyWith(color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
