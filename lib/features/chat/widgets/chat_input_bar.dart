// Input bar with multiline text field and send button.
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_shapes.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/widgets/frosted_icon_button.dart';
import '../../notion/widgets/notion_page_picker_sheet.dart';
import '../../voice_input/providers/voice_input_notifier.dart';
import '../../voice_input/services/voice_recorder.dart';
import '../../voice_input/widgets/voice_input_setup.dart';
import '../providers/chat_provider.dart';
import 'chat_page_selector_row.dart';

class ChatInputBar extends ConsumerStatefulWidget {
  const ChatInputBar({super.key});

  @override
  ConsumerState<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends ConsumerState<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final VoiceRecorder _recorder = VoiceRecorder();
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _focusNode.onKeyEvent = _onKeyEvent;
    _recorder.isRecordingNotifier.addListener(_onRecordingChanged);
  }

  @override
  void dispose() {
    _recorder.isRecordingNotifier.removeListener(_onRecordingChanged);
    _controller.dispose();
    _focusNode.dispose();
    _recorder.dispose();
    super.dispose();
  }

  void _onRecordingChanged() {
    setState(() {});
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
      final shift = HardwareKeyboard.instance.isShiftPressed;
      if (!shift) {
        _send();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  void _onChanged(String value) {
    final next = value.trim().isNotEmpty;
    if (next != _canSend) {
      setState(() => _canSend = next);
    }
  }

  Future<void> _send() async {
    if (ref.read(chatProvider).isSending) {
      return;
    }
    final text = _controller.text;
    if (text.trim().isEmpty) {
      return;
    }
    await HapticFeedback.selectionClick();
    _controller.clear();
    _focusNode.requestFocus();
    setState(() => _canSend = false);
    await ref.read(chatProvider.notifier).sendMessage(text);
  }

  Future<void> _openPagePicker() async {
    await HapticFeedback.selectionClick();
    final alreadySelected = ref
        .read(chatProvider)
        .selectedPages
        .map((p) => p.id)
        .toList();

    if (!mounted) return;

    final page = await showNotionPagePickerSheet(
      context,
      ref: ref,
      alreadySelected: alreadySelected,
    );
    if (page != null) {
      ref.read(chatProvider.notifier).selectPage(page);
    }
  }

  void _showSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _startRecording() async {
    final voiceState = ref.read(voiceInputProvider);
    if (!voiceState.isConfigured) {
      _showSnackbar('Configure voice input in Settings first.');
      return;
    }

    final granted = await _recorder.requestPermission();
    if (!granted) {
      _showPermissionDeniedSnackbar();
      return;
    }

    final started = await _recorder.start();
    if (!started) {
      _showSnackbar(
        'Recording unavailable. On Linux, install pulseaudio-utils and ffmpeg.',
      );
    }
  }

  void _showPermissionDeniedSnackbar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text(
            'Microphone permission is required for voice input.',
          ),
          action: SnackBarAction(
            label: 'Open Settings',
            onPressed: _openMicrophoneSettings,
          ),
        ),
      );
  }

  Future<void> _openMicrophoneSettings() async {
    if (kIsWeb) return;
    final Uri uri;
    if (Platform.isMacOS) {
      uri = Uri(
        scheme: 'x-apple.systempreferences',
        host: 'com.apple.preference.security',
        path: 'Privacy_Microphone',
      );
    } else if (Platform.isIOS) {
      uri = Uri.parse('app-settings:');
    } else {
      return;
    }

    try {
      await launchUrl(uri);
    } catch (_) {}
  }

  Future<void> _stopRecordingAndTranscribe() async {
    String? path;
    try {
      path = await _recorder.stop();
    } catch (e) {
      _showSnackbar('Failed to stop recording: ${e.toString()}');
      return;
    }

    if (path == null) {
      _showSnackbar(
        'Recording did not complete. Grant microphone permission and '
        'try again.',
      );
      return;
    }

    try {
      final text = await ref.read(voiceInputProvider.notifier).transcribe(path);
      if (!mounted) return;
      final existing = _controller.text;
      final merged = existing.isEmpty ? text : '$existing $text';
      _controller.text = merged;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
      _onChanged(merged);
      _focusNode.requestFocus();
    } catch (e) {
      _showSnackbar('Transcription failed: ${e.toString()}');
    }
  }

  Future<void> _cancelRecording() async {
    await _recorder.cancel();
  }

  Future<void> _showNotConfiguredDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Voice input not configured'),
        content: const Text(
          'To use voice input, add your OpenAI API key and a transcription '
          'model (e.g. whisper-1) in Settings > Voice input.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _openVoiceInputSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _openVoiceInputSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const VoiceInputSetup()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final chatState = ref.watch(chatProvider);
    final isSending = chatState.isSending;
    final selectedPages = chatState.selectedPages;
    final voiceState = ref.watch(voiceInputProvider);
    final canRecord = voiceState.isConfigured && !voiceState.isTranscribing;

    final barColor = AppColors.bgPrimary(
      isDark ? Brightness.dark : Brightness.light,
    );
    final borderColor = AppColors.borderDefault(
      isDark ? Brightness.dark : Brightness.light,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space3,
        AppSpacing.space2,
        AppSpacing.space3,
        AppSpacing.space3,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.space1),
                ChatPageSelectorRow(
                  selectedPages: selectedPages,
                  onAttach: _openPagePicker,
                  onRemovePage: (page) =>
                      ref.read(chatProvider.notifier).removePage(page),
                ),
                const SizedBox(height: AppSpacing.space2),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Material(
                  color: barColor,
                  shape: AppShapes.superellipse(
                    AppRadius.xxl,
                    side: BorderSide(color: borderColor),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space4,
                      vertical: AppSpacing.space1,
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      minLines: 1,
                      maxLines: 6,
                      onChanged: _onChanged,
                      style: theme.textTheme.bodyMedium,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: 'Type here...',
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textTertiary(theme.brightness),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.space1,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              _MicButton(
                isRecording: _recorder.isRecording,
                isTranscribing: voiceState.isTranscribing,
                enabled: canRecord,
                onPress: _startRecording,
                onRelease: _stopRecordingAndTranscribe,
                onCancel: _cancelRecording,
                onDisabledTap: _showNotConfiguredDialog,
              ),
              const SizedBox(width: AppSpacing.space2),
              if (isSending)
                _StopButton(
                  onPressed: () {
                    ref.read(chatProvider.notifier).stopStreaming();
                  },
                )
              else
                _SendButton(enabled: _canSend, onPressed: _send),
            ],
          ),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final iconColor = enabled
        ? AppColors.white
        : AppColors.textTertiary(brightness);
    final bgColor = enabled
        ? AppColors.accent
        : AppColors.subtleFillFor(brightness);

    return FrostedIconButton(
      icon: Icons.arrow_upward_rounded,
      onPressed: enabled ? onPressed : null,
      diameter: 32,
      iconSize: 18,
      iconColor: iconColor,
      solidColor: bgColor,
    );
  }
}

class _StopButton extends StatelessWidget {
  const _StopButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bgColor = AppColors.hoverFillFor(brightness);
    final iconColor = AppColors.textSecondary(brightness);

    return FrostedIconButton(
      icon: Icons.stop_rounded,
      onPressed: onPressed,
      diameter: 32,
      iconSize: 16,
      iconColor: iconColor,
      solidColor: bgColor,
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({
    required this.isRecording,
    required this.isTranscribing,
    required this.enabled,
    required this.onPress,
    required this.onRelease,
    required this.onCancel,
    required this.onDisabledTap,
  });

  final bool isRecording;
  final bool isTranscribing;
  final bool enabled;
  final Future<void> Function() onPress;
  final Future<void> Function() onRelease;
  final Future<void> Function() onCancel;
  final Future<void> Function() onDisabledTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final showSpinner = isTranscribing;
    final active = enabled || isTranscribing;

    final iconColor = !active
        ? AppColors.textDisabled(brightness)
        : (isRecording ? AppColors.white : AppColors.textSecondary(brightness));
    final bgColor = !active
        ? AppColors.subtleFillFor(brightness)
        : isRecording
        ? AppColors.error
        : isTranscribing
        ? AppColors.accent
        : AppColors.bgTertiary(brightness);

    final core = SizedBox(
      width: 32,
      height: 32,
      child: Material(
        color: bgColor,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: Center(
          child: showSpinner
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.white,
                  ),
                )
              : Icon(
                  isRecording ? Icons.mic_rounded : Icons.mic_none_rounded,
                  size: 18,
                  color: iconColor,
                ),
        ),
      ),
    );

    if (!active) {
      return Tooltip(
        message: 'Voice input not configured',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onDisabledTap(),
          child: core,
        ),
      );
    }

    return Tooltip(
      message: isRecording ? 'Release to transcribe' : 'Hold to record',
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => onPress(),
        onPointerUp: (_) => onRelease(),
        onPointerCancel: (_) => onCancel(),
        child: core,
      ),
    );
  }
}
