import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_fonts.dart';
import '../../../app/theme/app_spacing.dart';
import '../../notion/models/notion_page_ref.dart';

class ChatPageChip extends StatelessWidget {
  const ChatPageChip({super.key, required this.page, required this.onClear});

  final NotionPageRef page;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = AppColors.textTertiary(theme.brightness);
    return Material(
      color: AppColors.bgPrimary(theme.brightness),
      shape: StadiumBorder(
        side: BorderSide(color: AppColors.borderDefault(theme.brightness)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onClear();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space2,
            vertical: AppSpacing.space1,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_rounded,
                size: AppIconSize.sm,
                color: AppColors.accent,
              ),
              const SizedBox(width: AppSpacing.space1),
              if (page.icon != null && page.icon!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.space1),
                  child: Text(page.icon!, style: const TextStyle(fontSize: 13)),
                ),
              Flexible(
                child: Text(
                  page.title,
                  style: AppFonts.labelSmall().copyWith(color: muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.space1),
              Icon(
                Icons.close,
                size: AppIconSize.sm,
                color: AppColors.textTertiary(theme.brightness),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
