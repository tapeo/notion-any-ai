import 'package:equatable/equatable.dart';

import '../models/conversation.dart';

class ConversationsState extends Equatable {
  const ConversationsState({
    this.summaries = const [],
    this.activeId,
    this.isLoading = false,
  });

  final List<ConversationSummary> summaries;
  final String? activeId;
  final bool isLoading;

  ConversationsState copyWith({
    List<ConversationSummary>? summaries,
    String? activeId,
    bool? isLoading,
    bool clearActiveId = false,
  }) {
    return ConversationsState(
      summaries: summaries ?? this.summaries,
      activeId: clearActiveId ? null : activeId ?? this.activeId,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [summaries, activeId, isLoading];
}
