import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'shared_prefs_provider.dart';

enum BackendEnv {
  local,
  production;

  String get label {
    if (this == BackendEnv.local) {
      return 'Local';
    }
    return 'Production';
  }

  String get url {
    if (this == BackendEnv.local) {
      return 'http://localhost:3000';
    }
    return 'https://notion-any-ai-backend-824089784983.europe-west1.run.app';
  }
}

const _kBackendEnvKey = 'backend_env';

class BackendEnvNotifier extends Notifier<BackendEnv> {
  @override
  BackendEnv build() {
    final prefs = ref.watch(sharedPrefsProvider);
    final stored = prefs.getString(_kBackendEnvKey);
    if (stored == 'local') {
      return BackendEnv.local;
    }
    return BackendEnv.production;
  }

  Future<void> setEnv(BackendEnv env) async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setString(_kBackendEnvKey, env.name);
    state = env;
  }
}

final backendEnvProvider =
    NotifierProvider<BackendEnvNotifier, BackendEnv>(
  BackendEnvNotifier.new,
);

final backendUrlProvider = Provider<String>((ref) {
  return ref.watch(backendEnvProvider).url;
});