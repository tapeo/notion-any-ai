import 'package:equatable/equatable.dart';

class AiProviderState extends Equatable {
  const AiProviderState({
    this.endpoint = '',
    this.model = '',
    this.hasApiKey = false,
    this.saving = false,
  });

  final String endpoint;
  final String model;
  final bool hasApiKey;
  final bool saving;

  bool get isConfigured => endpoint.isNotEmpty && model.isNotEmpty && hasApiKey;

  AiProviderState copyWith({
    String? endpoint,
    String? model,
    bool? hasApiKey,
    bool? saving,
  }) {
    return AiProviderState(
      endpoint: endpoint ?? this.endpoint,
      model: model ?? this.model,
      hasApiKey: hasApiKey ?? this.hasApiKey,
      saving: saving ?? this.saving,
    );
  }

  @override
  List<Object?> get props => [endpoint, model, hasApiKey, saving];
}