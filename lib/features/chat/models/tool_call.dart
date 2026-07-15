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
      final length = argumentsRaw.length;
      const maxFragment = 200;
      String fragment;
      if (length <= maxFragment * 2) {
        fragment = argumentsRaw;
      } else {
        fragment =
            '${argumentsRaw.substring(0, maxFragment)} ... '
            '${argumentsRaw.substring(length - maxFragment)}';
      }
      arguments = <String, dynamic>{
        '_parseError': true,
        'length': length,
        'fragment': fragment,
      };
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
