import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/services/backend_env_provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_fonts.dart';
import '../../../app/theme/app_shapes.dart';
import '../../../app/theme/app_spacing.dart';
import '../../notion/providers/notion_connection_notifier.dart';

class EnvironmentSwitcherSection extends ConsumerStatefulWidget {
  const EnvironmentSwitcherSection({super.key});

  @override
  ConsumerState<EnvironmentSwitcherSection> createState() =>
      _EnvironmentSwitcherSectionState();
}

class _EnvironmentSwitcherSectionState
    extends ConsumerState<EnvironmentSwitcherSection> {
  bool _hovered = false;

  Future<void> _switchTo(BackendEnv env) async {
    final current = ref.read(backendEnvProvider);
    if (env == current) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Switch backend environment?'),
        content: Text(
          'Switching to ${env.label} will disconnect Notion. '
          'You will need to reconnect after the change. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Switch'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(notionConnectionProvider.notifier).disconnect();
    await ref.read(backendEnvProvider.notifier).setEnv(env);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Environment changed. Reconnect Notion to continue.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = theme.brightness;
    final env = ref.watch(backendEnvProvider);
    final bg = _hovered
        ? AppColors.hoverFillFor(b)
        : Colors.transparent;

    return Material(
      color: AppColors.surfaceCard(b),
      shape: AppShapes.lg(
        side: BorderSide(color: AppColors.borderSubtle(b)),
      ),
      clipBehavior: Clip.antiAlias,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: bg,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space4,
              vertical: AppSpacing.space3,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Material(
                      color: AppColors.accent.withValues(alpha: 0.10),
                      shape: AppShapes.md(),
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.space2 - 2),
                        child: Icon(
                          Icons.dns_outlined,
                          size: 18,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space3),
                    Expanded(
                      child: Text(
                        'Backend environment',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  'Switch between local and production backend. '
                  'Notion will disconnect on change.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary(b),
                  ),
                ),
                const SizedBox(height: AppSpacing.space3),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<BackendEnv>(
                    segments: const [
                      ButtonSegment(
                        value: BackendEnv.local,
                        label: Text('Local'),
                        icon: Icon(Icons.computer_outlined, size: 16),
                      ),
                      ButtonSegment(
                        value: BackendEnv.production,
                        label: Text('Production'),
                        icon: Icon(Icons.cloud_outlined, size: 16),
                      ),
                    ],
                    selected: {env},
                    onSelectionChanged: (selection) {
                      if (selection.isNotEmpty) _switchTo(selection.first);
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  env.url,
                  style: AppFonts.labelSmall().copyWith(
                    color: AppColors.textTertiary(b),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}