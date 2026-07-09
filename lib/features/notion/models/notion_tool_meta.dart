import 'package:equatable/equatable.dart';

class NotionToolMeta extends Equatable {
  const NotionToolMeta({
    required this.name,
    required this.description,
    required this.parameters,
  });

  final String name;
  final String description;
  final Map<String, dynamic> parameters;

  factory NotionToolMeta.fromJson(Map<String, dynamic> json) {
    return NotionToolMeta(
      name: json['name'] as String,
      description: json['description'] as String? ?? json['name'] as String,
      parameters: (json['parameters'] as Map<String, dynamic>?) ?? const {},
    );
  }

  @override
  List<Object?> get props => [name, description, parameters];
}

enum NotionToolKind { read, write }

String formatToolName(String name) {
  final base = name.replaceFirst(RegExp(r'^notion_'), '');
  return base
      .replaceAll('_', ' ')
      .replaceAllMapped(RegExp(r'\b\w'), (m) => m[0]!.toUpperCase());
}

NotionToolKind getToolKind(String name) {
  final base = name.replaceFirst(RegExp(r'^notion_'), '');
  if (RegExp(r'^(fetch|search|query|get|list|retrieve|read)').hasMatch(base)) {
    return NotionToolKind.read;
  }
  return NotionToolKind.write;
}

const businessPlanRequiredTools = <String>{
  'notion_query_data_sources',
  'notion_query_database_view',
  'notion_query_meeting_notes',
};

bool requiresBusinessPlan(String name) =>
    businessPlanRequiredTools.contains(name);
