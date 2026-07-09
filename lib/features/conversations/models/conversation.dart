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
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;
  final String lastPreview;

  ConversationSummary copyWith({
    String? title,
    DateTime? updatedAt,
    int? messageCount,
    String? lastPreview,
  }) {
    return ConversationSummary(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messageCount: messageCount ?? this.messageCount,
      lastPreview: lastPreview ?? this.lastPreview,
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
    );
  }

  @override
  List<Object?> get props =>
      [id, title, createdAt, updatedAt, messageCount, lastPreview];
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
    return ConversationSummary(
      id: id,
      title: title,
      createdAt: createdAt,
      updatedAt: updatedAt,
      messageCount: messages.length,
      lastPreview: lastPreview,
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