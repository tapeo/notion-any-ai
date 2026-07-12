import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_fonts.dart';
import '../../../app/theme/app_shapes.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/widgets/frosted_app_bar.dart';
import '../../../app/widgets/frosted_icon_button.dart';
import '../../ai_provider/widgets/ai_provider_setup.dart';
import '../../builtin_tools/widgets/builtin_tools_setup.dart';
import '../../feedback/widgets/feedback_dialog.dart';
import '../../memory/widgets/memory_setup.dart';
import '../../notifications/widgets/notifications_setup.dart';
import '../../notion/services/notion_platform.dart';
import '../../notion/widgets/notion_setup.dart';
import '../../system_prompt/widgets/system_prompt_setup.dart';
import '../../voice_input/widgets/voice_input_setup.dart';
import 'clear_app_data_section.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _sections = <SettingsSection>[
    SettingsSection(
      icon: Icons.link_outlined,
      label: 'Notion',
      description:
          'Connect your Notion workspace so the assistant can search, read, and update your Notion pages from the chat.',
      screen: NotionSetup(),
    ),
    SettingsSection(
      icon: Icons.smart_toy_outlined,
      label: 'AI Provider',
      description:
          'Configure a custom OpenAI-compatible provider with endpoint, API key, and model. Used by the chat assistant to generate replies.',
      screen: AiProviderSetup(),
    ),
    SettingsSection(
      icon: Icons.mic_outlined,
      label: 'Voice input',
      description:
          'Configure a Whisper-compatible transcription provider with '
          'an API key and model. Press and hold the microphone button in '
          'the chat input bar to dictate a message.',
      screen: VoiceInputSetup(),
    ),
    SettingsSection(
      icon: Icons.edit_note_outlined,
      label: 'System prompt',
      description:
          'Customize the instructions sent at the start of every '
          'conversation to control how the assistant behaves.',
      screen: SystemPromptSetup(),
    ),
    SettingsSection(
      icon: Icons.bolt_outlined,
      label: 'Built-in tools',
      description:
          'Enable or disable local tool functions the assistant '
          'can call during chat, such as getting the current date '
          'and time. These do not require a Notion connection.',
      screen: BuiltinToolsSetup(),
    ),
    SettingsSection(
      icon: Icons.psychology_outlined,
      label: 'Memory',
      description:
          'Shared persistent memory the assistant reads and '
          'updates via tools. The full content is injected into '
          'every conversation. Edit it here or let the assistant '
          'add, search, and delete sections on its own.',
      screen: MemorySetup(),
    ),
    SettingsSection(
      icon: Icons.notifications_active_outlined,
      label: 'Reminders',
      description:
          'Local push notifications scheduled by the assistant '
          'from Notion due dates. Fires at the scheduled time on '
          'iOS, Android, macOS, Windows, and Linux (while the '
          'app is running).',
      screen: NotificationsSetup(),
    ),
  ];

  static const _legalLinks = <_LegalLink>[
    _LegalLink(
      icon: Icons.description_outlined,
      label: 'Terms of Service',
      url:
          'https://raw.githubusercontent.com/tapeo/notion-any-ai/refs/heads/main/assets/terms-of-service.md',
    ),
    _LegalLink(
      icon: Icons.privacy_tip_outlined,
      label: 'Privacy Policy',
      url:
          'https://raw.githubusercontent.com/tapeo/notion-any-ai/refs/heads/main/assets/privacy-policy.md',
    ),
    _LegalLink(
      icon: Icons.code_outlined,
      label: 'Open source - leave a Star',
      url: 'https://github.com/tapeo/notion-any-ai',
    ),
    _LegalLink(
      icon: Icons.dns_outlined,
      label: 'Backend open source',
      url: 'https://github.com/tapeo/notion-any-ai-backend',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: FrostedAppBar(
        title: 'Settings',
        leading: FrostedIconButton(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: topInset + AppSpacing.space3,
          left: AppSpacing.space0,
          right: AppSpacing.space0,
          bottom: AppSpacing.space4,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.settingsWidth,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _GroupLabel('General'),
                for (final section in _sections) ...[
                  _MinimalTile(
                    icon: section.icon,
                    label: section.label,
                    onTap: () => Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (_) => section.screen)),
                  ),
                  const SizedBox(height: AppSpacing.space1),
                ],
                const SizedBox(height: AppSpacing.space3),
                const _GroupLabel('Feedback'),
                _MinimalTile(
                  icon: Icons.feedback_outlined,
                  label: 'Leave feedback',
                  onTap: () => showFeedbackDialog(context),
                ),
                const SizedBox(height: AppSpacing.space3),
                const _GroupLabel('Legal'),
                for (final link in _legalLinks) ...[
                  _MinimalTile(
                    icon: link.icon,
                    label: link.label,
                    trailing: Icons.open_in_new,
                    onTap: () => _launchUrlInBrowser(context, link.url),
                  ),
                  const SizedBox(height: AppSpacing.space1),
                ],
                const SizedBox(height: AppSpacing.space4),
                const ClearAppDataSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsSection {
  const SettingsSection({
    required this.icon,
    required this.label,
    required this.description,
    required this.screen,
  });

  final IconData icon;
  final String label;
  final String description;
  final Widget screen;
}

class _LegalLink {
  const _LegalLink({
    required this.icon,
    required this.label,
    required this.url,
  });

  final IconData icon;
  final String label;
  final String url;
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space4,
        AppSpacing.space3,
        AppSpacing.space4,
        AppSpacing.space2,
      ),
      child: Text(
        text,
        style: AppFonts.microUpper().copyWith(color: AppColors.textTertiary(b)),
      ),
    );
  }
}

class _MinimalTile extends StatefulWidget {
  const _MinimalTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing = Icons.chevron_right,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final IconData trailing;

  @override
  State<_MinimalTile> createState() => _MinimalTileState();
}

class _MinimalTileState extends State<_MinimalTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = theme.brightness;
    final bg = _hovered ? AppColors.hoverFillFor(b) : Colors.transparent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space2,
        ),
        child: Material(
          color: bg,
          shape: AppShapes.sm(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
                vertical: AppSpacing.space2,
              ),
              child: Row(
                children: [
                  Icon(widget.icon, size: 18, color: AppColors.accent),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Icon(
                    widget.trailing,
                    size: AppIconSize.lg,
                    color: AppColors.textTertiary(b),
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

Future<void> _launchUrlInBrowser(BuildContext context, String url) async {
  final mode = isDesktopPlatform
      ? LaunchMode.externalApplication
      : LaunchMode.inAppBrowserView;
  final uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: mode) && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Could not open link.')));
  }
}
