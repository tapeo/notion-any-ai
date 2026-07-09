import 'package:equatable/equatable.dart';

import '../models/notion_tool_meta.dart';

class NotionConnectionState extends Equatable {
  const NotionConnectionState({
    this.connected = false,
    this.workspaceName,
    this.enabled = false,
    this.tools = const [],
    this.enabledTools,
    this.toolsLoading = false,
    this.toolsError,
    this.connecting = false,
    this.disconnecting = false,
    this.saving = false,
    this.businessPlanPrompt,
  });

  final bool connected;
  final String? workspaceName;
  final bool enabled;
  final List<NotionToolMeta> tools;
  final List<String>? enabledTools;
  final bool toolsLoading;
  final String? toolsError;
  final bool connecting;
  final bool disconnecting;
  final bool saving;
  final int? businessPlanPrompt;

  NotionConnectionState copyWith({
    bool? connected,
    String? workspaceName,
    bool? enabled,
    List<NotionToolMeta>? tools,
    List<String>? enabledTools,
    bool? toolsLoading,
    String? toolsError,
    bool? connecting,
    bool? disconnecting,
    bool? saving,
    int? businessPlanPrompt,
  }) {
    return NotionConnectionState(
      connected: connected ?? this.connected,
      workspaceName: workspaceName ?? this.workspaceName,
      enabled: enabled ?? this.enabled,
      tools: tools ?? this.tools,
      enabledTools: enabledTools ?? this.enabledTools,
      toolsLoading: toolsLoading ?? this.toolsLoading,
      toolsError: toolsError ?? this.toolsError,
      connecting: connecting ?? this.connecting,
      disconnecting: disconnecting ?? this.disconnecting,
      saving: saving ?? this.saving,
      businessPlanPrompt: businessPlanPrompt ?? this.businessPlanPrompt,
    );
  }

  @override
  List<Object?> get props => [
    connected,
    workspaceName,
    enabled,
    tools,
    enabledTools,
    toolsLoading,
    toolsError,
    connecting,
    disconnecting,
    saving,
    businessPlanPrompt,
  ];
}