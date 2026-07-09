import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ai_provider_storage.dart';
import '../states/ai_provider_state.dart';
import 'ai_provider_storage_provider.dart';

class AiProviderNotifier extends Notifier<AiProviderState> {
  late final AiProviderStorage _storage;

  @override
  AiProviderState build() {
    _storage = ref.watch(aiProviderStorageProvider);
    return const AiProviderState();
  }

  Future<void> init() async {
    final config = await _storage.loadConfig();
    if (config == null) return;
    state = state.copyWith(
      endpoint: config.endpoint,
      model: config.model,
      hasApiKey: true,
    );
  }

  Future<void> save({
    required String endpoint,
    required String model,
    required String apiKey,
  }) async {
    state = state.copyWith(saving: true);
    await _storage.saveConfig(
      endpoint: endpoint.trim(),
      model: model.trim(),
      apiKey: apiKey.trim(),
    );
    state = state.copyWith(
      endpoint: endpoint.trim(),
      model: model.trim(),
      hasApiKey: apiKey.trim().isNotEmpty,
      saving: false,
    );
  }

  Future<void> clear() async {
    state = state.copyWith(saving: true);
    await _storage.clearConfig();
    state = const AiProviderState();
  }
}

final aiProviderProvider =
    NotifierProvider<AiProviderNotifier, AiProviderState>(
      AiProviderNotifier.new,
    );
