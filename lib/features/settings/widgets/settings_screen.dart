import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_shapes.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/widgets/frosted_app_bar.dart';
import '../../../app/widgets/frosted_icon_button.dart';
import '../../ai_provider/widgets/ai_provider_setup.dart';
import '../../builtin_tools/widgets/builtin_tools_setup.dart';
import '../../memory/widgets/memory_setup.dart';
import '../../notifications/widgets/notifications_setup.dart';
import '../../notion/services/notion_platform.dart';
import '../../notion/widgets/notion_setup.dart';
import '../../system_prompt/widgets/system_prompt_setup.dart';
import '../../voice_input/widgets/voice_input_setup.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _sections = <SettingsSection>[
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
      icon: Icons.link_outlined,
      label: 'Notion',
      description:
          'Connect your Notion workspace so the assistant can search, read, and update your Notion pages from the chat.',
      screen: NotionSetup(),
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
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SettingsSectionGroup(sections: _sections),
                const SizedBox(height: AppSpacing.space4),
                const _LegalSectionGroup(),
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

class _SettingsSectionGroup extends StatelessWidget {
  const _SettingsSectionGroup({required this.sections});

  final List<SettingsSection> sections;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      shape: AppShapes.lg(
        side: BorderSide(color: AppColors.borderSubtle(theme.brightness)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < sections.length; i++) ...[
            _SettingsSectionTile(section: sections[i]),
            if (i < sections.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                color: AppColors.borderSubtle(theme.brightness),
              ),
          ],
        ],
      ),
    );
  }
}

class _SettingsSectionTile extends StatefulWidget {
  const _SettingsSectionTile({required this.section});

  final SettingsSection section;

  @override
  State<_SettingsSectionTile> createState() => _SettingsSectionTileState();
}

class _SettingsSectionTileState extends State<_SettingsSectionTile> {
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
      child: Material(
        color: bg,
        child: InkWell(
          onTap: () => _open(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space4,
              vertical: AppSpacing.space3,
            ),
            child: Row(
              children: [
                Material(
                  color: AppColors.accent.withValues(alpha: 0.10),
                  shape: AppShapes.md(),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.space2 - 2),
                    child: Icon(
                      widget.section.icon,
                      size: 18,
                      color: AppColors.accent,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Text(
                    widget.section.label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space2),
                Icon(
                  Icons.chevron_right,
                  size: AppIconSize.lg,
                  color: AppColors.textTertiary(b),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => widget.section.screen));
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

class _LegalSectionGroup extends StatelessWidget {
  const _LegalSectionGroup();

  static const _links = <_LegalLink>[
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
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      shape: AppShapes.lg(
        side: BorderSide(color: AppColors.borderSubtle(theme.brightness)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < _links.length; i++) ...[
            _LegalTile(link: _links[i]),
            if (i < _links.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                color: AppColors.borderSubtle(theme.brightness),
              ),
          ],
        ],
      ),
    );
  }
}

class _LegalTile extends StatefulWidget {
  const _LegalTile({required this.link});

  final _LegalLink link;

  @override
  State<_LegalTile> createState() => _LegalTileState();
}

class _LegalTileState extends State<_LegalTile> {
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
      child: Material(
        color: bg,
        child: InkWell(
          onTap: () => _launchUrlInBrowser(context, widget.link.url),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space4,
              vertical: AppSpacing.space3,
            ),
            child: Row(
              children: [
                Material(
                  color: AppColors.accent.withValues(alpha: 0.10),
                  shape: AppShapes.md(),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.space2 - 2),
                    child: Icon(
                      widget.link.icon,
                      size: 18,
                      color: AppColors.accent,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Text(
                    widget.link.label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space2),
                Icon(
                  Icons.open_in_new,
                  size: AppIconSize.lg,
                  color: AppColors.textTertiary(b),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
