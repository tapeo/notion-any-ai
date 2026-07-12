import 'package:equatable/equatable.dart';

class SystemPromptState extends Equatable {
  const SystemPromptState({this.prompt = '', this.saving = false});

  final String prompt;
  final bool saving;

  static const String defaultPrompt =
      '''You are Any AI for Notion, an assistant with access to the user's Notion workspace via tools. Use tools when the user asks about their Notion content. When tools are not needed, answer directly.

- Work on the the attached notion page if provided by the user
- Always return the link of the task related ready to be opened
- Never use emojis
- Never use em dashes''';

  SystemPromptState copyWith({String? prompt, bool? saving}) {
    return SystemPromptState(
      prompt: prompt ?? this.prompt,
      saving: saving ?? this.saving,
    );
  }

  @override
  List<Object?> get props => [prompt, saving];
}
