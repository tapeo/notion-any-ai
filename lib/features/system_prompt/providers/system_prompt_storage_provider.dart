import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/services/shared_prefs_provider.dart';
import '../services/system_prompt_storage.dart';

final systemPromptStorageProvider = Provider<SystemPromptStorage>((ref) {
  return SystemPromptStorage(sharedPrefs: ref.watch(sharedPrefsProvider));
});