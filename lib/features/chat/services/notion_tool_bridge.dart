import '../../notion/models/notion_tool_meta.dart';
import '../../notion/services/notion_api_client.dart';
import '../models/tool_call.dart';

class NotionToolBridge {
  NotionToolBridge({
    required NotionApiClient apiClient,
    required this._accessToken,
    required this._availableTools,
  }) : _api = apiClient;

  final NotionApiClient _api;
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

  List<String> _missingRequiredParams(
    NotionToolMeta tool,
    Map<String, dynamic> args,
  ) {
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
      final parseError = call.arguments['_parseError'];
      if (parseError == true) {
        final length = call.arguments['length'];
        final fragment = call.arguments['fragment'];
        return 'Tool error: arguments JSON could not be parsed '
            '(length=$length). The streamed arguments were likely '
            'truncated or malformed. Retry with a simpler structure, '
            'appending one block per call, especially for nested '
            'blocks such as tables and column lists. Fragment: $fragment';
      }
      final missing = _missingRequiredParams(tool, call.arguments);
      if (missing.isNotEmpty) {
        return 'Tool error: Missing required parameter${missing.length > 1 ? 's' : ''} '
            '${missing.map((m) => "'$m'").join(', ')} for ${call.name}. '
            'Provide the missing parameter${missing.length > 1 ? 's' : ''} and retry.';
      }
      final result = await _api.callTool(
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
