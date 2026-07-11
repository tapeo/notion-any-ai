import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/services/backend_env_provider.dart';
import '../../../app/services/secure_storage_provider.dart';
import '../../../app/services/shared_prefs_provider.dart';
import '../models/notion_tokens.dart';
import '../models/notion_tool_meta.dart';
import '../services/notion_api_client.dart';
import '../services/notion_oauth_service.dart';
import '../services/notion_storage.dart';
import '../services/notion_tool_registry.dart';
import '../states/notion_connection_state.dart';

class NotionConnectionNotifier extends Notifier<NotionConnectionState> {
  late final NotionStorage _storage;
  late final NotionOAuthService _oauth;
  late final NotionApiClient _api;

  @override
  NotionConnectionState build() {
    _storage = NotionStorage(
      secureStorage: ref.watch(flutterSecureStorageProvider),
      sharedPrefs: ref.watch(sharedPrefsProvider),
    );
    final backendUrl = ref.watch(backendUrlProvider);
    _oauth = NotionOAuthService(backendUrl: backendUrl);
    _api = ref.watch(notionApiClientProvider);
    final state = NotionConnectionState(
      enabled: _storage.loadEnabled(),
      enabledTools: _storage.loadEnabledTools(),
    );
    return state;
  }

  Future<void> init() async {
    final tokens = await _storage.loadTokens();
    if (tokens == null) {
      return;
    }
    state = state.copyWith(
      connected: true,
      workspaceName: tokens.workspaceName,
    );
    await _loadToolsAndIdentity(tokens);
  }

  Future<String?> connect() async {
    state = state.copyWith(connecting: true);
    try {
      final result = await _oauth.start();
      state = state.copyWith(connecting: false);
      return result.authorizationUrl;
    } catch (_) {
      state = state.copyWith(connecting: false);
      rethrow;
    }
  }

  Future<bool> handleCallbackTokens(NotionTokens tokens) async {
    try {
      await _storage.saveTokens(tokens);
      state = state.copyWith(
        connected: true,
        workspaceName: tokens.workspaceName,
      );
      await _loadToolsAndIdentity(tokens);
      return true;
    } catch (_) {
      rethrow;
    }
  }

  Future<void> disconnect() async {
    state = state.copyWith(disconnecting: true);
    try {
      await _storage.clearTokens();
      state = NotionConnectionState(
        enabled: state.enabled,
        enabledTools: state.enabledTools,
      );
    } finally {
      state = state.copyWith(disconnecting: false);
    }
  }

  Future<String?> validAccessToken() async {
    final tokens = await _storage.loadTokens();
    if (tokens == null) return null;
    try {
      final validTokens = await _oauth.ensureValidToken(tokens);
      if (validTokens != tokens) {
        await _storage.saveTokens(validTokens);
      }
      return validTokens.accessToken;
    } catch (_) {
      rethrow;
    }
  }

  Future<void> toggleEnabled(bool enabled) async {
    state = state.copyWith(saving: true, enabled: enabled);
    await _storage.saveEnabled(enabled);
    state = state.copyWith(saving: false);
  }

  Future<void> toggleTool(String name, bool checked) async {
    final current = state.enabledTools ?? _defaultWhitelist();
    final next = <String>{...current};
    if (checked) {
      next.add(name);
    } else {
      next.remove(name);
    }
    final list = next.toList()..sort();
    final value = _isAllDefault(list) ? null : list;
    state = state.copyWith(saving: true, enabledTools: value);
    await _storage.saveEnabledTools(value);
    state = state.copyWith(saving: false);
  }

  Future<void> bulkToggleTools(List<dynamic> tools, bool enable) async {
    final current = state.enabledTools ?? _defaultWhitelist();
    final next = <String>{...current};
    for (final tool in tools) {
      final name = tool is String ? tool : (tool.name as String);
      if (enable) {
        next.add(name);
      } else {
        next.remove(name);
      }
    }
    final list = next.toList()..sort();
    final value = _isAllDefault(list) ? null : list;
    state = state.copyWith(saving: true, enabledTools: value);
    await _storage.saveEnabledTools(value);
    state = state.copyWith(saving: false);
  }

  List<String> _defaultWhitelist() {
    final tools = state.tools.isEmpty ? NotionToolRegistry.allTools : state.tools;
    return tools
        .where((t) => getToolKind(t.name) == NotionToolKind.read)
        .map((t) => t.name)
        .toList();
  }

  bool _isAllDefault(List<String> list) {
    final defaultNames = NotionToolRegistry.allTools
        .where((t) => getToolKind(t.name) == NotionToolKind.read)
        .map((t) => t.name)
        .toSet();
    final set = list.toSet();
    return set.length == defaultNames.length &&
        set.every((n) => defaultNames.contains(n));
  }

  Future<void> _loadToolsAndIdentity(NotionTokens tokens) async {
    state = state.copyWith(toolsLoading: true, toolsError: null);
    try {
      final validTokens = await _oauth.ensureValidToken(tokens);
      if (validTokens != tokens) {
        await _storage.saveTokens(validTokens);
      }
      state = state.copyWith(
        tools: NotionToolRegistry.allTools,
        toolsLoading: false,
      );
      await _captureSelfIdentity(validTokens);
    } catch (err) {
      state = state.copyWith(
        toolsLoading: false,
        toolsError: err is NotionOAuthError
            ? err.message
            : 'Failed to load Notion tools',
      );
      rethrow;
    }
  }

  Future<void> _captureSelfIdentity(NotionTokens tokens) async {
    if (tokens.workspaceName != null) {
      state = state.copyWith(workspaceName: tokens.workspaceName);
      return;
    }
    try {
      final self = await _api.fetchSelf(tokens.accessToken);
      if (self == null) return;
      final updated = tokens.copyWith(
        workspaceId: self.workspaceId,
        workspaceName: self.workspaceName,
        userName: self.userName,
      );
      await _storage.saveTokens(updated);
      state = state.copyWith(workspaceName: self.workspaceName);
    } catch (_) {
      // best-effort
    }
  }
}

final notionConnectionProvider =
    NotifierProvider<NotionConnectionNotifier, NotionConnectionState>(
      NotionConnectionNotifier.new,
    );

final notionApiClientProvider = Provider<NotionApiClient>((ref) {
  final backendUrl = ref.watch(backendUrlProvider);
  final client = NotionApiClient(backendUrl: backendUrl);
  ref.onDispose(client.close);
  return client;
});