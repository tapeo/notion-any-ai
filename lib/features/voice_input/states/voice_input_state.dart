import 'package:equatable/equatable.dart';

class VoiceInputState extends Equatable {
  const VoiceInputState({
    this.model = '',
    this.hasApiKey = false,
    this.saving = false,
    this.isTranscribing = false,
    this.language = 'en',
  });

  final String model;
  final bool hasApiKey;
  final bool saving;
  final bool isTranscribing;
  final String language;

  bool get isConfigured => model.isNotEmpty && hasApiKey;

  VoiceInputState copyWith({
    String? model,
    bool? hasApiKey,
    bool? saving,
    bool? isTranscribing,
    String? language,
  }) {
    return VoiceInputState(
      model: model ?? this.model,
      hasApiKey: hasApiKey ?? this.hasApiKey,
      saving: saving ?? this.saving,
      isTranscribing: isTranscribing ?? this.isTranscribing,
      language: language ?? this.language,
    );
  }

  @override
  List<Object?> get props => [model, hasApiKey, saving, isTranscribing, language];
}
