import 'package:shared_preferences/shared_preferences.dart';

class SystemPromptStorage {
  SystemPromptStorage({required this._sharedPrefs});

  final SharedPreferences _sharedPrefs;

  static const _keyPrompt = 'system_prompt';

  String? loadPrompt() => _sharedPrefs.getString(_keyPrompt);

  Future<void> savePrompt(String prompt) =>
      _sharedPrefs.setString(_keyPrompt, prompt);

  Future<void> clearPrompt() => _sharedPrefs.remove(_keyPrompt);
}
