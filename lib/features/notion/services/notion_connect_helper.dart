import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/notion_connection_notifier.dart';
import 'notion_platform.dart';

Future<void> connectNotion(BuildContext context, WidgetRef ref) async {
  final notifier = ref.read(notionConnectionProvider.notifier);
  final url = await notifier.connect();
  if (url == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to start Notion connection.')),
      );
    }
    return;
  }
  final mode = isDesktopPlatform
      ? LaunchMode.externalApplication
      : LaunchMode.inAppBrowserView;
  await launchUrl(Uri.parse(url), mode: mode);
}