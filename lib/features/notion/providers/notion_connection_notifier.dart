import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/services/secure_storage_provider.dart';
import '../../../app/services/shared_prefs_provider.dart';
import '../models/notion_tokens.dart';
import '../models/notion_tool_meta.dart';
import '../services/notion_loopback_server.dart';
import '../services/notion_mcp_client.dart';
import '../services/notion_oauth_service.dart';
import '../services/notion_platform.dart';
import '../services/notion_storage.dart';
import '../states/notion_connection_state.dart';

const _notionDefaultTools = <String>[
  'notion_search',
  'notion_fetch',
  'notion_query',
  'notion_get',
  'notion_list',
  'notion_retrieve',
  'notion_read',
];

class NotionConnectionNotifier extends Notifier<NotionConnectionState> {
  late final NotionStorage _storage;
  late final NotionOAuthService _oauth;
  late final NotionMcpClient _mcp;
  NotionLoopbackServer? _loopbackServer;

  @override
  NotionConnectionState build() {
    _storage = NotionStorage(
      secureStorage: ref.watch(flutterSecureStorageProvider),
      sharedPrefs: ref.watch(sharedPrefsProvider),
    );
    _oauth = NotionOAuthService();
    _mcp = ref.watch(notionMcpClientProvider);
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
      String redirectUri;
      if (isDesktopPlatform) {
        _loopbackServer = NotionLoopbackServer();
        redirectUri = await _loopbackServer!.start();
      } else {
        redirectUri = defaultRedirectUri;
      }

      final result = await _oauth.start(redirectUri: redirectUri);
      await _storage.savePending(result.pending);

      if (isDesktopPlatform && _loopbackServer != null) {
        _awaitLoopbackCallback();
      }
      state = state.copyWith(connecting: false);
      return result.authorizationUrl;
    } catch (_) {
      await _stopLoopbackServer();
      state = state.copyWith(connecting: false);
      return null;
    }
  }

  void _awaitLoopbackCallback() {
    final server = _loopbackServer;
    if (server == null) return;
    server
        .waitForCallback()
        .then((result) {
          if (result.error != null) {
            _stopLoopbackServer();
            return;
          }
          if (result.code != null && result.state != null) {
            handleCallback(result.code!, result.state!);
          }
        })
        .catchError((_) {
          _stopLoopbackServer();
        });
  }

  Future<void> _stopLoopbackServer() async {
    await _loopbackServer?.stop();
    _loopbackServer = null;
  }

  Future<bool> handleCallback(String code, String stateParam) async {
    final pending = await _storage.loadPending();
    if (pending == null) {
      await _stopLoopbackServer();
      return false;
    }
    if (pending.state != stateParam) {
      await _storage.clearPending();
      await _stopLoopbackServer();
      return false;
    }
    if (pending.isExpired) {
      await _storage.clearPending();
      await _stopLoopbackServer();
      return false;
    }
    try {
      final tokens = await _oauth.handleCallback(pending: pending, code: code);
      await _storage.saveTokens(tokens);
      await _storage.clearPending();
      await _stopLoopbackServer();
      _mcp.reset();
      state = state.copyWith(
        connected: true,
        workspaceName: tokens.workspaceName,
      );
      await _loadToolsAndIdentity(tokens);
      return true;
    } catch (_) {
      await _storage.clearPending();
      await _stopLoopbackServer();
      return false;
    }
  }

  Future<void> disconnect() async {
    state = state.copyWith(disconnecting: true);
    try {
      await _storage.clearTokens();
      _mcp.reset();
      await _stopLoopbackServer();
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
      return null;
    }
  }

  Future<void> toggleEnabled(bool enabled) async {
    state = state.copyWith(saving: true, enabled: enabled);
    await _storage.saveEnabled(enabled);
    state = state.copyWith(saving: false);
  }

  Future<void> toggleTool(String name, bool checked) async {
    if (checked && requiresBusinessPlan(name)) {
      state = state.copyWith(
        businessPlanPrompt: DateTime.now().millisecondsSinceEpoch,
      );
      return;
    }
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

  Future<void> bulkToggleTools(List<NotionToolMeta> tools, bool enable) async {
    if (enable && tools.any((t) => requiresBusinessPlan(t.name))) {
      final filtered = tools
          .where((t) => !requiresBusinessPlan(t.name))
          .toList();
      if (filtered.isEmpty) {
        state = state.copyWith(
          businessPlanPrompt: DateTime.now().millisecondsSinceEpoch,
        );
        return;
      }
      tools = filtered;
    }
    final current = state.enabledTools ?? _defaultWhitelist();
    final next = <String>{...current};
    for (final tool in tools) {
      if (enable) {
        next.add(tool.name);
      } else {
        next.remove(tool.name);
      }
    }
    final list = next.toList()..sort();
    final value = _isAllDefault(list) ? null : list;
    state = state.copyWith(saving: true, enabledTools: value);
    await _storage.saveEnabledTools(value);
    state = state.copyWith(saving: false);
  }

  List<String> _defaultWhitelist() {
    if (state.tools.isEmpty) {
      return [..._notionDefaultTools];
    }
    return state.tools
        .where(
          (t) =>
              getToolKind(t.name) == NotionToolKind.read &&
              !requiresBusinessPlan(t.name),
        )
        .map((t) => t.name)
        .toList();
  }

  bool _isAllDefault(List<String> list) {
    final sortedDefault = [..._notionDefaultTools]..sort();
    return list.length == sortedDefault.length &&
        list.every((n) => sortedDefault.contains(n));
  }

  Future<void> _loadToolsAndIdentity(NotionTokens tokens) async {
    state = state.copyWith(toolsLoading: true, toolsError: null);
    try {
      final validTokens = await _oauth.ensureValidToken(tokens);
      if (validTokens != tokens) {
        await _storage.saveTokens(validTokens);
      }
      final tools = await _mcp.listTools(validTokens.accessToken);
      state = state.copyWith(tools: tools, toolsLoading: false);
      await _captureSelfIdentity(validTokens);
    } catch (err) {
      state = state.copyWith(
        toolsLoading: false,
        toolsError: err is NotionOAuthError
            ? err.message
            : 'Failed to load Notion tools',
      );
    }
  }

  Future<void> _captureSelfIdentity(NotionTokens tokens) async {
    try {
      final self = await _mcp.fetchSelf(tokens.accessToken);
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

final businessPlanPromptSelector = Provider<int?>(
  (ref) => ref.watch(notionConnectionProvider).businessPlanPrompt,
);

final notionMcpClientProvider = Provider<NotionMcpClient>((ref) {
  final client = NotionMcpClient();
  ref.onDispose(client.close);
  return client;
});
