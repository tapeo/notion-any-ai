import 'package:equatable/equatable.dart';

class VoiceInputState extends Equatable {
  const VoiceInputState({
    this.model = '',
    this.hasApiKey = false,
    this.saving = false,
    this.isTranscribing = false,
  });

  final String model;
  final bool hasApiKey;
  final bool saving;
  final bool isTranscribing;

  bool get isConfigured => model.isNotEmpty && hasApiKey;

  VoiceInputState copyWith({
    String? model,
    bool? hasApiKey,
    bool? saving,
    bool? isTranscribing,
  }) {
    return VoiceInputState(
      model: model ?? this.model,
      hasApiKey: hasApiKey ?? this.hasApiKey,
      saving: saving ?? this.saving,
      isTranscribing: isTranscribing ?? this.isTranscribing,
    );
  }

  @override
  List<Object?> get props => [model, hasApiKey, saving, isTranscribing];
}