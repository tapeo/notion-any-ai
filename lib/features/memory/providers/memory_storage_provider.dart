import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../conversations/providers/conversation_storage_provider.dart';
import '../services/memory_storage.dart';

final memoryStorageProvider = Provider<MemoryStorage>((ref) {
  final instance = appDirInstance;
  if (instance == null) {
    throw StateError(
      'App directory not initialized. Call initAppDir() in main '
      'before reading memoryStorageProvider.',
    );
  }
  return MemoryStorage(appDir: instance);
});