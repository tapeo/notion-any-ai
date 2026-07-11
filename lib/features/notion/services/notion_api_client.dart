import 'dart:convert';

import 'package:http/http.dart' as http;

const _backendUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'http://localhost:3000',
);

class NotionApiClient {
  NotionApiClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  bool get isInitialized => true;

  void reset() {}

  Future<NotionSelfInfo?> fetchSelf(String accessToken) async {
    final res = await _httpClient.get(
      Uri.parse('$_backendUrl/api/notion/self'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (res.statusCode < 200 || res.statusCode >= 300) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return NotionSelfInfo(
      workspaceId: data['workspace_id'] as String?,
      workspaceName: data['workspace_name'] as String?,
      userName: data['user_name'] as String?,
    );
  }

  Future<NotionToolResult> callTool({
    required String accessToken,
    required String name,
    required Map<String, dynamic> arguments,
  }) async {
    try {
      final res = await _httpClient.post(
        Uri.parse('$_backendUrl/api/notion/tool'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'access_token': accessToken,
          'name': name,
          'arguments': arguments,
        }),
      );
      if (res.statusCode < 200 || res.statusCode >= 300) {
        return NotionToolResult(
          content: 'Backend error (${res.statusCode}): ${res.body}',
          isError: true,
        );
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return NotionToolResult(
        content: data['content'] as String? ?? '',
        isError: data['is_error'] as bool? ?? false,
      );
    } catch (err) {
      return NotionToolResult(content: 'Tool error: $err', isError: true);
    }
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