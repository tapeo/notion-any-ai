import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../models/notion_tokens.dart';
import 'notion_platform.dart';

class NotionOAuthError implements Exception {
  NotionOAuthError(this.message, [this.code]);

  final String message;
  final String? code;

  @override
  String toString() =>
      'NotionOAuthError: $message${code != null ? ' ($code)' : ''}';
}

const _notionMcpBase = 'https://mcp.notion.com';

class _OAuthMetadata {
  const _OAuthMetadata({
    required this.authorizationEndpoint,
    required this.tokenEndpoint,
    this.registrationEndpoint,
  });

  final String authorizationEndpoint;
  final String tokenEndpoint;
  final String? registrationEndpoint;
}

class _RegisteredClient {
  const _RegisteredClient({required this.clientId, this.clientSecret});

  final String clientId;
  final String? clientSecret;
}

class _TokenResponse {
  const _TokenResponse({
    required this.accessToken,
    this.refreshToken,
    this.expiresIn,
  });

  final String accessToken;
  final String? refreshToken;
  final int? expiresIn;
}

const String _mobileRedirectUri = 'notionopenai://oauth/callback';
const _pendingMaxMs = 10 * 60 * 1000;
const _refreshSkewMs = 60 * 1000;

String get defaultRedirectUri =>
    isDesktopPlatform ? 'http://localhost:0/callback' : _mobileRedirectUri;

class NotionOAuthService {
  NotionOAuthService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  _OAuthMetadata? _cachedMetadata;
  int _metadataFetchedAt = 0;
  static const _metadataTtlMs = 24 * 60 * 60 * 1000;

  Future<_OAuthMetadata> _fetchMetadata() async {
    if (_cachedMetadata != null &&
        DateTime.now().millisecondsSinceEpoch - _metadataFetchedAt <
            _metadataTtlMs) {
      return _cachedMetadata!;
    }

    final resourceRes = await _httpClient.get(
      Uri.parse('$_notionMcpBase/.well-known/oauth-protected-resource'),
    );
    if (!resourceRes.statusCode.toString().startsWith('2')) {
      throw NotionOAuthError(
        'Protected resource metadata fetch failed: ${resourceRes.statusCode}',
      );
    }
    final resource = jsonDecode(resourceRes.body) as Map<String, dynamic>;
    final authServers = resource['authorization_servers'];
    if (authServers is! List || authServers.isEmpty) {
      throw NotionOAuthError(
        'No authorization servers advertised by Notion MCP',
      );
    }
    final authServerUrl = authServers[0] as String;

    final metaRes = await _httpClient.get(
      Uri.parse('$authServerUrl/.well-known/oauth-authorization-server'),
    );
    if (!metaRes.statusCode.toString().startsWith('2')) {
      throw NotionOAuthError(
        'Authorization server metadata fetch failed: ${metaRes.statusCode}',
      );
    }
    final meta = jsonDecode(metaRes.body) as Map<String, dynamic>;
    final authorizationEndpoint = meta['authorization_endpoint'] as String?;
    final tokenEndpoint = meta['token_endpoint'] as String?;
    if (authorizationEndpoint == null || tokenEndpoint == null) {
      throw NotionOAuthError(
        'Notion OAuth metadata missing required endpoints',
      );
    }

    _cachedMetadata = _OAuthMetadata(
      authorizationEndpoint: authorizationEndpoint,
      tokenEndpoint: tokenEndpoint,
      registrationEndpoint: meta['registration_endpoint'] as String?,
    );
    _metadataFetchedAt = DateTime.now().millisecondsSinceEpoch;
    return _cachedMetadata!;
  }

  Future<_RegisteredClient> _registerClient(
    _OAuthMetadata metadata,
    String redirectUri,
  ) async {
    if (metadata.registrationEndpoint == null) {
      throw NotionOAuthError(
        'Notion OAuth server does not advertise dynamic client registration',
      );
    }
    final res = await _httpClient.post(
      Uri.parse(metadata.registrationEndpoint!),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'client_name': 'Any AI for Notion',
        'client_uri': 'https://notionopenai.local',
        'redirect_uris': [redirectUri],
        'grant_types': ['authorization_code', 'refresh_token'],
        'response_types': ['code'],
        'token_endpoint_auth_method': 'none',
      }),
    );
    if (!res.statusCode.toString().startsWith('2')) {
      throw NotionOAuthError(
        'Dynamic client registration failed: ${res.statusCode} ${res.body}',
      );
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final clientId = data['client_id'] as String?;
    if (clientId == null) {
      throw NotionOAuthError(
        'Dynamic client registration returned no client_id',
      );
    }
    return _RegisteredClient(
      clientId: clientId,
      clientSecret: data['client_secret'] as String?,
    );
  }

  String _base64UrlEncode(List<int> bytes) {
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  String _generateCodeVerifier() {
    final random = Uint8List(32);
    final rng = Random.secure();
    for (var i = 0; i < 32; i++) {
      random[i] = rng.nextInt(256);
    }
    return _base64UrlEncode(random);
  }

  String _generateCodeChallenge(String verifier) {
    final digest = sha256.convert(utf8.encode(verifier));
    return _base64UrlEncode(digest.bytes);
  }

  String _generateState() {
    final random = Uint8List(32);
    final rng = Random.secure();
    for (var i = 0; i < 32; i++) {
      random[i] = rng.nextInt(256);
    }
    return random.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Future<NotionStartResult> start({String? redirectUri}) async {
    final effectiveRedirectUri = redirectUri ?? defaultRedirectUri;
    final metadata = await _fetchMetadata();
    final registered = await _registerClient(metadata, effectiveRedirectUri);
    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _generateCodeChallenge(codeVerifier);
    final state = _generateState();

    final params = <String, String>{
      'response_type': 'code',
      'client_id': registered.clientId,
      'redirect_uri': effectiveRedirectUri,
      'state': state,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
    };
    final authorizationUrl = Uri.parse(
      metadata.authorizationEndpoint,
    ).replace(queryParameters: params).toString();

    final now = DateTime.now().millisecondsSinceEpoch;
    final pending = NotionPendingFlow(
      clientId: registered.clientId,
      clientSecret: registered.clientSecret,
      codeVerifier: codeVerifier,
      state: state,
      redirectUri: effectiveRedirectUri,
      startedAt: now,
      expiresAt: now + _pendingMaxMs,
    );

    return NotionStartResult(
      authorizationUrl: authorizationUrl,
      pending: pending,
    );
  }

  Future<NotionTokens> handleCallback({
    required NotionPendingFlow pending,
    required String code,
  }) async {
    if (pending.isExpired) {
      throw NotionOAuthError('OAuth flow expired, please try again', 'expired');
    }
    final metadata = await _fetchMetadata();
    final tokens = await _exchangeCode(
      metadata: metadata,
      clientId: pending.clientId,
      clientSecret: pending.clientSecret,
      code: code,
      codeVerifier: pending.codeVerifier,
      redirectUri: pending.redirectUri,
    );

    final expiresIn = tokens.expiresIn ?? 3600;
    final now = DateTime.now().millisecondsSinceEpoch;
    return NotionTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken ?? '',
      accessTokenExpiresAt: now + expiresIn * 1000,
      clientId: pending.clientId,
      clientSecret: pending.clientSecret,
      workspaceId: null,
      workspaceName: null,
      userName: null,
      connectedAt: now,
    );
  }

  Future<_TokenResponse> _exchangeCode({
    required _OAuthMetadata metadata,
    required String clientId,
    String? clientSecret,
    required String code,
    required String codeVerifier,
    required String redirectUri,
  }) async {
    final body = <String, String>{
      'grant_type': 'authorization_code',
      'code': code,
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'code_verifier': codeVerifier,
    };
    if (clientSecret != null) {
      body['client_secret'] = clientSecret;
    }
    final res = await _httpClient.post(
      Uri.parse(metadata.tokenEndpoint),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: body,
    );
    if (!res.statusCode.toString().startsWith('2')) {
      throw NotionOAuthError(
        'Token exchange failed: ${res.statusCode} ${res.body}',
      );
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final accessToken = data['access_token'] as String?;
    if (accessToken == null) {
      throw NotionOAuthError('Token response missing access_token');
    }
    return _TokenResponse(
      accessToken: accessToken,
      refreshToken: data['refresh_token'] as String?,
      expiresIn: data['expires_in'] as int?,
    );
  }

  Future<NotionTokens> refreshAccessToken(NotionTokens tokens) async {
    final metadata = await _fetchMetadata();
    final body = <String, String>{
      'grant_type': 'refresh_token',
      'refresh_token': tokens.refreshToken,
      'client_id': tokens.clientId,
    };
    if (tokens.clientSecret != null) {
      body['client_secret'] = tokens.clientSecret!;
    }
    final res = await _httpClient.post(
      Uri.parse(metadata.tokenEndpoint),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: body,
    );
    if (!res.statusCode.toString().startsWith('2')) {
      final errCode = _parseErrorCode(res.body);
      if (errCode == 'invalid_grant') {
        throw NotionOAuthError('Re-authentication required', 'reauth_required');
      }
      throw NotionOAuthError(
        'Token refresh failed: ${res.statusCode} ${res.body}',
        errCode,
      );
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final accessToken = data['access_token'] as String?;
    if (accessToken == null) {
      throw NotionOAuthError('Refresh response missing access_token');
    }
    final expiresIn = data['expires_in'] as int? ?? 3600;
    final now = DateTime.now().millisecondsSinceEpoch;
    return tokens.copyWith(
      accessToken: accessToken,
      refreshToken: data['refresh_token'] as String? ?? tokens.refreshToken,
      accessTokenExpiresAt: now + expiresIn * 1000,
    );
  }

  String? _parseErrorCode(String body) {
    try {
      final parsed = jsonDecode(body) as Map<String, dynamic>;
      return parsed['error'] as String?;
    } catch (_) {
      return null;
    }
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

class NotionStartResult {
  const NotionStartResult({
    required this.authorizationUrl,
    required this.pending,
  });

  final String authorizationUrl;
  final NotionPendingFlow pending;
}
