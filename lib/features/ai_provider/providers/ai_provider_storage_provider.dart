// Riverpod provider for AiProviderStorage.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/services/secure_storage_provider.dart';
import '../../../app/services/shared_prefs_provider.dart';
import '../services/ai_provider_storage.dart';

final aiProviderStorageProvider = Provider<AiProviderStorage>((ref) {
  return AiProviderStorage(
    secureStorage: ref.watch(flutterSecureStorageProvider),
    sharedPrefs: ref.watch(sharedPrefsProvider),
  );
});