import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'shared_prefs_provider.dart';

const _productionBackendUrl = String.fromEnvironment(
  'PRODUCTION_BACKEND_URL',
  defaultValue: '',
);

const _localBackendUrl = 'http://localhost:3000';

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
      return _localBackendUrl;
    }
    return _productionBackendUrl;
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
    if (stored == 'production' && _productionBackendUrl.isNotEmpty) {
      return BackendEnv.production;
    }
    return _productionBackendUrl.isNotEmpty
        ? BackendEnv.production
        : BackendEnv.local;
  }

  Future<void> setEnv(BackendEnv env) async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setString(_kBackendEnvKey, env.name);
    state = env;
  }
}

final backendEnvProvider = NotifierProvider<BackendEnvNotifier, BackendEnv>(
  BackendEnvNotifier.new,
);

final backendUrlProvider = Provider<String>((ref) {
  return ref.watch(backendEnvProvider).url;
});
