// Markdown renderer themed to match the chat bubbles.
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';

class MarkdownText extends StatelessWidget {
  const MarkdownText({super.key, required this.data, required this.isUser});

  final String data;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final baseColor = isUser
        ? AppColors.userBubbleText
        : AppColors.assistantBubbleText(brightness);

    final baseStyle = (theme.textTheme.bodyMedium ?? const TextStyle())
        .copyWith(color: baseColor);

    final codeBg = isUser
        ? const Color(0x33FFFFFF)
        : AppColors.subtleFillFor(brightness);
    final codeBlockBg = isUser
        ? const Color(0x33FFFFFF)
        : AppColors.bgTertiary(brightness);
    final codeColor = baseColor;
    final linkColor = isUser ? AppColors.userBubbleText : AppColors.accent;

    final styleSheet = MarkdownStyleSheet(
      p: baseStyle,
      h1: baseStyle.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      h2: baseStyle.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      h3: baseStyle.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      h4: baseStyle.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      h5: baseStyle.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      h6: baseStyle.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      listBullet: baseStyle,
      strong: baseStyle.copyWith(fontWeight: FontWeight.w700),
      em: baseStyle.copyWith(fontStyle: FontStyle.italic),
      del: baseStyle.copyWith(decoration: TextDecoration.lineThrough),
      blockquote: baseStyle.copyWith(
        color: baseColor.withValues(alpha: 0.85),
        fontStyle: FontStyle.italic,
      ),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: linkColor.withValues(alpha: 0.5), width: 3),
        ),
      ),
      code: baseStyle.copyWith(
        fontFamily: 'monospace',
        fontSize: 13,
        backgroundColor: codeBg,
        color: codeColor,
      ),
      codeblockPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2 + 2,
        vertical: AppSpacing.space2,
      ),
      codeblockDecoration: BoxDecoration(
        color: codeBlockBg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      a: baseStyle.copyWith(color: linkColor, decoration: TextDecoration.none),
      tableHead: baseStyle.copyWith(fontWeight: FontWeight.w700),
      tableBody: baseStyle,
      tableHeadAlign: TextAlign.start,
      tableBorder: TableBorder.all(
        color: AppColors.borderSubtle(brightness),
        width: 1,
      ),
      tableCellsPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: AppSpacing.space1 + 2,
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle(brightness), width: 1),
        ),
      ),
    );

    return SelectionArea(
      child: MarkdownBody(
        data: data,
        styleSheet: styleSheet,
        onTapLink: _onTapLink,
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
