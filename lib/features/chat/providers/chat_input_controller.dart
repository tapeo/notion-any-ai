// Shared channel for pre-filling the chat input text from outside the bar.
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatInputController {
  ChatInputController();

  final ValueNotifier<int> prefillSignal = ValueNotifier(0);
  String _pendingText = '';

  String get pendingText => _pendingText;

  void prefill(String text) {
    _pendingText = text;
    prefillSignal.value++;
  }

  void consume() {
    _pendingText = '';
  }
}

final chatInputControllerProvider = Provider<ChatInputController>((ref) {
  return ChatInputController();
});