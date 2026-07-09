// shadcn-style icon copy button with copied-state feedback.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/widgets/frosted_icon_button.dart';

class CopyButton extends StatefulWidget {
  const CopyButton({
    super.key,
    required this.text,
    this.alignment = Alignment.centerLeft,
  });

  final String text;
  final Alignment alignment;

  @override
  State<CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<CopyButton> {
  bool _copied = false;

  Future<void> _handleCopy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    if (!mounted) {
      return;
    }
    setState(() {
      _copied = true;
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _copied = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final iconColor = _copied
        ? AppColors.success
        : AppColors.textTertiary(brightness);

    return Align(
      alignment: widget.alignment,
      child: FrostedIconButton(
        icon: _copied ? Icons.check : Icons.copy,
        onPressed: _handleCopy,
        diameter: 28,
        iconSize: AppIconSize.sm,
        iconColor: iconColor,
      ),
    );
  }
}
