import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../chat/providers/chat_provider.dart';
import '../models/conversation.dart';
import '../providers/conversation_storage_provider.dart';
import '../providers/conversations_notifier.dart';
import '../services/reveal_in_file_manager.dart';
import 'conversation_tile.dart';

class ConversationsDrawer extends ConsumerStatefulWidget {
  const ConversationsDrawer({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  ConsumerState<ConversationsDrawer> createState() =>
      _ConversationsDrawerState();
}

class _ConversationsDrawerState extends ConsumerState<ConversationsDrawer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slide;
  late final Animation<double> _fade;

  static const double _panelWidth = 280;

  bool get _isDesktop =>
      Platform.isMacOS || Platform.isLinux || Platform.isWindows;

  Future<void> _revealConversation(String id) async {
    final storage = ref.read(conversationStorageProvider);
    await storage.ensureDir();
    final file = storage.conversationFile(id);
    if (file.existsSync()) {
      await revealInFileManager(file);
    }
  }

  Future<void> _copyConversationMarkdown(String id) async {
    final storage = ref.read(conversationStorageProvider);
    final convo = storage.loadConversation(id);
    if (convo == null) return;
    await Clipboard.setData(ClipboardData(text: convo.toMarkdown()));
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _slide = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    FocusManager.instance.primaryFocus?.unfocus();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    await _controller.reverse();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = theme.brightness;
    final panelColor = AppColors.bgSecondary(b);
    final dividerColor = AppColors.borderSubtle(b);

    final conversations = ref.watch(conversationsProvider);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _close,
              child: Container(
                color: Colors.black.withValues(alpha: 0.4 * _fade.value),
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              child: FractionalTranslation(
                translation: Offset(-1 + _slide.value, 0),
                child: Container(
                  width: _panelWidth,
                  decoration: BoxDecoration(
                    color: panelColor,
                    border: Border(
                      right: BorderSide(color: dividerColor, width: 1),
                    ),
                  ),
                  child: SafeArea(
                    right: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: conversations.summaries.isEmpty
                              ? _buildEmpty(theme, b)
                              : _buildList(conversations.summaries),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmpty(ThemeData theme, Brightness b) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space6),
        child: Text(
          'No conversations yet.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textTertiary(b),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildList(List<ConversationSummary> summaries) {
    final activeId = ref.watch(conversationsProvider.select((s) => s.activeId));
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
      itemCount: summaries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 0),
      itemBuilder: (context, index) {
        final summary = summaries[index];
        return ConversationTile(
          summary: summary,
          isActive: summary.id == activeId,
          onTap: () {
            if (summary.id == activeId) {
              ref.read(chatProvider.notifier).reloadActiveConversation();
            } else {
              ref.read(conversationsProvider.notifier).open(summary.id);
            }
            _close();
          },
          onRename: () => _showRenameDialog(summary),
          onDelete: () => _showDeleteDialog(summary),
          onReveal: _isDesktop ? () => _revealConversation(summary.id) : null,
          onCopyMarkdown: () => _copyConversationMarkdown(summary.id),
        );
      },
    );
  }

  Future<void> _showRenameDialog(ConversationSummary summary) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return _RenameDialog(initialTitle: summary.title);
      },
    );
    if (result != null && result.isNotEmpty) {
      await ref.read(conversationsProvider.notifier).rename(summary.id, result);
    }
  }

  Future<void> _showDeleteDialog(ConversationSummary summary) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete conversation?'),
          content: const Text(
            'This conversation will be permanently removed. '
            'This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await ref.read(conversationsProvider.notifier).delete(summary.id);
    }
  }
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initialTitle});

  final String initialTitle;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename conversation'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Title'),
        onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
