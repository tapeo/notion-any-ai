// Attach button and selected page chips shown in a single row.
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_fonts.dart';
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
      spacing: AppSpacing.space1,
      runSpacing: AppSpacing.space1,
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
    final color = AppColors.textTertiary(theme.brightness);
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space2,
          vertical: AppSpacing.space1,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: color, size: AppIconSize.sm),
            const SizedBox(width: AppSpacing.space1),
            Text(
              'Notion page',
              style: AppFonts.labelSmall().copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
