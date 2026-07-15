// Markdown renderer themed to match the chat bubbles.
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
    return SelectionArea(
      child: MarkdownBody(
        data: data,
        onTapLink: _onTapLink,
        styleSheet: MarkdownStyleSheet.fromTheme(
          Theme.of(context),
        ).copyWith(p: pStyle),
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
