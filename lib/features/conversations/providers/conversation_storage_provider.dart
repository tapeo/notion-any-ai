import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../services/conversation_storage.dart';

Directory? _appDirInstance;

Directory? get appDirInstance => _appDirInstance;

Future<void> initAppDir() async {
  _appDirInstance = await getApplicationDocumentsDirectory();
}

final conversationStorageProvider = Provider<ConversationStorage>((ref) {
  final instance = _appDirInstance;
  if (instance == null) {
    throw StateError(
      'App directory not initialized. Call initAppDir() in main '
      'before reading conversationStorageProvider.',
    );
  }
  return ConversationStorage(appDir: instance);
});