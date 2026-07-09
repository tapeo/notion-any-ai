import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/services/secure_storage_provider.dart';
import '../../../app/services/shared_prefs_provider.dart';
import '../services/voice_input_storage.dart';

final voiceInputStorageProvider = Provider<VoiceInputStorage>((ref) {
  return VoiceInputStorage(
    secureStorage: ref.watch(flutterSecureStorageProvider),
    sharedPrefs: ref.watch(sharedPrefsProvider),
  );
});