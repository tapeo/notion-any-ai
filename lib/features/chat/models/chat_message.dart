// Single chat message with role, content and timestamp.
import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'chat_role.dart';
import 'token_usage.dart';
import 'tool_call.dart';

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.createdAt,
    this.content,
    this.reasoning,
    this.toolCalls,
    this.toolCallId,
    this.name,
    this.usage,
  });

  final String id;
  final ChatRole role;
  final String? content;
  final String? reasoning;
  final List<ToolCall>? toolCalls;
  final String? toolCallId;
  final String? name;
  final DateTime createdAt;
  final TokenUsage? usage;

  ChatMessage copyWith({
    String? content,
    String? reasoning,
    List<ToolCall>? toolCalls,
    TokenUsage? usage,
  }) {
    return ChatMessage(
      id: id,
      role: role,
      content: content ?? this.content,
      reasoning: reasoning ?? this.reasoning,
      toolCalls: toolCalls ?? this.toolCalls,
      toolCallId: toolCallId,
      name: name,
      createdAt: createdAt,
      usage: usage ?? this.usage,
    );
  }

  Map<String, dynamic> toOpenAiJson() {
    final map = <String, dynamic>{'role': role.apiName};
    if (role == ChatRole.tool) {
      map['content'] = content ?? '';
      if (toolCallId != null) map['tool_call_id'] = toolCallId;
      if (name != null) map['name'] = name;
    } else if (role == ChatRole.assistant) {
      if (content != null) map['content'] = content;
      if (toolCalls != null && toolCalls!.isNotEmpty) {
        map['tool_calls'] = toolCalls!.map((t) => t.toJson()).toList();
      }
    } else {
      map['content'] = content ?? '';
    }
    return map;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.name,
      if (content != null) 'content': content,
      if (toolCalls != null && toolCalls!.isNotEmpty)
        'tool_calls': toolCalls!.map((t) => t.toJson()).toList(),
      if (toolCallId != null) 'tool_call_id': toolCallId,
      if (name != null) 'name': name,
      'created_at': createdAt.toUtc().toIso8601String(),
      if (usage != null) 'usage': usage!.toJson(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      role: ChatRole.values.byName(json['role'] as String),
      content: json['content'] as String?,
      toolCalls: (json['tool_calls'] as List<dynamic>?)
          ?.map((e) => ToolCall.fromJson(e as Map<String, dynamic>))
          .toList(),
      toolCallId: json['tool_call_id'] as String?,
      name: json['name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      usage: json['usage'] == null
          ? null
          : TokenUsage.fromJson(json['usage'] as Map<String, dynamic>),
    );
  }

  @override
  List<Object?> get props => [
    id,
    role,
    content,
    reasoning,
    toolCalls,
    toolCallId,
    name,
    createdAt,
    usage,
  ];
}

extension ChatRoleApiName on ChatRole {
  String get apiName {
    switch (this) {
      case ChatRole.system:
        return 'system';
      case ChatRole.user:
        return 'user';
      case ChatRole.assistant:
        return 'assistant';
      case ChatRole.tool:
        return 'tool';
    }
  }
}

String encodeToolResultContent(String text) => text;

String? decodeToolResultContent(dynamic raw) {
  if (raw is String) return raw;
  if (raw == null) return null;
  try {
    return jsonEncode(raw);
  } catch (_) {
    return null;
  }
}
