import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VoiceInputStorage {
  VoiceInputStorage({required this._secureStorage, required this._sharedPrefs});

  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _sharedPrefs;

  static const _keyModel = 'voice_input_model';
  static const _keyApiKey = 'voice_input_api_key';

  Future<String?> loadModel() =>
      Future.value(_sharedPrefs.getString(_keyModel));

  Future<String?> loadApiKey() => _secureStorage.read(key: _keyApiKey);

  Future<void> saveConfig({
    required String model,
    required String apiKey,
  }) async {
    await _sharedPrefs.setString(_keyModel, model);
    await _secureStorage.write(key: _keyApiKey, value: apiKey);
  }

  Future<void> clear() async {
    await _sharedPrefs.remove(_keyModel);
    await _secureStorage.delete(key: _keyApiKey);
  }
}
