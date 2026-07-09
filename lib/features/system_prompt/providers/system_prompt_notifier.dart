import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/system_prompt_storage.dart';
import '../states/system_prompt_state.dart';
import 'system_prompt_storage_provider.dart';

class SystemPromptNotifier extends Notifier<SystemPromptState> {
  late SystemPromptStorage _storage;

  @override
  SystemPromptState build() {
    _storage = ref.watch(systemPromptStorageProvider);
    return const SystemPromptState();
  }

  Future<void> init() async {
    final prompt = _storage.loadPrompt();
    if (prompt != null) {
      state = state.copyWith(prompt: prompt);
    }
  }

  Future<void> save(String prompt) async {
    final trimmed = prompt.trim();
    state = state.copyWith(saving: true);
    await _storage.savePrompt(trimmed);
    state = state.copyWith(prompt: trimmed, saving: false);
  }

  Future<void> reset() async {
    state = state.copyWith(saving: true);
    await _storage.clearPrompt();
    state = state.copyWith(
      prompt: SystemPromptState.defaultPrompt,
      saving: false,
    );
  }

  Future<void> clear() async {
    state = state.copyWith(saving: true);
    await _storage.clearPrompt();
    state = const SystemPromptState();
  }
}

final systemPromptProvider =
    NotifierProvider<SystemPromptNotifier, SystemPromptState>(
      SystemPromptNotifier.new,
    );
