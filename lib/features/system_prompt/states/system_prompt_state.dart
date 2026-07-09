import 'package:equatable/equatable.dart';

class SystemPromptState extends Equatable {
  const SystemPromptState({this.prompt = '', this.saving = false});

  final String prompt;
  final bool saving;

  static const String defaultPrompt =
      'You are Any AI for Notion, an assistant with access to the user\'s Notion '
      'workspace via tools. Use tools when the user asks about their Notion '
      'content. When tools are not needed, answer directly. Always return related Notion pages as links.';

  SystemPromptState copyWith({String? prompt, bool? saving}) {
    return SystemPromptState(
      prompt: prompt ?? this.prompt,
      saving: saving ?? this.saving,
    );
  }

  @override
  List<Object?> get props => [prompt, saving];
}
