import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_shapes.dart';
import '../../../app/theme/app_spacing.dart';
import '../../settings/widgets/settings_body.dart';
import '../providers/notion_connection_notifier.dart';
import '../services/notion_platform.dart';
import '../states/notion_connection_state.dart';
import 'notion_tool_list.dart';

class NotionSetup extends ConsumerStatefulWidget {
  const NotionSetup({super.key});

  @override
  ConsumerState<NotionSetup> createState() => _NotionSetupState();
}

class _NotionSetupState extends ConsumerState<NotionSetup> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notionConnectionProvider.notifier).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notionConnectionProvider);

    final Widget content = !state.connected
        ? _DisconnectedView(state: state, ref: ref)
        : _ConnectedView(state: state, ref: ref);

    return SettingsBody(
      title: 'Notion',
      icon: Icons.link_outlined,
      description:
          'Connect your Notion workspace so the assistant can search, read, and update your Notion pages from the chat.',
      child: content,
    );
  }
}

class _DisconnectedView extends StatelessWidget {
  const _DisconnectedView({required this.state, required this.ref});

  final NotionConnectionState state;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connect your Notion workspace so the assistant can search, read, and update your Notion pages from the chat. You\'ll authorize access via Notion\'s consent screen.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary(theme.brightness),
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        FilledButton.icon(
          onPressed: state.connecting ? null : () => _handleConnect(context),
          icon: state.connecting
              ? const SizedBox(
                  width: AppIconSize.md,
                  height: AppIconSize.md,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.link_outlined, size: AppIconSize.md),
          label: Text(state.connecting ? 'Redirecting...' : 'Connect Notion'),
        ),
      ],
    );
  }

  Future<void> _handleConnect(BuildContext context) async {
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
}

class _ConnectedView extends StatelessWidget {
  const _ConnectedView({required this.state, required this.ref});

  final NotionConnectionState state;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifier = ref.read(notionConnectionProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          shape: AppShapes.md(
            side: BorderSide(color: AppColors.borderSubtle(theme.brightness)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space3,
              vertical: AppSpacing.space3 - 2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.workspaceName != null
                      ? '${state.workspaceName}'
                      : 'Notion',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Connected. Toggle to let the assistant use Notion tools during chat.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary(theme.brightness),
                  ),
                ),
                const SizedBox(height: AppSpacing.space3),
                Row(
                  children: [
                    Switch(
                      value: state.enabled,
                      onChanged: state.saving
                          ? null
                          : (v) {
                              HapticFeedback.selectionClick();
                              notifier.toggleEnabled(v);
                            },
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: state.disconnecting
                              ? null
                              : () => _handleDisconnect(context),
                          icon: state.disconnecting
                              ? const SizedBox(
                                  width: AppIconSize.md,
                                  height: AppIconSize.md,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.logout_outlined,
                                  size: AppIconSize.md,
                                ),
                          label: const Text('Disconnect'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        Text(
          'Notion tools',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          'Choose which Notion tools the assistant can call. Tools are grouped by read and write access.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary(theme.brightness),
          ),
        ),
        const SizedBox(height: AppSpacing.space3),
        const NotionToolList(),
        if (state.saving)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.space2),
            child: Row(
              children: [
                const SizedBox(
                  width: AppIconSize.sm,
                  height: AppIconSize.sm,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: AppSpacing.space2),
                Text(
                  'Saving...',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary(theme.brightness),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _handleDisconnect(BuildContext context) async {
    await ref.read(notionConnectionProvider.notifier).disconnect();
  }
}
