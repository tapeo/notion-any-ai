import 'package:equatable/equatable.dart';

class MemoryState extends Equatable {
  const MemoryState({this.content = '', this.saving = false});

  final String content;
  final bool saving;

  MemoryState copyWith({String? content, bool? saving}) {
    return MemoryState(
      content: content ?? this.content,
      saving: saving ?? this.saving,
    );
  }

  @override
  List<Object?> get props => [content, saving];
}