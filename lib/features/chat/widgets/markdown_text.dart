// Markdown renderer themed to match the chat bubbles.
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_fonts.dart';
import '../../../app/theme/app_spacing.dart';

class MarkdownText extends StatelessWidget {
  const MarkdownText({
    super.key,
    required this.data,
    required this.isUser,
    this.pStyle,
  });

  final String data;
  final bool isUser;
  final TextStyle? pStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final base = MarkdownStyleSheet.fromTheme(theme);
    final inkColor = AppColors.textPrimary(brightness);
    final mutedColor = AppColors.textSecondary(brightness);
    final codeBg = AppColors.bgTertiary(brightness).withValues(
      alpha: brightness == Brightness.dark ? 1.0 : 0.6,
    );

    final styleSheet = base.copyWith(
      p: pStyle ??
          AppFonts.bodyLarge().copyWith(
            color: inkColor,
            height: 1.55,
          ),
      h1: AppFonts.displaySmall().copyWith(color: inkColor),
      h2: AppFonts.headlineSmall().copyWith(color: inkColor),
      h3: AppFonts.headlineSmall().copyWith(
        color: inkColor,
        fontSize: 19,
      ),
      h4: AppFonts.titleLarge().copyWith(color: inkColor),
      h5: AppFonts.titleMedium().copyWith(color: inkColor),
      h6: AppFonts.titleMedium().copyWith(color: mutedColor),
      pPadding: const EdgeInsets.symmetric(vertical: AppSpacing.space1),
      blockquote: AppFonts.bodyLarge().copyWith(color: mutedColor),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            width: 3,
            color: AppColors.borderDefault(brightness),
          ),
        ),
      ),
      blockquotePadding: const EdgeInsets.only(
        left: AppSpacing.space3,
        bottom: AppSpacing.space1,
      ),
      code: AppFonts.codeSm().copyWith(color: inkColor),
      codeblockDecoration: BoxDecoration(
        color: codeBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      codeblockPadding: const EdgeInsets.all(AppSpacing.space3),
      a: AppFonts.bodyLarge().copyWith(
        color: AppColors.accent,
        decoration: TextDecoration.none,
      ),
      listBullet: AppFonts.bodyLarge().copyWith(color: inkColor),
      listIndent: AppSpacing.space4,
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.borderSubtle(brightness),
            width: 1,
          ),
        ),
      ),
    );

    return SelectionArea(
      child: MarkdownBody(
        data: data,
        onTapLink: _onTapLink,
        styleSheet: styleSheet,
      ),
    );
  }

  Future<void> _onTapLink(String text, String? href, String title) async {
    if (href == null) {
      return;
    }
    final uri = Uri.tryParse(href);
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}