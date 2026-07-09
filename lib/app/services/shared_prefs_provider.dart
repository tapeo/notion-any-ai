import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

SharedPreferences? _sharedPrefsInstance;

Future<void> initSharedPrefs() async {
  _sharedPrefsInstance = await SharedPreferences.getInstance();
}

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  final instance = _sharedPrefsInstance;
  if (instance == null) {
    throw StateError(
      'SharedPreferences not initialized. Call initSharedPrefs() in main '
      'before reading sharedPrefsProvider.',
    );
  }
  return instance;
});
