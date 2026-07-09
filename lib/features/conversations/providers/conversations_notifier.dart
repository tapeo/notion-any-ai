import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notion_any_ai/features/conversations/services/conversation_storage.dart';

import '../../chat/models/chat_message.dart';
import '../models/conversation.dart';
import '../states/conversations_state.dart';
import 'conversation_storage_provider.dart';

class ConversationsNotifier extends Notifier<ConversationsState> {
  late ConversationStorage _storage;

  @override
  ConversationsState build() {
    _storage = ref.watch(conversationStorageProvider);
    return const ConversationsState();
  }

  void init() {
    state = state.copyWith(isLoading: true);
    final summaries = _storage.loadIndex();
    state = state.copyWith(summaries: summaries, isLoading: false);
  }

  void startNew() {
    state = state.copyWith(clearActiveId: true);
  }

  void open(String id) {
    state = state.copyWith(activeId: id);
  }

  Future<void> create({
    required String id,
    required String title,
    required DateTime createdAt,
  }) async {
    final conversation = Conversation(
      id: id,
      title: title,
      createdAt: createdAt,
      updatedAt: createdAt,
      messages: const [],
    );
    await _storage.saveConversation(conversation);
    state = state.copyWith(
      summaries: [conversation.toSummary(), ...state.summaries],
      activeId: id,
    );
  }

  Future<void> persistMessages(
    String id,
    List<ChatMessage> messages, {
    required DateTime updatedAt,
  }) async {
    final existing = _storage.loadConversation(id);
    if (existing == null) return;
    final updated = existing.copyWith(messages: messages, updatedAt: updatedAt);
    await _storage.saveConversation(updated);
    state = state.copyWith(
      summaries: state.summaries.map((s) {
        if (s.id != id) return s;
        return updated.toSummary();
      }).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
    );
  }

  Future<void> rename(String id, String title) async {
    final existing = _storage.loadConversation(id);
    if (existing == null) return;
    final updated = existing.copyWith(title: title);
    await _storage.saveConversation(updated);
    state = state.copyWith(
      summaries: state.summaries.map((s) {
        if (s.id != id) return s;
        return s.copyWith(title: title);
      }).toList(),
    );
  }

  Future<void> delete(String id) async {
    await _storage.deleteConversation(id);
    state = state.copyWith(
      summaries: state.summaries.where((s) => s.id != id).toList(),
      activeId: state.activeId == id ? null : state.activeId,
    );
  }
}

final conversationsProvider =
    NotifierProvider<ConversationsNotifier, ConversationsState>(
      ConversationsNotifier.new,
    );
