import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_fonts.dart';
import '../../../app/theme/app_shapes.dart';
import '../../../app/services/secure_storage_provider.dart';
import '../../../app/services/shared_prefs_provider.dart';
import '../../../app/theme/app_spacing.dart';
import '../../ai_provider/providers/ai_provider_notifier.dart';
import '../../ai_provider/providers/ai_provider_storage_provider.dart';
import '../../builtin_tools/providers/builtin_tools_notifier.dart';
import '../../builtin_tools/providers/builtin_tools_storage_provider.dart';
import '../../conversations/providers/conversation_storage_provider.dart';
import '../../conversations/providers/conversations_notifier.dart';
import '../../memory/providers/memory_notifier.dart';
import '../../memory/providers/memory_storage_provider.dart';
import '../../notifications/providers/notifications_provider.dart';
import '../../notifications/services/notifications_service_provider.dart';
import '../../notifications/services/reminder_storage.dart';
import '../../notion/providers/notion_connection_notifier.dart';
import '../../notion/services/notion_recent_pages_storage.dart';
import '../../notion/services/notion_storage.dart';
import '../../system_prompt/providers/system_prompt_notifier.dart';
import '../../system_prompt/providers/system_prompt_storage_provider.dart';
import '../../voice_input/providers/voice_input_notifier.dart';
import '../../voice_input/providers/voice_input_storage_provider.dart';
import 'environment_switcher_section.dart';

class ClearAppDataSection extends ConsumerStatefulWidget {
  const ClearAppDataSection({super.key});

  @override
  ConsumerState<ClearAppDataSection> createState() =>
      _ClearAppDataSectionState();
}

class _ClearAppDataSectionState extends ConsumerState<ClearAppDataSection> {
  static const _revealThreshold = 7;

  int _tapCount = 0;
  bool _revealed = false;
  bool _clearing = false;
  String? _version;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = '${info.version} (${info.buildNumber})';
      });
    }
  }

  void _handleVersionTap() {
    if (_revealed) return;
    _tapCount++;
    if (_tapCount >= _revealThreshold) {
      setState(() => _revealed = true);
    }
  }

  Future<void> _handleClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all app data?'),
        content: const Text(
          'This will permanently remove all settings, API keys, '
          'conversations, memory, reminders, and Notion connections. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _clearing = true);

    try {
      await _clearAllData(ref);

      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Data cleared'),
            content: const Text(
              'All app data has been removed. Settings and conversations '
              'are now empty.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _clearing = false;
          _revealed = false;
          _tapCount = 0;
        });
      }
    }
  }

  Future<void> _clearAllData(WidgetRef ref) async {
    await ref.read(aiProviderStorageProvider).clearConfig();
    await ref.read(voiceInputStorageProvider).clear();

    final notionStorage = NotionStorage(
      secureStorage: ref.read(flutterSecureStorageProvider),
      sharedPrefs: ref.read(sharedPrefsProvider),
    );
    await notionStorage.clearTokens();
    await notionStorage.saveEnabled(false);
    await notionStorage.saveEnabledTools(null);

    await NotionRecentPagesStorage(
      sharedPrefs: ref.read(sharedPrefsProvider),
    ).clear();

    await ref.read(systemPromptStorageProvider).clearPrompt();
    await ref.read(builtinToolsStorageProvider).clear();

    await ref.read(notificationsServiceProvider).cancelAll();
    await ReminderStorage(sharedPrefs: ref.read(sharedPrefsProvider)).clear();

    await ref.read(memoryStorageProvider).clear();

    final appDir = appDirInstance;
    if (appDir != null) {
      final conversationsDir = Directory('${appDir.path}/conversations');
      if (conversationsDir.existsSync()) {
        await conversationsDir.delete(recursive: true);
      }
    }

    final sharedPrefs = ref.read(sharedPrefsProvider);
    await sharedPrefs.remove('install_sent');
    await sharedPrefs.remove('onboarding_completed');
    await ref.read(flutterSecureStorageProvider).delete(key: 'installation_id');

    ref.invalidate(aiProviderProvider);
    ref.invalidate(voiceInputProvider);
    ref.invalidate(notionConnectionProvider);
    ref.invalidate(systemPromptProvider);
    ref.invalidate(builtinToolsProvider);
    ref.invalidate(conversationsProvider);
    ref.invalidate(memoryProvider);
    ref.invalidate(notificationsProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aiProviderProvider.notifier).init();
      ref.read(voiceInputProvider.notifier).init();
      ref.read(notionConnectionProvider.notifier).init();
      ref.read(systemPromptProvider.notifier).init();
      ref.read(builtinToolsProvider.notifier).init();
      ref.read(conversationsProvider.notifier).init();
      ref.read(memoryProvider.notifier).init();
      () async {
        await ref.read(notificationsProvider.notifier).init();
      }();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = theme.brightness;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_version != null)
          GestureDetector(
            onTap: _handleVersionTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.space4,
                bottom: AppSpacing.space1,
              ),
              child: Center(
                child: Text(
                  'Version $_version',
                  style: AppFonts.labelSmall().copyWith(
                    color: AppColors.textTertiary(b),
                  ),
                ),
              ),
            ),
          ),
        if (_revealed) ...[
          const SizedBox(height: AppSpacing.space3),
          const EnvironmentSwitcherSection(),
          const SizedBox(height: AppSpacing.space3),
          _DangerZoneCard(clearing: _clearing, onClear: _handleClear),
        ],
      ],
    );
  }
}

class _DangerZoneCard extends StatefulWidget {
  const _DangerZoneCard({required this.clearing, required this.onClear});

  final bool clearing;
  final VoidCallback onClear;

  @override
  State<_DangerZoneCard> createState() => _DangerZoneCardState();
}

class _DangerZoneCardState extends State<_DangerZoneCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = theme.brightness;
    final bg = _hovered
        ? AppColors.error.withValues(alpha: 0.06)
        : Colors.transparent;

    return Material(
      color: AppColors.surfaceCard(theme.brightness),
      shape: AppShapes.lg(
        side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: bg,
          child: InkWell(
            onTap: widget.clearing ? null : widget.onClear,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space4,
                vertical: AppSpacing.space3,
              ),
              child: Row(
                children: [
                  Material(
                    color: AppColors.error.withValues(alpha: 0.10),
                    shape: AppShapes.md(),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.space2 - 2),
                      child: Icon(
                        Icons.delete_forever_outlined,
                        size: 18,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Clear all app data',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Remove all settings, conversations, memory, '
                          'and connections.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textTertiary(b),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  if (widget.clearing)
                    SizedBox(
                      width: AppIconSize.md,
                      height: AppIconSize.md,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.error,
                      ),
                    )
                  else
                    Icon(
                      Icons.chevron_right,
                      size: AppIconSize.lg,
                      color: AppColors.error,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
