// Immutable state of the chat feature: messages list and sending flag.
import 'package:equatable/equatable.dart';

import '../../notion/models/notion_page_ref.dart';
import '../models/chat_error.dart';
import '../models/chat_message.dart';

class ChatState extends Equatable {
  const ChatState({
    this.messages = const [],
    this.isSending = false,
    this.selectedPages = const [],
    this.error,
  });

  final List<ChatMessage> messages;
  final bool isSending;
  final List<NotionPageRef> selectedPages;
  final ChatError? error;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isSending,
    List<NotionPageRef>? selectedPages,
    ChatError? error,
    bool clearSelectedPages = false,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      selectedPages: clearSelectedPages
          ? const []
          : selectedPages ?? this.selectedPages,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [messages, isSending, selectedPages, error];
}
