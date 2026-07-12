import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_fonts.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/widgets/frosted_icon_button.dart';
import '../../settings/widgets/settings_body.dart';
import '../providers/notifications_provider.dart';

class NotificationsSetup extends ConsumerWidget {
  const NotificationsSetup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);
    final theme = Theme.of(context);
    final reminders = state.reminders;

    return SettingsBody(
      title: 'Reminders',
      icon: Icons.notifications_active_outlined,
      description:
          'Local push notifications scheduled by the assistant '
          'from Notion due dates. Fires at the scheduled time on '
          'iOS, Android, macOS, Windows, and Linux (while the '
          'app is running).',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Scheduled (${reminders.length})'.toUpperCase(),
                style: AppFonts.microUpper().copyWith(
                  color: AppColors.textTertiary(theme.brightness),
                ),
              ),
              if (reminders.isNotEmpty)
                TextButton(
                  onPressed: state.saving ? null : () => notifier.removeAll(),
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space1,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Clear all',
                    style: AppFonts.labelMedium(),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.space1),
          if (reminders.isEmpty)
            Text(
              'No scheduled reminders. Ask the assistant in chat to set one, '
              'e.g. "Remind me to review the roadmap on 2026-07-10 at 9am".',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary(theme.brightness),
              ),
            )
          else
            ...reminders.map(
              (reminder) => _ReminderRow(
                title: reminder.title,
                body: reminder.body,
                notionPageUrl: reminder.notionPageUrl,
                scheduledAt: reminder.scheduledAt,
                saving: state.saving,
                onCancel: () => notifier.remove(reminder.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({
    required this.title,
    required this.scheduledAt,
    required this.saving,
    required this.onCancel,
    this.body,
    this.notionPageUrl,
  });

  final String title;
  final String? body;
  final String? notionPageUrl;
  final DateTime scheduledAt;
  final bool saving;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final local = scheduledAt.toLocal();
    final formatted =
        '${_weekdayName(local.weekday)}, ${local.day} ${_monthName(local.month)} '
        '${local.year} ${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (body != null && body!.isNotEmpty)
                  Text(
                    body!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary(theme.brightness),
                    ),
                  ),
                Text(
                  formatted,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary(theme.brightness),
                  ),
                ),
                if (notionPageUrl != null && notionPageUrl!.isNotEmpty)
                  Text(
                    notionPageUrl!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.accent,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          FrostedIconButton(
            onPressed: saving ? null : onCancel,
            icon: Icons.close,
            tooltip: 'Cancel reminder',
            iconSize: AppIconSize.md,
          ),
        ],
      ),
    );
  }

  String _weekdayName(int weekday) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[weekday - 1];
  }

  String _monthName(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[month - 1];
  }
}
