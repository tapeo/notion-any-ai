// Riverpod provider for the OpenAI-compatible chat client.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/openai_chat_client.dart';

final openAiChatClientProvider = Provider<OpenAiChatClient>((ref) {
  final client = OpenAiChatClient();
  ref.onDispose(client.close);
  return client;
});