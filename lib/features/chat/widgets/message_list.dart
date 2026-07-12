// Scrollable list of messages with auto-scroll to bottom on changes.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../conversations/providers/conversations_notifier.dart';
import '../models/chat_role.dart';
import '../providers/chat_provider.dart';
import 'empty_chat_state.dart';
import 'message_bubble.dart';

class MessageList extends ConsumerStatefulWidget {
  const MessageList({super.key, this.bottomInset = 0.0});

  final double bottomInset;

  @override
  ConsumerState<MessageList> createState() => _MessageListState();
}

class _MessageListState extends ConsumerState<MessageList> {
  final ScrollController _controller = ScrollController();
  static const double _bottomThreshold = 80.0;
  bool _autoScrollEnabled = true;
  String? _lastActiveId;
  String? _lastMessageId;
  int _lastLastMessageLength = 0;
  final Set<String> _seenIds = <String>{};

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleScroll);
    _controller.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_controller.hasClients) {
      return;
    }
    final position = _controller.position;
    final isAtBottom =
        position.pixels >= position.maxScrollExtent - _bottomThreshold;
    if (isAtBottom != _autoScrollEnabled) {
      setState(() {
        _autoScrollEnabled = isAtBottom;
      });
    }
  }

  void _jumpToBottom({bool instant = false}) {
    if (!_autoScrollEnabled || !_controller.hasClients) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_controller.hasClients) {
        return;
      }
      if (instant) {
        _controller.jumpTo(_controller.position.maxScrollExtent);
        return;
      }
      _controller.animateTo(
        _controller.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatProvider);
    final messages = chat.messages;

    final bottomInset = widget.bottomInset;

    if (messages.isEmpty) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (_) => FocusScope.of(context).unfocus(),
        onPanDown: (_) => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            SizedBox(height: AppSpacing.space4),
            Expanded(child: const EmptyChatState()),
            SizedBox(height: bottomInset + AppSpacing.space6),
          ],
        ),
      );
    }

    final activeId = ref.watch(conversationsProvider.select((s) => s.activeId));
    final lastMessage = messages.last;
    final lastMessageId = lastMessage.id;
    final lastMessageLength = lastMessage.content?.length ?? 0;
    final activeChanged = activeId != _lastActiveId;

    if (activeChanged) {
      final unseenCount = messages
          .where((m) => !_seenIds.contains(m.id))
          .length;
      if (unseenCount > 1) {
        _seenIds
          ..clear()
          ..addAll(messages.map((m) => m.id));
      }
    }
    final newIds = <String>{};
    for (final m in messages) {
      if (!_seenIds.contains(m.id)) {
        newIds.add(m.id);
        _seenIds.add(m.id);
      }
    }

    final lastMessageChanged =
        lastMessageId != _lastMessageId ||
        lastMessageLength != _lastLastMessageLength;
    _lastActiveId = activeId;
    _lastMessageId = lastMessageId;
    _lastLastMessageLength = lastMessageLength;

    if (activeChanged) {
      _autoScrollEnabled = true;
      _jumpToBottom(instant: true);
    } else if (lastMessageChanged) {
      _jumpToBottom();
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => FocusScope.of(context).unfocus(),
      onPanDown: (_) => FocusScope.of(context).unfocus(),
      child: ListView.builder(
        controller: _controller,
        padding: EdgeInsets.only(
          top: AppSpacing.space1,
          bottom: bottomInset + AppSpacing.space6,
        ),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          final playEntrance =
              message.role == ChatRole.user && newIds.contains(message.id);
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == messages.length - 1
                  ? AppSpacing.space2
                  : AppSpacing.space1,
            ),
            child: MessageBubble(
              message: message,
              allMessages: messages,
              playEntrance: playEntrance,
            ),
          );
        },
      ),
    );
  }
}
