import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VoiceInputStorage {
  VoiceInputStorage({required this._secureStorage, required this._sharedPrefs});

  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _sharedPrefs;

  static const _keyModel = 'voice_input_model';
  static const _keyApiKey = 'voice_input_api_key';
  static const _keyLanguage = 'voice_input_language';

  Future<String?> loadModel() =>
      Future.value(_sharedPrefs.getString(_keyModel));

  Future<String?> loadApiKey() => _secureStorage.read(key: _keyApiKey);

  Future<String?> loadLanguage() =>
      Future.value(_sharedPrefs.getString(_keyLanguage));

  Future<void> saveConfig({
    required String model,
    String? apiKey,
    required String language,
  }) async {
    await _sharedPrefs.setString(_keyModel, model);
    if (apiKey != null && apiKey.isNotEmpty) {
      await _secureStorage.write(key: _keyApiKey, value: apiKey);
    }
    await _sharedPrefs.setString(_keyLanguage, language);
  }

  Future<void> clear() async {
    await _sharedPrefs.remove(_keyModel);
    await _secureStorage.delete(key: _keyApiKey);
    await _sharedPrefs.remove(_keyLanguage);
  }
}
