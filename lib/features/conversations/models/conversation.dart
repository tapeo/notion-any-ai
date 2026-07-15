import 'package:equatable/equatable.dart';

import '../../chat/models/chat_message.dart';
import '../../chat/models/chat_role.dart';

class ConversationSummary extends Equatable {
  const ConversationSummary({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messageCount,
    required this.lastPreview,
    this.totalTokens = 0,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;
  final String lastPreview;
  final int totalTokens;

  ConversationSummary copyWith({
    String? title,
    DateTime? updatedAt,
    int? messageCount,
    String? lastPreview,
    int? totalTokens,
  }) {
    return ConversationSummary(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messageCount: messageCount ?? this.messageCount,
      lastPreview: lastPreview ?? this.lastPreview,
      totalTokens: totalTokens ?? this.totalTokens,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'message_count': messageCount,
      'last_preview': lastPreview,
      'total_tokens': totalTokens,
    };
  }

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    return ConversationSummary(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      messageCount: (json['message_count'] as num).toInt(),
      lastPreview: (json['last_preview'] as String?) ?? '',
      totalTokens: (json['total_tokens'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    createdAt,
    updatedAt,
    messageCount,
    lastPreview,
    totalTokens,
  ];
}

class Conversation extends Equatable {
  const Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessage> messages;

  ConversationSummary toSummary() {
    final lastPreview = _lastUserPreview();
    final totalTokens = messages
        .where(
          (m) => m.role == ChatRole.assistant && m.usage?.totalTokens != null,
        )
        .fold(0, (sum, m) => sum + m.usage!.totalTokens!);
    return ConversationSummary(
      id: id,
      title: title,
      createdAt: createdAt,
      updatedAt: updatedAt,
      messageCount: messages.length,
      lastPreview: lastPreview,
      totalTokens: totalTokens,
    );
  }

  String _lastUserPreview() {
    for (var i = messages.length - 1; i >= 0; i--) {
      final msg = messages[i];
      if (msg.role == ChatRole.user && msg.content != null) {
        final content = msg.content!.trim();
        return content.length > 80 ? '${content.substring(0, 80)}...' : content;
      }
    }
    return '';
  }

  Conversation copyWith({
    String? title,
    DateTime? updatedAt,
    List<ChatMessage>? messages,
  }) {
    return Conversation(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
    );
  }

  String toMarkdown() {
    final buffer = StringBuffer('# $title\n');
    for (final msg in messages) {
      switch (msg.role) {
        case ChatRole.system:
          continue;
        case ChatRole.user:
          buffer.write('\n## You\n\n');
          buffer.write('${msg.content ?? ''}\n');
        case ChatRole.assistant:
          buffer.write('\n## Assistant\n\n');
          if (msg.content != null && msg.content!.isNotEmpty) {
            buffer.write('${msg.content}\n');
          }
        case ChatRole.tool:
          final name = msg.name ?? 'tool';
          buffer.write('\n## Tool: $name\n\n');
          final content = msg.content ?? '';
          buffer.write(
            content.length > 2000
                ? '${content.substring(0, 2000)}...\n'
                : '$content\n',
          );
      }
    }
    return buffer.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'messages': messages.map((m) => m.toJson()).toList(),
    };
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      messages: (json['messages'] as List<dynamic>)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [id, title, createdAt, updatedAt, messages];
}
