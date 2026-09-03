// Frosted-style app bar and bottom bar (translucent fill, no blur).
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

class FrostedAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FrostedAppBar({
    super.key,
    this.title,
    this.actions = const [],
    this.leading,
    this.bottom,
    this.showBorder = true,
  });

  final String? title;
  final List<Widget> actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final bool showBorder;

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? 0.0;
    return Size.fromHeight(kToolbarHeight + bottomHeight);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final barColor = AppColors.barFill(
      isDark ? Brightness.dark : Brightness.light,
    );
    final dividerColor = AppColors.borderSubtle(
      isDark ? Brightness.dark : Brightness.light,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: barColor,
        boxShadow: isDark ? null : AppShadows.xs,
        border: showBorder
            ? Border(bottom: BorderSide(width: 0.5, color: dividerColor))
            : null,
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: NavigationToolbar(
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 8),
                    if (leading != null) ...[leading!],
                    const SizedBox(width: 8),
                  ],
                ),
                centerMiddle: false,
                middleSpacing: 0,
                middle: title == null
                    ? null
                    : Text(
                        title!,
                        style: AppFonts.titleMedium().copyWith(
                          color: theme.appBarTheme.foregroundColor,
                        ),
                      ),
                trailing: actions.isEmpty
                    ? null
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 8,
                        children: [
                          const SizedBox(width: 0),
                          ...actions.map((action) => action),
                          const SizedBox(width: 0),
                        ],
                      ),
              ),
            ),
            if (bottom != null)
              SizedBox(
                height: bottom!.preferredSize.height,
                width: double.infinity,
                child: bottom!,
              )
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}

/// Frosted bar pinned at the bottom edge of the screen.
class FrostedBottomBar extends StatelessWidget {
  const FrostedBottomBar({
    super.key,
    required this.child,
    this.showBorder = true,
  });

  final Widget child;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final barColor = AppColors.barFill(
      isDark ? Brightness.dark : Brightness.light,
    );
    final dividerColor = AppColors.borderSubtle(
      isDark ? Brightness.dark : Brightness.light,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: barColor,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0x40000000)
                : const Color(0x0D0F0F0F),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
        border: showBorder
            ? Border(top: BorderSide(width: 0.5, color: dividerColor))
            : null,
      ),
      child: SafeArea(top: false, child: child),
    );
  }
}
