import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/notion_tokens.dart';

class NotionStorage {
  NotionStorage({required this.secureStorage, required this.sharedPrefs});

  final FlutterSecureStorage secureStorage;
  final SharedPreferences sharedPrefs;

  static const _keyTokens = 'notion_tokens';
  static const _keyPending = 'notion_pending';
  static const _keyEnabled = 'notion_enabled';
  static const _keyEnabledTools = 'notion_enabled_tools';

  Future<NotionTokens?> loadTokens() async {
    final json = await secureStorage.read(key: _keyTokens);
    if (json == null) return null;
    try {
      return NotionTokens.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveTokens(NotionTokens tokens) async {
    await secureStorage.write(
      key: _keyTokens,
      value: jsonEncode(tokens.toJson()),
    );
  }

  Future<void> clearTokens() async {
    await secureStorage.delete(key: _keyTokens);
  }

  Future<NotionPendingFlow?> loadPending() async {
    final json = await secureStorage.read(key: _keyPending);
    if (json == null) return null;
    try {
      return NotionPendingFlow.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> savePending(NotionPendingFlow pending) async {
    await secureStorage.write(
      key: _keyPending,
      value: jsonEncode(pending.toJson()),
    );
  }

  Future<void> clearPending() async {
    await secureStorage.delete(key: _keyPending);
  }

  bool loadEnabled() {
    return sharedPrefs.getBool(_keyEnabled) ?? false;
  }

  Future<void> saveEnabled(bool enabled) async {
    await sharedPrefs.setBool(_keyEnabled, enabled);
  }

  List<String>? loadEnabledTools() {
    final raw = sharedPrefs.getStringList(_keyEnabledTools);
    return raw;
  }

  Future<void> saveEnabledTools(List<String>? tools) async {
    if (tools == null) {
      await sharedPrefs.remove(_keyEnabledTools);
    } else {
      await sharedPrefs.setStringList(_keyEnabledTools, tools);
    }
  }
}
