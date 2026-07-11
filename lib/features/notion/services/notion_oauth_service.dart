import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/notion_tokens.dart';

class NotionOAuthError implements Exception {
  NotionOAuthError(this.message, [this.code]);

  final String message;
  final String? code;

  @override
  String toString() =>
      'NotionOAuthError: $message${code != null ? ' ($code)' : ''}';
}

const _backendUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'http://localhost:3000',
);

const _refreshSkewMs = 60 * 1000;

class NotionOAuthService {
  NotionOAuthService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<NotionStartResult> start() async {
    final res = await _httpClient.post(
      Uri.parse('$_backendUrl/api/notion-oauth/start'),
      headers: {'Content-Type': 'application/json'},
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw NotionOAuthError('Failed to start OAuth flow: ${res.statusCode}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final authorizationUrl = data['authorization_url'];
    if (authorizationUrl is! String || authorizationUrl.isEmpty) {
      throw NotionOAuthError(
        'OAuth start response missing authorization_url: ${res.body}',
      );
    }
    return NotionStartResult(authorizationUrl: authorizationUrl);
  }

  NotionTokens parseCallbackTokens(Map<String, String> params) {
    final error = params['error'];
    if (error != null) {
      final message = params['message'] ?? error;
      throw NotionOAuthError(message, error);
    }
    final accessToken = params['access_token'];
    if (accessToken == null || accessToken.isEmpty) {
      throw NotionOAuthError('Missing access_token in callback');
    }
    final refreshToken = params['refresh_token'] ?? '';
    final expiresAt = int.tryParse(params['access_token_expires_at'] ?? '') ??
        DateTime.now().millisecondsSinceEpoch + 3600 * 1000;
    final connectedAt = int.tryParse(params['connected_at'] ?? '') ??
        DateTime.now().millisecondsSinceEpoch;
    return NotionTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      accessTokenExpiresAt: expiresAt,
      workspaceId: _nullable(params['workspace_id']),
      workspaceName: _nullable(params['workspace_name']),
      userName: _nullable(params['user_name']),
      botId: _nullable(params['bot_id']),
      connectedAt: connectedAt,
    );
  }

  Future<NotionTokens> refreshAccessToken(NotionTokens tokens) async {
    final res = await _httpClient.post(
      Uri.parse('$_backendUrl/api/notion-oauth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': tokens.refreshToken}),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      String? code;
      try {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        code = data['code'] as String?;
      } catch (_) {}
      if (code == 'reauth_required') {
        throw NotionOAuthError('Re-authentication required', 'reauth_required');
      }
      throw NotionOAuthError(
        'Token refresh failed: ${res.statusCode} ${res.body}',
        code,
      );
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return NotionTokens(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String? ?? tokens.refreshToken,
      accessTokenExpiresAt:
          data['access_token_expires_at'] as int? ??
          DateTime.now().millisecondsSinceEpoch + 3600 * 1000,
      workspaceId: data['workspace_id'] as String? ?? tokens.workspaceId,
      workspaceName: data['workspace_name'] as String? ?? tokens.workspaceName,
      userName: data['user_name'] as String? ?? tokens.userName,
      botId: data['bot_id'] as String? ?? tokens.botId,
      connectedAt: data['connected_at'] as int? ?? tokens.connectedAt,
    );
  }

  Future<NotionTokens> ensureValidToken(NotionTokens tokens) async {
    if (DateTime.now().millisecondsSinceEpoch <
        tokens.accessTokenExpiresAt - _refreshSkewMs) {
      return tokens;
    }
    return refreshAccessToken(tokens);
  }

  void close() {
    _httpClient.close();
  }
}

String? _nullable(String? value) {
  if (value == null || value.isEmpty) return null;
  return value;
}

class NotionStartResult {
  const NotionStartResult({required this.authorizationUrl});

  final String authorizationUrl;
}