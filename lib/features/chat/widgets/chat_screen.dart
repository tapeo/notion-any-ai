// Full-screen chat: frosted app bar, scrollable messages and frosted input bar.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  bool _drawerOpen = false;

  @override
  void dispose() {
    _inputBarHeight.dispose();
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
          ValueListenableBuilder<double>(
            valueListenable: _inputBarHeight,
            builder: (context, height, _) {
              return MessageList(bottomInset: height);
            },
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
          if (_drawerOpen)
            Positioned.fill(child: ConversationsDrawer(onClose: _closeDrawer)),
        ],
      ),
    );
  }
}
