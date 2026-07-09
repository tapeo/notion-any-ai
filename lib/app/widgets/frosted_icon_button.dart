// Shared icon button with a circular solid background and haptic feedback.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../../features/notion/services/notion_platform.dart';

/// Icon button following the Notion icon-button spec (DESIGN.md 4.1).
///
/// Transparent background by default with a secondary-colored icon and a
/// subtle hover fill (`rgba(55,53,47,0.06)`). Fires [HapticFeedback.selectionClick]
/// on tap when enabled. Platform-aware sizing: 44px diameter on mobile, 32px on
/// desktop. Override [diameter] and [iconSize] for bespoke contexts (e.g. dense
/// rows). Pass [solidColor] for tinted variants (send/stop buttons).
class FrostedIconButton extends StatefulWidget {
  const FrostedIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.diameter,
    this.iconSize,
    this.iconColor,
    this.solidColor,
    this.haptic = true,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double? diameter;
  final double? iconSize;
  final Color? iconColor;
  final Color? solidColor;
  final bool haptic;

  @override
  State<FrostedIconButton> createState() => _FrostedIconButtonState();
}

class _FrostedIconButtonState extends State<FrostedIconButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.20,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _enabled => widget.onPressed != null;

  double get _diameter => widget.diameter ?? (isMobilePlatform ? 44.0 : 32.0);

  double get _resolvedIconSize =>
      widget.iconSize ?? (isMobilePlatform ? AppIconSize.lg : AppIconSize.md);

  Future<void> _handleTapDown() async {
    if (!_enabled) {
      return;
    }
    _controller.forward();
  }

  Future<void> _handleTapUp() async {
    if (!_enabled) {
      return;
    }
    if (widget.haptic) {
      await HapticFeedback.selectionClick();
    }
    _controller.reverse();
    widget.onPressed!();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final d = _diameter;
    final size = _resolvedIconSize;

    final resolvedIconColor =
        widget.iconColor ??
        (_enabled
            ? AppColors.textSecondary(brightness)
            : AppColors.textDisabled(brightness));

    final bgColor = widget.solidColor ?? AppColors.bgTertiary(brightness);
    final hoverColor = AppColors.hoverFillFor(brightness);

    final core = SizedBox(
      width: d,
      height: d,
      child: Material(
        color: bgColor,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTapDown: _enabled ? (_) => _handleTapDown() : null,
          onTapUp: _enabled ? (_) => _handleTapUp() : null,
          onTapCancel: _enabled ? _handleTapCancel : null,
          customBorder: const CircleBorder(),
          hoverColor: hoverColor,
          highlightColor: AppColors.activeFillFor(brightness),
          splashColor: Colors.transparent,
          child: Center(
            child: Icon(widget.icon, size: size, color: resolvedIconColor),
          ),
        ),
      ),
    );

    final scaled = ScaleTransition(scale: _scale, child: core);

    final overflow = SizedBox(
      width: d,
      height: d,
      child: OverflowBox(
        maxWidth: d * 1.25,
        maxHeight: d * 1.25,
        minWidth: d,
        minHeight: d,
        alignment: Alignment.center,
        child: scaled,
      ),
    );

    if (widget.tooltip != null && _enabled) {
      return Tooltip(message: widget.tooltip!, child: overflow);
    }
    return overflow;
  }
}
