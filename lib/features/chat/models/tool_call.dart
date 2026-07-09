// Single tool call requested by the assistant in a chat completion.
import 'dart:convert';

import 'package:equatable/equatable.dart';

class ToolCall extends Equatable {
  const ToolCall({
    required this.id,
    required this.name,
    required this.arguments,
  });

  final String id;
  final String name;
  final Map<String, dynamic> arguments;

  factory ToolCall.fromJson(Map<String, dynamic> json) {
    final function = json['function'] as Map<String, dynamic>?;
    final argumentsRaw = function?['arguments'] as String? ?? '{}';
    Map<String, dynamic> arguments;
    try {
      arguments = jsonDecode(argumentsRaw) as Map<String, dynamic>;
    } catch (_) {
      arguments = <String, dynamic>{};
    }
    return ToolCall(
      id: json['id'] as String? ?? '',
      name: function?['name'] as String? ?? '',
      arguments: arguments,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': 'function',
    'function': {'name': name, 'arguments': jsonEncode(arguments)},
  };

  @override
  List<Object?> get props => [id, name, arguments];
}
