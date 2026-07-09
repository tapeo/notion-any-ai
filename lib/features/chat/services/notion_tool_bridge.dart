// Maps Notion MCP tools to OpenAI tool schemas and executes tool calls.
import '../../notion/models/notion_tool_meta.dart';
import '../../notion/services/notion_mcp_client.dart';
import '../models/tool_call.dart';

class NotionToolBridge {
  NotionToolBridge({
    required NotionMcpClient mcpClient,
    required String accessToken,
    required List<NotionToolMeta> availableTools,
  })  : _mcp = mcpClient,
        _accessToken = accessToken,
        _availableTools = availableTools;

  final NotionMcpClient _mcp;
  final String _accessToken;
  final List<NotionToolMeta> _availableTools;

  List<Map<String, dynamic>> buildTools({
    required List<NotionToolMeta> available,
    required List<String> enabled,
  }) {
    final enabledSet = Set<String>.from(enabled);
    return available
        .where((t) => enabledSet.contains(t.name))
        .map((t) => _toOpenAiTool(t))
        .toList();
  }

  List<String> _missingRequiredParams(NotionToolMeta tool, Map<String, dynamic> args) {
    final schema = tool.parameters;
    final required = schema['required'];
    if (required is! List) return const [];
    return required
        .where((r) => r is String && !args.containsKey(r))
        .cast<String>()
        .toList();
  }

  Map<String, dynamic> _toOpenAiTool(NotionToolMeta tool) {
    return {
      'type': 'function',
      'function': {
        'name': tool.name,
        'description': tool.description,
        'parameters': tool.parameters,
      },
    };
  }

  Future<String> execute(ToolCall call) async {
    try {
      final tool = _availableTools.firstWhere(
        (t) => t.name == call.name,
        orElse: () => NotionToolMeta(
          name: call.name,
          description: call.name,
          parameters: const {},
        ),
      );
      final missing = _missingRequiredParams(tool, call.arguments);
      if (missing.isNotEmpty) {
        return 'Tool error: Missing required parameter${missing.length > 1 ? 's' : ''} '
            '${missing.map((m) => "'$m'").join(', ')} for ${call.name}. '
            'Provide the missing parameter${missing.length > 1 ? 's' : ''} and retry.';
      }
      final result = await _mcp.callTool(
        accessToken: _accessToken,
        name: call.name,
        arguments: call.arguments,
      );
      if (result.isError) {
        return 'Tool error: ${result.content}';
      }
      return result.content;
    } catch (err) {
      return 'Tool error: $err';
    }
  }
}