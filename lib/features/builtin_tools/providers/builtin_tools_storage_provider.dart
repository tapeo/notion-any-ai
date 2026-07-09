import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/services/shared_prefs_provider.dart';
import '../services/builtin_tools_storage.dart';

final builtinToolsStorageProvider = Provider<BuiltinToolsStorage>((ref) {
  return BuiltinToolsStorage(sharedPrefs: ref.watch(sharedPrefsProvider));
});