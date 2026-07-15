import 'package:equatable/equatable.dart';

class PendingQuestion extends Equatable {
  const PendingQuestion({
    required this.id,
    required this.question,
    this.options,
    this.context,
  });

  final String id;
  final String question;
  final List<String>? options;
  final String? context;

  @override
  List<Object?> get props => [id, question, options, context];
}
