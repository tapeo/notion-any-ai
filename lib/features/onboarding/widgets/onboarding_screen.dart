import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_fonts.dart';
import '../../../app/theme/app_shapes.dart';
import '../../../app/theme/app_spacing.dart';
import '../../ai_provider/providers/ai_provider_notifier.dart';
import '../../ai_provider/widgets/ai_provider_form.dart';
import '../../notion/providers/notion_connection_notifier.dart';
import '../../notion/services/notion_connect_helper.dart';
import '../../notion/states/notion_connection_state.dart';

const _kOnboardingCompletedKey = 'onboarding_completed';
const _kPrivacyPolicyUrl =
    'https://raw.githubusercontent.com/tapeo/notion-any-ai/refs/heads/main/assets/privacy-policy.md';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _ProgressDots(currentPage: _currentPage, totalPages: 3),
            Expanded(child: _buildPage(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(BuildContext context) {
    switch (_currentPage) {
      case 0:
        return _ConsentPage(
          onAgree: _nextPage,
          onDecline: _showDeclineDialog,
        );
      case 1:
        return _ProviderSetupPage(
          onSave: _nextPage,
          onSkip: _nextPage,
        );
      case 2:
        return _NotionSetupPage(
          onComplete: _finish,
          onSkip: _finish,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _nextPage() {
    setState(() {
      _currentPage++;
    });
  }

  void _finish() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool(_kOnboardingCompletedKey, true);
    });
    widget.onComplete();
  }

  void _showDeclineDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Consent required'),
        content: const Text(
          'You must agree to the privacy terms to use this app.',
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
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({
    required this.currentPage,
    required this.totalPages,
  });

  final int currentPage;
  final int totalPages;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.space3,
        bottom: AppSpacing.space2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalPages, (i) {
          final active = i == currentPage;
          final done = i < currentPage;
          final color = active
              ? AppColors.accent
              : done
                  ? AppColors.accent.withValues(alpha: 0.4)
                  : AppColors.borderDefault(brightness);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }
}

Widget onboardingActionBar({required List<Widget> children}) {
  return Builder(
    builder: (context) {
      final brightness = Theme.of(context).brightness;
      final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
      return Material(
        color: AppColors.bgPrimary(brightness),
        shape: Border(
          top: BorderSide(color: AppColors.borderSubtle(brightness)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.space6,
            AppSpacing.space3,
            AppSpacing.space6,
            AppSpacing.space4 + bottomInset,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      );
    },
  );
}

class _ConsentPage extends StatelessWidget {
  const _ConsentPage({required this.onAgree, required this.onDecline});

  final VoidCallback onAgree;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space6,
              vertical: AppSpacing.space4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.space4),
                Center(
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: Image.asset('assets/macos.png'),
                  ),
                ),
                const SizedBox(height: AppSpacing.space3),
                Center(
                  child: Text(
                    'Any AI for Notion',
                    style: AppFonts.headlineMedium().copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                Center(
                  child: Text(
                    'Not affiliated with Notion.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary(brightness),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space6),
                Text(
                  'Your data and privacy',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  'When you chat, the following data is sent to the AI provider you configure:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary(brightness),
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                const _BulletPoint(
                    text: 'Your messages and conversation history'),
                const _BulletPoint(
                    text:
                        'Notion page content (when the assistant calls Notion tools)'),
                const _BulletPoint(text: 'Persistent memory content'),
                const _BulletPoint(text: 'Your system prompt'),
                const SizedBox(height: AppSpacing.space4),
                Text(
                  'Where it\'s sent',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  'To the AI provider you configure (OpenAI, OpenRouter, a local server, etc.). Data is sent via HTTPS to the endpoint URL you enter in the next step.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary(brightness),
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                Text(
                  'Notion',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  'Your Notion workspace is accessed via OAuth. The app only sees what you authorize.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary(brightness),
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                Center(
                  child: TextButton(
                    onPressed: () => _openPrivacyPolicy(context),
                    child: const Text('Privacy policy'),
                  ),
                ),
              ],
            ),
          ),
        ),
        onboardingActionBar(
          children: [
            FilledButton(
              onPressed: onAgree,
              child: const Text('I understand and agree'),
            ),
            const SizedBox(height: AppSpacing.space2),
            OutlinedButton(
              onPressed: onDecline,
              child: const Text('Decline'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    final uri = Uri.parse(_kPrivacyPolicyUrl);
    await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  }
}

class _BulletPoint extends StatelessWidget {
  const _BulletPoint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary(brightness),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary(brightness),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderSetupPage extends ConsumerStatefulWidget {
  const _ProviderSetupPage({required this.onSave, required this.onSkip});

  final VoidCallback onSave;
  final VoidCallback onSkip;

  @override
  ConsumerState<_ProviderSetupPage> createState() => _ProviderSetupPageState();
}

class _ProviderSetupPageState extends ConsumerState<_ProviderSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _endpointController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _modelController = TextEditingController();

  bool _obscureApiKey = true;
  bool _initialized = false;

  @override
  void dispose() {
    _endpointController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final state = ref.watch(aiProviderProvider);

    if (!_initialized) {
      _initialized = true;
      _endpointController.text = state.endpoint;
      _modelController.text = state.model;
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space6,
              vertical: AppSpacing.space4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.space4),
                Text(
                  'Configure your AI provider',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  'Enter your AI provider details. You can get an API key from your provider\'s dashboard (OpenAI, OpenRouter, etc.). You can change this later in Settings.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary(brightness),
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                AiProviderForm(
                  formKey: _formKey,
                  endpointController: _endpointController,
                  apiKeyController: _apiKeyController,
                  modelController: _modelController,
                  obscureApiKey: _obscureApiKey,
                  onToggleObscure: () => setState(() {
                    _obscureApiKey = !_obscureApiKey;
                  }),
                  hasApiKey: state.hasApiKey,
                  saving: state.saving,
                  onSave: _handleSave,
                  showSaveButton: false,
                ),
              ],
            ),
          ),
        ),
        onboardingActionBar(
          children: [
            FilledButton(
              onPressed: state.saving ? null : _handleSave,
              child: const Text('Save and continue'),
            ),
            const SizedBox(height: AppSpacing.space2),
            Center(
              child: TextButton(
                onPressed: widget.onSkip,
                child: const Text('Skip for now'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    final apiKey = _apiKeyController.text.trim();
    await ref
        .read(aiProviderProvider.notifier)
        .save(
          endpoint: _endpointController.text,
          model: _modelController.text,
          apiKey: apiKey.isEmpty ? null : apiKey,
        );
    if (!mounted) return;
    widget.onSave();
  }
}

class _NotionSetupPage extends ConsumerWidget {
  const _NotionSetupPage({required this.onComplete, required this.onSkip});

  final VoidCallback onComplete;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final state = ref.watch(notionConnectionProvider);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space6,
              vertical: AppSpacing.space4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.space4),
                Text(
                  'Connect Notion',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  'Connect your Notion workspace so the assistant can read and write your pages. You\'ll authorize access via Notion\'s consent screen.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary(brightness),
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                if (state.connected) ...[
                  _ConnectedCard(state: state),
                ],
              ],
            ),
          ),
        ),
        onboardingActionBar(
          children: [
            if (state.connected) ...[
              FilledButton(
                onPressed: onComplete,
                child: const Text('Continue'),
              ),
            ] else ...[
              FilledButton.icon(
                onPressed: state.connecting
                    ? null
                    : () => connectNotion(context, ref),
                icon: state.connecting
                    ? const SizedBox(
                        width: AppIconSize.md,
                        height: AppIconSize.md,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.link_outlined, size: AppIconSize.md),
                label: Text(
                    state.connecting ? 'Redirecting...' : 'Connect Notion'),
              ),
            ],
            const SizedBox(height: AppSpacing.space2),
            Center(
              child: TextButton(
                onPressed: onSkip,
                child: const Text('Skip for now'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ConnectedCard extends StatelessWidget {
  const _ConnectedCard({required this.state});

  final NotionConnectionState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
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
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.success),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.workspaceName ?? 'Notion',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Connected',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary(theme.brightness),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}