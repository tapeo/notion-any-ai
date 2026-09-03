// Scrollable message list, top-anchored. Content growing at the end of the
// list (streaming replies, tool results) never moves the reading position.
// The list follows the newest message only while pinned to the bottom.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../conversations/providers/conversations_notifier.dart';
import '../models/chat_role.dart';
import '../providers/chat_provider.dart';
import '../providers/chat_input_controller.dart';
import 'empty_chat_state.dart';
import 'message_bubble.dart';

class MessageList extends ConsumerStatefulWidget {
  const MessageList({super.key, this.bottomInset = 0.0, this.topInset = 0.0});

  final double bottomInset;
  final double topInset;

  @override
  ConsumerState<MessageList> createState() => _MessageListState();
}

class _MessageListState extends ConsumerState<MessageList> {
  final ScrollController _controller = ScrollController();
  static const double _bottomThreshold = 80.0;
  static const int _settleFrameBudget = 12;

  // The list follows the newest message while pinned. Unpins on the first
  // user scroll away from the bottom; re-pins when the user scrolls back,
  // sends a message, or opens a conversation.
  bool _pinned = true;
  int _settleFramesLeft = 0;
  double _lastSettleExtent = -1;
  String? _lastActiveId;
  final Set<String> _seenIds = <String>{};

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isAtBottom {
    if (!_controller.hasClients) {
      return false;
    }
    final position = _controller.position;
    return position.pixels >= position.maxScrollExtent - _bottomThreshold;
  }

  void _schedulePinSync() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _pinSyncAfterLayout());
  }

  // A lazy list only estimates maxScrollExtent until its items are laid out,
  // so a freshly opened conversation re-pins each frame until the extent is
  // stable or the settle budget runs out.
  void _pinSyncAfterLayout() {
    if (!mounted || !_controller.hasClients) {
      return;
    }
    final position = _controller.position;
    if (position.userScrollDirection != ScrollDirection.idle) {
      return;
    }
    if (_pinned) {
      _controller.jumpTo(position.maxScrollExtent);
    }
    if (_settleFramesLeft > 0) {
      final extent = position.maxScrollExtent;
      if (extent == _lastSettleExtent) {
        _settleFramesLeft = 0;
      } else {
        _lastSettleExtent = extent;
        _settleFramesLeft--;
        _schedulePinSync();
      }
    }
  }

  bool _handleUserScroll(UserScrollNotification notification) {
    if (notification.direction == ScrollDirection.reverse) {
      _settleFramesLeft = 0;
      if (_pinned) {
        setState(() {
          _pinned = false;
        });
      }
      return false;
    }
    if (notification.direction == ScrollDirection.idle) {
      final atBottom = _isAtBottom;
      if (atBottom != _pinned) {
        setState(() {
          _pinned = atBottom;
        });
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatProvider);
    final messages = chat.messages;
    final error = chat.error;

    final bottomInset = widget.bottomInset;
    final topInset = widget.topInset;

    if (messages.isEmpty && error == null) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (_) => FocusScope.of(context).unfocus(),
        onPanDown: (_) => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            SizedBox(height: topInset + AppSpacing.space4),
            Expanded(
              child: EmptyChatState(
                onSuggestion: (prompt) => ref
                    .read(chatInputControllerProvider)
                    .prefill(prompt),
              ),
            ),
            SizedBox(height: bottomInset + AppSpacing.space6),
          ],
        ),
      );
    }

    // Subscribe to view insets so keyboard changes rebuild the list and the
    // pinned sync keeps the newest message visible above the keyboard.
    MediaQuery.viewInsetsOf(context);

    final activeId = ref.watch(conversationsProvider.select((s) => s.activeId));
    final hasError = error != null;
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

    final lastMessage = messages.isNotEmpty ? messages.last : null;
    final userSentNewMessage =
        lastMessage != null &&
        lastMessage.role == ChatRole.user &&
        newIds.contains(lastMessage.id);

    if (activeChanged || userSentNewMessage) {
      _lastActiveId = activeId;
      _pinned = true;
    }
    if (activeChanged) {
      _lastSettleExtent = -1;
      _settleFramesLeft = _settleFrameBudget;
    }
    _schedulePinSync();

    final itemCount = messages.length + (hasError ? 1 : 0);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => FocusScope.of(context).unfocus(),
      onPanDown: (_) => FocusScope.of(context).unfocus(),
      child: NotificationListener<UserScrollNotification>(
        onNotification: _handleUserScroll,
        child: ListView.builder(
          controller: _controller,
          padding: EdgeInsets.only(
            top: topInset + AppSpacing.space1,
            bottom: bottomInset + AppSpacing.space6,
          ),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (index == messages.length) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.space2),
                child: ErrorBubble(error: error!),
              );
            }
            final message = messages[index];
            final playEntrance =
                message.role == ChatRole.user && newIds.contains(message.id);
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == 0 ? AppSpacing.space2 : AppSpacing.space1,
              ),
              child: MessageBubble(
                message: message,
                allMessages: messages,
                playEntrance: playEntrance,
              ),
            );
          },
        ),
      ),
    );
  }
}