import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/notion_tool_meta.dart';

const _notionMcpUrl = 'https://mcp.notion.com/mcp';

class NotionMcpClient {
  NotionMcpClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;
  String? _initializedWithToken;
  String? _sessionId;
  int _nextRequestId = 100;

  bool get isInitialized => _initializedWithToken != null;

  Future<void> initialize(String accessToken) async {
    if (_initializedWithToken == accessToken && _sessionId != null) {
      return;
    }
    _initializedWithToken = accessToken;
    final res = await _post(accessToken, {
      'jsonrpc': '2.0',
      'id': 1,
      'method': 'initialize',
      'params': {
        'protocolVersion': '2024-11-05',
        'capabilities': {},
        'clientInfo': {'name': 'notion-any-ai', 'version': '1.0.0'},
      },
    });
    final sessionId = res.headers['mcp-session-id'];
    if (sessionId != null) {
      _sessionId = sessionId;
    }
    await _post(accessToken, {
      'jsonrpc': '2.0',
      'id': 2,
      'method': 'notifications/initialized',
    });
  }

  void reset() {
    _initializedWithToken = null;
    _sessionId = null;
  }

  Future<List<NotionToolMeta>> listTools(String accessToken) async {
    await initialize(accessToken);
    final res = await _post(accessToken, {
      'jsonrpc': '2.0',
      'id': 3,
      'method': 'tools/list',
      'params': {},
    });
    final result = _parseResponseBody(res, expectedId: 3);
    final toolsRaw = (result['result']?['tools'] as List?) ?? const [];
    return toolsRaw.map((t) => _mapTool(t as Map<String, dynamic>)).toList();
  }

  NotionToolMeta _mapTool(Map<String, dynamic> tool) {
    final mcpName = tool['name'] as String? ?? '';
    final exposedName = _toExposedName(mcpName);
    final description = tool['description'] as String? ?? exposedName;
    final inputSchema =
        (tool['inputSchema'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};
    return NotionToolMeta(
      name: exposedName,
      description: description,
      parameters: inputSchema,
    );
  }

  String _toExposedName(String mcpName) {
    final underscored = mcpName.replaceAll('-', '_');
    if (underscored.startsWith('notion_')) {
      return underscored;
    }
    return 'notion_$underscored';
  }

  Future<NotionToolResult> callTool({
    required String accessToken,
    required String name,
    required Map<String, dynamic> arguments,
  }) async {
    await initialize(accessToken);
    final id = _nextRequestId++;
    final res = await _post(accessToken, {
      'jsonrpc': '2.0',
      'id': id,
      'method': 'tools/call',
      'params': {'name': _toMcpName(name), 'arguments': arguments},
    });
    final body = _parseResponseBody(res, expectedId: id);
    final result = body['result'] as Map<String, dynamic>?;
    if (result == null) {
      final error = body['error'];
      final message = (error is Map<String, dynamic>)
          ? (error['message'] as String? ?? 'Unknown MCP error')
          : 'Unknown MCP error';
      return NotionToolResult(content: message, isError: true);
    }
    final isError = result['isError'] as bool? ?? false;
    final text = _extractText(result);
    return NotionToolResult(
      content: text.isEmpty ? _encodeContentFallback(result) : text,
      isError: isError,
    );
  }

  String _encodeContentFallback(Map<String, dynamic> result) {
    final content = result['content'];
    if (content == null) return '';
    try {
      return jsonEncode(content);
    } catch (_) {
      return '';
    }
  }

  String _toMcpName(String exposedName) {
    final hyphenated = exposedName.replaceAll('_', '-');
    if (hyphenated.startsWith('notion-')) {
      return hyphenated;
    }
    return 'notion-$hyphenated';
  }

  Future<NotionSelfInfo?> fetchSelf(String accessToken) async {
    await initialize(accessToken);
    final res = await _post(accessToken, {
      'jsonrpc': '2.0',
      'id': 4,
      'method': 'tools/call',
      'params': {
        'name': 'notion-fetch',
        'arguments': {'id': 'self'},
      },
    });
    final body = _parseResponseBody(res, expectedId: 4);
    final result = body['result'] as Map<String, dynamic>?;
    if (result == null) return null;
    final isError = result['isError'] as bool? ?? false;
    if (isError) return null;
    final text = _extractText(result);
    if (text.isEmpty) return null;
    try {
      final parsed = jsonDecode(text) as Map<String, dynamic>;
      final self = parsed['self'] as Map<String, dynamic>?;
      if (self == null) return null;
      final workspace = self['workspace'] as Map<String, dynamic>?;
      final user = self['user'] as Map<String, dynamic>?;
      return NotionSelfInfo(
        workspaceId: workspace?['id'] as String?,
        workspaceName: workspace?['name'] as String?,
        userName: user?['name'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  String _extractText(Map<String, dynamic> result) {
    final content = result['content'];
    if (content is! List) return '';
    for (final block in content) {
      if (block is Map<String, dynamic> && block['type'] == 'text') {
        final text = block['text'];
        if (text is String) return text;
      }
    }
    return '';
  }

  /// Parses an MCP Streamable HTTP response body into a JSON-RPC message map.
  ///
  /// The server may respond with plain JSON (`application/json`) or an SSE
  /// stream (`text/event-stream`) wrapping the JSON-RPC message in
  /// `event: message` / `data:` lines. This normalizes both formats and, when
  /// [expectedId] is provided, returns the JSON-RPC message whose `id` matches
  /// (progress notifications carrying no matching id are skipped).
  ///
  /// Throws [FormatException] if no parseable JSON-RPC response is found.
  Map<String, dynamic> _parseResponseBody(
    http.Response res, {
    int? expectedId,
  }) {
    final body = res.body;
    if (body.isEmpty) return <String, dynamic>{};

    final contentType = res.headers['content-type'] ?? '';
    final isSse =
        contentType.contains('text/event-stream') ||
        body.startsWith('event:') ||
        body.startsWith('data:');

    if (!isSse) {
      return jsonDecode(body) as Map<String, dynamic>;
    }

    final messages = <Map<String, dynamic>>[];
    final dataLines = <String>[];

    void flushEvent() {
      if (dataLines.isEmpty) return;
      final data = dataLines.join('\n');
      dataLines.clear();
      try {
        final decoded = jsonDecode(data) as Map<String, dynamic>;
        messages.add(decoded);
      } catch (_) {
        // ignore non-JSON data lines (e.g. keepalive comments)
      }
    }

    for (final line in body.split('\n')) {
      final trimmed = line.trimRight();
      if (trimmed.isEmpty) {
        flushEvent();
        continue;
      }
      if (trimmed.startsWith('data:')) {
        dataLines.add(trimmed.substring(5).trimLeft());
      } else if (trimmed.startsWith('event:') ||
          trimmed.startsWith(':') ||
          trimmed.startsWith('id:') ||
          trimmed.startsWith('retry:')) {
        // event/id/retry fields do not carry the JSON payload; ignore
        continue;
      } else {
        // unexpected line inside SSE; flush any pending event and try plain JSON
        flushEvent();
        try {
          final decoded = jsonDecode(trimmed) as Map<String, dynamic>;
          messages.add(decoded);
        } catch (_) {
          // ignore
        }
      }
    }
    flushEvent();

    // Prefer the message whose id matches expectedId; otherwise the first
    // JSON-RPC response (has result or error).
    Map<String, dynamic>? match;
    for (final m in messages) {
      if (expectedId != null && m['id'] == expectedId) {
        match = m;
        break;
      }
      if (match == null &&
          (m.containsKey('result') || m.containsKey('error'))) {
        match = m;
      }
    }
    if (match != null) return match;
    if (messages.isNotEmpty) return messages.first;
    throw FormatException('No JSON-RPC message found in SSE response');
  }

  Future<http.Response> _post(
    String accessToken,
    Map<String, dynamic> payload,
  ) async {
    final headers = <String, String>{
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
      'Accept': 'application/json, text/event-stream',
    };
    if (_sessionId != null) {
      headers['Mcp-Session-Id'] = _sessionId!;
    }
    return _httpClient.post(
      Uri.parse(_notionMcpUrl),
      headers: headers,
      body: jsonEncode(payload),
    );
  }

  void close() {
    _httpClient.close();
  }
}

class NotionSelfInfo {
  const NotionSelfInfo({this.workspaceId, this.workspaceName, this.userName});

  final String? workspaceId;
  final String? workspaceName;
  final String? userName;
}

class NotionToolResult {
  const NotionToolResult({required this.content, required this.isError});

  final String content;
  final bool isError;
}
