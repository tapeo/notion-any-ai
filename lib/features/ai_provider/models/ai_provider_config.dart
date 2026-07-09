import 'package:equatable/equatable.dart';

class AiProviderConfig extends Equatable {
  const AiProviderConfig({required this.endpoint, required this.model});

  final String endpoint;
  final String model;

  @override
  List<Object?> get props => [endpoint, model];
}
