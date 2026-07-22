// Transient error shown inline at the end of the message list.
import 'package:equatable/equatable.dart';

class ChatError extends Equatable {
  const ChatError({required this.text, required this.userText, this.detail});

  final String text;
  final String userText;
  final String? detail;

  @override
  List<Object?> get props => [text, userText, detail];
}
