// Full-screen chat: frosted app bar, scrollable messages and frosted input bar.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/widgets/frosted_app_bar.dart';
import '../../../app/widgets/frosted_icon_button.dart';
import '../../../app/widgets/measure_size.dart';
import '../../conversations/widgets/conversations_drawer.dart';
import '../../settings/widgets/settings_screen.dart';
import '../providers/chat_provider.dart';
import 'chat_input_bar.dart';
import 'message_list.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ValueNotifier<double> _inputBarHeight = ValueNotifier<double>(0.0);
  final ValueNotifier<double> _scrollPixels = ValueNotifier<double>(0.0);
  final ValueNotifier<double> _maxScrollExtent = ValueNotifier<double>(0.0);
  bool _drawerOpen = false;

  @override
  void dispose() {
    _inputBarHeight.dispose();
    _scrollPixels.dispose();
    _maxScrollExtent.dispose();
    super.dispose();
  }

  void _openSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  void _startNewChat() {
    ref.read(chatProvider.notifier).clearChat();
  }

  void _toggleDrawer() {
    setState(() {
      _drawerOpen = !_drawerOpen;
    });
  }

  void _closeDrawer() {
    setState(() {
      _drawerOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasMessages = ref.watch(
      chatProvider.select((s) => s.messages.isNotEmpty),
    );
    final brightness = Theme.of(context).brightness;
    final fadeColor = AppColors.bgSecondary(brightness);
    const fadeHeight = 48.0;
    final topInset =
        MediaQuery.paddingOf(context).top + kToolbarHeight;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: FrostedAppBar(
        title: 'Any AI for Notion',
        leading: FrostedIconButton(
          onPressed: _toggleDrawer,
          icon: Icons.menu,
          tooltip: 'Conversations',
        ),
        actions: [
          FrostedIconButton(
            onPressed: hasMessages ? _startNewChat : null,
            icon: Icons.add,
            tooltip: 'New chat',
          ),
          FrostedIconButton(
            onPressed: _openSettings,
            icon: Icons.settings_outlined,
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              final metrics = notification.metrics;
              _scrollPixels.value = metrics.pixels;
              _maxScrollExtent.value = metrics.maxScrollExtent;
              return false;
            },
            child: ValueListenableBuilder<double>(
              valueListenable: _inputBarHeight,
              builder: (context, height, _) {
                return MessageList(
                  topInset: topInset,
                  bottomInset: height,
                );
              },
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: topInset,
            height: fadeHeight,
            child: IgnorePointer(
              child: ValueListenableBuilder<double>(
                valueListenable: _scrollPixels,
                builder: (context, pixels, _) {
                  final opacity = (pixels / fadeHeight).clamp(0.0, 1.0);
                  return Opacity(
                    opacity: opacity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            fadeColor,
                            fadeColor.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FrostedBottomBar(
              child: MeasureSize(
                onHeightChanged: (h) => _inputBarHeight.value = h,
                child: const ChatInputBar(),
              ),
            ),
          ),
          ValueListenableBuilder<double>(
            valueListenable: _inputBarHeight,
            builder: (context, height, _) {
              return Positioned(
                left: 0,
                right: 0,
                bottom: height,
                height: fadeHeight,
                child: IgnorePointer(
                  child: ValueListenableBuilder<double>(
                    valueListenable: _scrollPixels,
                    builder: (context, pixels, _) {
                      return ValueListenableBuilder<double>(
                        valueListenable: _maxScrollExtent,
                        builder: (context, maxExtent, _) {
                          final distance = maxExtent - pixels;
                          final opacity =
                              (distance / fadeHeight).clamp(0.0, 1.0);
                          return Opacity(
                            opacity: opacity,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    fadeColor.withValues(alpha: 0.0),
                                    fadeColor,
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              );
            },
          ),
          if (_drawerOpen)
            Positioned.fill(child: ConversationsDrawer(onClose: _closeDrawer)),
        ],
      ),
    );
  }
}
