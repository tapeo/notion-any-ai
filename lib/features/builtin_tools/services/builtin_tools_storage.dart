// Persists which built-in tools are enabled, in SharedPreferences.
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/builtin_tool_meta.dart';

class BuiltinToolsStorage {
  BuiltinToolsStorage({required SharedPreferences sharedPrefs})
      : _sharedPrefs = sharedPrefs;

  final SharedPreferences _sharedPrefs;

  static const _keyEnabled = 'builtin_tools_enabled';

  Map<String, bool> loadEnabled() {
    final raw = _sharedPrefs.getString(_keyEnabled);
    if (raw == null || raw.isEmpty) {
      return _defaults();
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final result = <String, bool>{};
      for (final entry in decoded.entries) {
        result[entry.key] = entry.value is bool
            ? entry.value as bool
            : true;
      }
      for (final tool in BuiltinToolRegistry.all) {
        result.putIfAbsent(tool.id, () => true);
      }
      return result;
    } catch (_) {
      return _defaults();
    }
  }

  Future<void> saveEnabled(Map<String, bool> enabled) {
    final encoded = jsonEncode(enabled);
    return _sharedPrefs.setString(_keyEnabled, encoded);
  }

  Future<void> clear() => _sharedPrefs.remove(_keyEnabled);

  Map<String, bool> _defaults() {
    final result = <String, bool>{};
    for (final tool in BuiltinToolRegistry.all) {
      result[tool.id] = true;
    }
    return result;
  }
}