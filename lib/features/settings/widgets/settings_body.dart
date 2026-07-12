import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/widgets/frosted_app_bar.dart';
import '../../../app/widgets/frosted_icon_button.dart';

class SettingsBody extends StatelessWidget {
  const SettingsBody({
    super.key,
    required this.title,
    required this.icon,
    required this.description,
    required this.child,
  });

  final String title;
  final IconData icon;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FrostedAppBar(
        title: title,
        leading: FrostedIconButton(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: AppSpacing.space3,
          left: AppSpacing.space4,
          right: AppSpacing.space4,
          bottom: AppSpacing.space4,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.settingsWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: AppColors.accent),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary(
                          Theme.of(context).brightness,
                        ),
                      ),
                ),
                const SizedBox(height: AppSpacing.space5),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
