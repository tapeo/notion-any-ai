import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ai_provider_config.dart';

class AiProviderStorage {
  AiProviderStorage({required this._secureStorage, required this._sharedPrefs});

  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _sharedPrefs;

  static const _keyEndpoint = 'ai_provider_endpoint';
  static const _keyModel = 'ai_provider_model';
  static const _keyApiKey = 'ai_provider_api_key';

  Future<AiProviderConfig?> loadConfig() async {
    final apiKey = await _secureStorage.read(key: _keyApiKey);
    if (apiKey == null) return null;
    final endpoint = _sharedPrefs.getString(_keyEndpoint);
    final model = _sharedPrefs.getString(_keyModel);
    if (endpoint == null || model == null) return null;
    return AiProviderConfig(endpoint: endpoint, model: model);
  }

  Future<String?> loadApiKey() => _secureStorage.read(key: _keyApiKey);

  Future<void> saveConfig({
    required String endpoint,
    required String model,
    String? apiKey,
  }) async {
    await _sharedPrefs.setString(_keyEndpoint, endpoint);
    await _sharedPrefs.setString(_keyModel, model);
    if (apiKey != null && apiKey.isNotEmpty) {
      await _secureStorage.write(key: _keyApiKey, value: apiKey);
    }
  }

  Future<void> clearConfig() async {
    await _sharedPrefs.remove(_keyEndpoint);
    await _sharedPrefs.remove(_keyModel);
    await _secureStorage.delete(key: _keyApiKey);
  }
}
