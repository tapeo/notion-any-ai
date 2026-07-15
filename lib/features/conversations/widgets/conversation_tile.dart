import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/widgets/frosted_icon_button.dart';
import '../../chat/utils/token_format.dart';
import '../../notion/services/notion_platform.dart';
import '../models/conversation.dart';

class ConversationTile extends StatefulWidget {
  const ConversationTile({
    super.key,
    required this.summary,
    required this.isActive,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
    this.onReveal,
  });

  final ConversationSummary summary;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback? onReveal;

  @override
  State<ConversationTile> createState() => _ConversationTileState();
}

class _ConversationTileState extends State<ConversationTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    if (isMobilePlatform) {
      return _buildMobile();
    }
    return _buildDesktop();
  }

  Widget _buildDesktop() {
    final theme = Theme.of(context);
    final b = theme.brightness;
    final bg = widget.isActive
        ? AppColors.activeFillFor(b)
        : (_hovered ? AppColors.hoverFillFor(b) : Colors.transparent);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: bg,
        child: InkWell(
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space3,
              vertical: AppSpacing.space2,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: _buildContent(theme, b)),
                if (_hovered) ...[
                  const SizedBox(width: AppSpacing.space1),
                  _buildDesktopActions(theme, b),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopActions(ThemeData theme, Brightness b) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.onReveal != null)
          _ActionIconButton(
            icon: Icons.folder_open_outlined,
            tooltip: 'Show in Finder',
            onTap: widget.onReveal!,
            b: b,
          ),
        _ActionIconButton(
          icon: Icons.edit_outlined,
          tooltip: 'Rename',
          onTap: widget.onRename,
          b: b,
        ),
        _ActionIconButton(
          icon: Icons.delete_outline,
          tooltip: 'Delete',
          onTap: widget.onDelete,
          b: b,
          color: AppColors.error,
        ),
      ],
    );
  }

  Widget _buildMobile() {
    final theme = Theme.of(context);
    final b = theme.brightness;
    final bg = widget.isActive
        ? AppColors.activeFillFor(b)
        : Colors.transparent;

    return Slidable(
      key: ValueKey(widget.summary.id),
      groupTag: 'conversations',
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        extentRatio: 0.3,
        children: [
          if (widget.onReveal != null)
            CustomSlidableAction(
              padding: EdgeInsets.all(AppSpacing.space1),
              backgroundColor: bg,
              onPressed: (_) => widget.onReveal!(),
              child: FrostedIconButton(
                icon: Icons.folder_open_outlined,
                onPressed: widget.onReveal,
                diameter: 32,
                iconSize: AppIconSize.lg,
                iconColor: AppColors.white,
                solidColor: AppColors.accent,
                haptic: false,
              ),
            ),
          CustomSlidableAction(
            padding: EdgeInsets.all(AppSpacing.space1),
            backgroundColor: bg,
            onPressed: (_) => widget.onRename(),
            child: FrostedIconButton(
              icon: Icons.edit_outlined,
              onPressed: widget.onRename,
              diameter: 32,
              iconSize: AppIconSize.lg,
              iconColor: AppColors.white,
              solidColor: AppColors.accent,
              haptic: false,
            ),
          ),
          CustomSlidableAction(
            padding: EdgeInsets.all(AppSpacing.space1),
            backgroundColor: bg,
            onPressed: (_) => widget.onDelete(),
            child: FrostedIconButton(
              icon: Icons.delete_outline,
              onPressed: widget.onDelete,
              diameter: 32,
              iconSize: AppIconSize.lg,
              iconColor: AppColors.white,
              solidColor: AppColors.error,
              haptic: false,
            ),
          ),
        ],
      ),
      child: Material(
        color: bg,
        child: InkWell(
          onTap: widget.onTap,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space3,
                    vertical: AppSpacing.space2,
                  ),
                  child: _buildContent(theme, b),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, Brightness b) {
    final titleColor = AppColors.textPrimary(b);
    final subtitleColor = AppColors.textTertiary(b);
    final showTokens = widget.summary.totalTokens > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.summary.title,
          style: theme.textTheme.labelMedium?.copyWith(
            color: titleColor,
            fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (showTokens) ...[
          const SizedBox(height: AppSpacing.space1 - 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt_outlined, size: 12, color: subtitleColor),
              const SizedBox(width: AppSpacing.space1 - 2),
              Text(
                formatTokenCount(widget.summary.totalTokens),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: subtitleColor,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.b,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Brightness b;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space1),
          child: Icon(
            icon,
            size: AppIconSize.sm,
            color: color ?? AppColors.textSecondary(b),
          ),
        ),
      ),
    );
  }
}
