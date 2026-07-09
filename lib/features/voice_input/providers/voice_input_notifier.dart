import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/transcription_client.dart';
import '../services/voice_input_storage.dart';
import '../states/voice_input_state.dart';
import 'voice_input_storage_provider.dart';

class VoiceInputNotifier extends Notifier<VoiceInputState> {
  late final VoiceInputStorage _storage;

  @override
  VoiceInputState build() {
    _storage = ref.watch(voiceInputStorageProvider);
    return const VoiceInputState();
  }

  Future<void> init() async {
    final model = await _storage.loadModel();
    final apiKey = await _storage.loadApiKey();
    state = state.copyWith(
      model: model ?? '',
      hasApiKey: apiKey != null && apiKey.isNotEmpty,
    );
  }

  Future<void> save({required String model, required String apiKey}) async {
    state = state.copyWith(saving: true);
    await _storage.saveConfig(model: model.trim(), apiKey: apiKey.trim());
    state = state.copyWith(
      model: model.trim(),
      hasApiKey: apiKey.trim().isNotEmpty,
      saving: false,
    );
  }

  Future<void> clear() async {
    state = state.copyWith(saving: true);
    await _storage.clear();
    state = const VoiceInputState();
  }

  Future<String> transcribe(String audioPath) async {
    if (!state.isConfigured) {
      throw Exception('Voice input not configured');
    }
    final apiKey = await _storage.loadApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Voice input not configured');
    }

    state = state.copyWith(isTranscribing: true);
    try {
      final text = await TranscriptionClient.transcribe(
        apiKey: apiKey,
        model: state.model,
        audioPath: audioPath,
      );
      return text;
    } finally {
      TranscriptionClient.cleanupFile(audioPath);
      state = state.copyWith(isTranscribing: false);
    }
  }
}

final voiceInputProvider =
    NotifierProvider<VoiceInputNotifier, VoiceInputState>(
  VoiceInputNotifier.new,
);