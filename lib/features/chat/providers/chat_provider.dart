// Notifier managing chat messages and the OpenAI-compatible streaming tool-call loop.
import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../ai_provider/providers/ai_provider_notifier.dart';
import '../../ai_provider/providers/ai_provider_storage_provider.dart';
import '../../builtin_tools/models/builtin_tool_meta.dart';
import '../../builtin_tools/providers/builtin_tools_notifier.dart';
import '../../builtin_tools/providers/pending_question_provider.dart';
import '../../conversations/providers/conversation_storage_provider.dart';
import '../../conversations/providers/conversations_notifier.dart';
import '../../memory/providers/memory_notifier.dart';
import '../../notion/models/notion_page_ref.dart';
import '../../notion/models/notion_tool_meta.dart';
import '../../notion/providers/notion_connection_notifier.dart';
import '../../notion/services/notion_tool_registry.dart';
import '../../notion/states/notion_connection_state.dart';
import '../../system_prompt/providers/system_prompt_notifier.dart';
import '../../system_prompt/states/system_prompt_state.dart';
import '../models/chat_message.dart';
import '../models/chat_role.dart';
import '../models/token_usage.dart';
import '../models/tool_call.dart';
import '../services/notion_tool_bridge.dart';
import '../states/chat_state.dart';
import 'openai_chat_client_provider.dart';

class ChatNotifier extends Notifier<ChatState> {
  ChatNotifier() : _uuid = const Uuid();

  final Uuid _uuid;

  static const int _maxIterations = 100;

  StreamSubscription<dynamic>? _streamSub;
  Completer<void>? _streamCompleter;
  bool _stopped = false;
  bool _isLoadingConversation = false;

  @override
  ChatState build() {
    ref.listen<String?>(conversationsProvider.select((s) => s.activeId), (
      previous,
      next,
    ) {
      if (previous != next) {
        _loadActiveConversation(next);
      }
    });

    return const ChatState();
  }

  Future<void> _loadActiveConversation(String? id) async {
    if (_isLoadingConversation) {
      return;
    }
    if (id == null) {
      state = const ChatState();
      return;
    }
    _isLoadingConversation = true;
    final storage = ref.read(conversationStorageProvider);
    final conversation = storage.loadConversation(id);
    if (conversation != null) {
      state = ChatState(messages: conversation.messages);
    } else {
      state = const ChatState();
    }
    _isLoadingConversation = false;
  }

  String get _effectiveSystemPrompt {
    final prompt = ref.read(systemPromptProvider).prompt;
    final base = prompt.isEmpty ? SystemPromptState.defaultPrompt : prompt;
    return base;
  }

  String _systemPromptWithPages(List<NotionPageRef> pages) {
    var base = _effectiveSystemPrompt;
    final memoryContent = ref.read(memoryProvider.select((s) => s.content));
    if (memoryContent.trim().isNotEmpty) {
      base =
          '$base\n\n## Persistent memory\n'
          'The following is the shared persistent memory. Treat it as facts '
          'the user asked you to remember across conversations. You can read, '
          'search, add, and delete sections using the memory tools.\n\n'
          '$memoryContent';
    }
    if (pages.isEmpty) {
      return base;
    }
    final pagesList = pages.where((p) => !p.isDataSource).toList();
    final dataSourcesList = pages.where((p) => p.isDataSource).toList();
    final lines = <String>[];
    for (final p in pagesList) {
      lines.add("- '${p.title}' (page id: ${p.id})");
    }
    for (final ds in dataSourcesList) {
      lines.add("- '${ds.title}' (database/data source id: ${ds.id})");
    }
    final hint =
        'The user has selected the following Notion resources as the '
        'focus of this message:\n${lines.join('\n')}\n'
        'You MUST fetch each of these with the available Notion read '
        'tools before answering, so your response is grounded in their '
        'actual content. For pages, use notion_fetch_page with the page '
        'id. For databases and data sources, use notion_get_database or '
        'notion_query_database with the database/data source id. Treat '
        "the user's message as referring to these resources unless they "
        'clearly ask about something else.';
    return '$base\n\n$hint';
  }

  void selectPage(NotionPageRef page) {
    if (state.selectedPages.any((p) => p.id == page.id)) {
      return;
    }
    state = state.copyWith(selectedPages: [...state.selectedPages, page]);
  }

  void removePage(NotionPageRef page) {
    state = state.copyWith(
      selectedPages: state.selectedPages.where((p) => p.id != page.id).toList(),
    );
  }

  void clearPages() {
    state = state.copyWith(clearSelectedPages: true);
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isSending) {
      return;
    }
    if (!ref.read(aiProviderProvider).isConfigured) {
      _appendAssistant(
        'Configure the AI provider in Settings to start chatting.',
      );
      return;
    }

    final selectedPages = state.selectedPages;
    final existingMessages = state.messages;

    final wasNewConversation = ref.read(
      conversationsProvider.select((s) => s.activeId == null),
    );
    String conversationId;
    if (wasNewConversation) {
      conversationId = _uuid.v4();
      final now = DateTime.now();
      final tempTitle = trimmed.length > 40
          ? '${trimmed.substring(0, 40)}...'
          : trimmed;
      _isLoadingConversation = true;
      await ref
          .read(conversationsProvider.notifier)
          .create(id: conversationId, title: tempTitle, createdAt: now);
      _isLoadingConversation = false;
    } else {
      conversationId = ref.read(
        conversationsProvider.select((s) => s.activeId),
      )!;
    }

    final userMessage = ChatMessage(
      id: _uuid.v4(),
      role: ChatRole.user,
      content: trimmed,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...existingMessages, userMessage],
      isSending: true,
      clearSelectedPages: true,
    );

    await _persist(conversationId);

    _stopped = false;
    var hadReply = false;
    try {
      await _runCompletionLoop(selectedPages: selectedPages);
      hadReply = true;
    } catch (err) {
      _appendAssistant('Something went wrong: $err');
    } finally {
      await _streamSub?.cancel();
      _streamSub = null;
      state = state.copyWith(isSending: false);
    }

    if (wasNewConversation && hadReply && !_stopped) {
      await _generateTitle(conversationId);
    }
  }

  void clearChat() {
    stopStreaming();
    ref.read(conversationsProvider.notifier).startNew();
  }

  Future<void> openConversation(String id) async {
    if (state.isSending) {
      stopStreaming();
    }
    ref.read(conversationsProvider.notifier).open(id);
  }

  Future<void> reloadActiveConversation() async {
    final id = ref.read(conversationsProvider.select((s) => s.activeId));
    await _loadActiveConversation(id);
  }

  Future<void> deleteConversation(String id) async {
    await ref.read(conversationsProvider.notifier).delete(id);
  }

  Future<void> renameConversation(String id, String title) async {
    await ref.read(conversationsProvider.notifier).rename(id, title);
  }

  void stopStreaming() {
    ref.read(pendingQuestionProvider.notifier).dismiss();
    if (!state.isSending) {
      return;
    }
    _stopped = true;
    _streamSub?.cancel();
    _streamSub = null;
    if (_streamCompleter != null && !_streamCompleter!.isCompleted) {
      _streamCompleter!.complete();
    }
  }

  Future<void> _persist(String conversationId) async {
    if (_isLoadingConversation) return;
    await ref
        .read(conversationsProvider.notifier)
        .persistMessages(
          conversationId,
          state.messages,
          updatedAt: DateTime.now(),
        );
  }

  Future<void> _runCompletionLoop({
    List<NotionPageRef> selectedPages = const [],
  }) async {
    final ai = ref.read(aiProviderProvider);
    final notion = ref.read(notionConnectionProvider);
    final client = ref.read(openAiChatClientProvider);
    final apiKey = await _loadApiKey();
    if (apiKey == null) {
      _appendAssistant(
        'Configure the AI provider in Settings to start chatting.',
      );
      return;
    }

    final notionContext = await _loadNotionContext();
    final notionAccessToken = notionContext.accessToken;
    final enabledTools = notionContext.enabledTools;

    final toolSchemas = <Map<String, dynamic>>[];
    if (notionAccessToken != null &&
        enabledTools != null &&
        enabledTools.isNotEmpty) {
      final bridge = NotionToolBridge(
        apiClient: ref.read(notionApiClientProvider),
        accessToken: notionAccessToken,
        availableTools: notion.tools,
      );
      toolSchemas.addAll(
        bridge.buildTools(available: notion.tools, enabled: enabledTools),
      );
    }
    toolSchemas.addAll(
      ref
          .read(builtinToolsProvider.notifier)
          .enabledTools()
          .map((t) => t.toOpenAiSchema())
          .toList(),
    );

    final conversationId = ref.read(
      conversationsProvider.select((s) => s.activeId),
    );

    final conversation = <ChatMessage>[
      ChatMessage(
        id: 'system',
        role: ChatRole.system,
        content: _systemPromptWithPages(selectedPages),
        createdAt: DateTime.now(),
      ),
      ...state.messages,
    ];

    for (var iteration = 0; iteration < _maxIterations; iteration++) {
      if (_stopped) {
        return;
      }

      final assistantId = _uuid.v4();
      final assistantPlaceholder = ChatMessage(
        id: assistantId,
        role: ChatRole.assistant,
        content: null,
        createdAt: DateTime.now(),
      );
      state = state.copyWith(
        messages: [...state.messages, assistantPlaceholder],
      );

      final contentBuffer = StringBuffer();
      final reasoningBuffer = StringBuffer();
      final toolCallAccumulator = <int, _AccumulatedToolCall>{};
      TokenUsage? capturedUsage;

      final completer = Completer<void>();
      _streamCompleter = completer;
      _streamSub = client
          .streamComplete(
            endpoint: ai.endpoint,
            apiKey: apiKey,
            model: ai.model,
            messages: conversation,
            tools: toolSchemas,
          )
          .listen(
            (chunk) {
              if (_stopped) {
                return;
              }
              if (chunk.reasoningDelta != null &&
                  chunk.reasoningDelta!.isNotEmpty) {
                reasoningBuffer.write(chunk.reasoningDelta);
                _updateStreamingMessage(
                  assistantId,
                  content: contentBuffer.toString(),
                  reasoning: reasoningBuffer.toString(),
                );
              }
              if (chunk.contentDelta != null &&
                  chunk.contentDelta!.isNotEmpty) {
                contentBuffer.write(chunk.contentDelta);
                _updateStreamingMessage(
                  assistantId,
                  content: contentBuffer.toString(),
                  reasoning: reasoningBuffer.toString(),
                );
              }
              for (final delta in chunk.toolCallDeltas) {
                final acc = toolCallAccumulator.putIfAbsent(
                  delta.index,
                  () => _AccumulatedToolCall(),
                );
                if (delta.id != null) acc.id = delta.id!;
                if (delta.name != null) acc.name = delta.name!;
                if (delta.argumentsDelta != null) {
                  acc.arguments.write(delta.argumentsDelta);
                }
              }
              if (chunk.usage != null) {
                capturedUsage = chunk.usage;
              }
            },
            onError: completer.completeError,
            onDone: completer.complete,
          );

      await completer.future;
      await _streamSub?.cancel();
      _streamSub = null;
      _streamCompleter = null;

      if (_stopped) {
        final conversationId = ref.read(
          conversationsProvider.select((s) => s.activeId),
        );
        _finalizeStoppedAssistant(
          assistantId: assistantId,
          contentBuffer: contentBuffer,
          reasoningBuffer: reasoningBuffer,
          toolCallAccumulator: toolCallAccumulator,
          createdAt: assistantPlaceholder.createdAt,
          usage: capturedUsage,
        );
        if (conversationId != null) {
          await _persist(conversationId);
        }
        return;
      }

      final toolCalls = _finalizeToolCalls(toolCallAccumulator);
      if (toolCalls.isNotEmpty) {
        final assistantMessage = ChatMessage(
          id: assistantId,
          role: ChatRole.assistant,
          content: contentBuffer.isEmpty ? null : contentBuffer.toString(),
          reasoning: reasoningBuffer.isEmpty
              ? null
              : reasoningBuffer.toString(),
          toolCalls: toolCalls,
          createdAt: assistantPlaceholder.createdAt,
          usage: capturedUsage,
        );
        _replaceMessage(assistantId, assistantMessage);
        conversation.add(assistantMessage);
        if (conversationId != null) {
          await _persist(conversationId);
        }

        final bridge = NotionToolBridge(
          apiClient: ref.read(notionApiClientProvider),
          accessToken: notionAccessToken ?? '',
          availableTools: notion.tools,
        );
        for (final call in toolCalls) {
          final String result;
          if (isBuiltinTool(call.name)) {
            result = await executeBuiltinTool(call, ref);
          } else if (notionAccessToken == null) {
            _appendAssistant(
              'I tried to call ${call.name} but the Notion connection is '
              'unavailable.',
            );
            return;
          } else {
            result = await bridge.execute(call);
          }
          if (_stopped) {
            _appendStoppedToolResults(toolCalls);
            if (conversationId != null) {
              await _persist(conversationId);
            }
            return;
          }
          final toolMessage = ChatMessage(
            id: _uuid.v4(),
            role: ChatRole.tool,
            content: result,
            toolCallId: call.id,
            name: call.name,
            createdAt: DateTime.now(),
          );
          conversation.add(toolMessage);
          state = state.copyWith(messages: [...state.messages, toolMessage]);
          if (conversationId != null) {
            await _persist(conversationId);
          }
        }
        continue;
      }

      final reply = contentBuffer.toString().trim();
      final finalized = ChatMessage(
        id: assistantId,
        role: ChatRole.assistant,
        content: reply.isEmpty ? '(no response)' : reply,
        reasoning: reasoningBuffer.isEmpty ? null : reasoningBuffer.toString(),
        createdAt: assistantPlaceholder.createdAt,
        usage: capturedUsage,
      );
      _replaceMessage(assistantId, finalized);
      if (conversationId != null) {
        await _persist(conversationId);
      }
      return;
    }

    if (_stopped) {
      return;
    }
    _appendAssistant(
      'I reached the tool-call limit while working on this. '
      'Try rephrasing or asking for fewer actions at once.',
    );
    if (conversationId != null) {
      await _persist(conversationId);
    }
  }

  Future<void> _generateTitle(String conversationId) async {
    final ai = ref.read(aiProviderProvider);
    if (!ai.isConfigured) return;
    final apiKey = await _loadApiKey();
    if (apiKey == null) return;

    final messages = state.messages;
    final firstUser = messages.firstWhere(
      (m) => m.role == ChatRole.user,
      orElse: () => messages.first,
    );
    final firstAssistant = messages.firstWhere(
      (m) => m.role == ChatRole.assistant && (m.content?.isNotEmpty ?? false),
      orElse: () => messages.last,
    );

    final titleMessages = <ChatMessage>[
      ChatMessage(
        id: 'title-system',
        role: ChatRole.system,
        content:
            'Generate a concise 3-6 word title for this conversation. '
            'Reply with only the title, no quotes, no punctuation at the end.',
        createdAt: DateTime.now(),
      ),
      ChatMessage(
        id: 'title-user',
        role: ChatRole.user,
        content:
            'User: ${firstUser.content ?? ""}\n\n'
            'Assistant: ${firstAssistant.content ?? ""}',
        createdAt: DateTime.now(),
      ),
    ];

    try {
      final client = ref.read(openAiChatClientProvider);
      final title = await client.complete(
        endpoint: ai.endpoint,
        apiKey: apiKey,
        model: ai.model,
        messages: titleMessages,
      );
      if (title != null && title.trim().isNotEmpty) {
        await ref
            .read(conversationsProvider.notifier)
            .rename(conversationId, title.trim());
      }
    } catch (_) {
      // Title generation is best-effort.
    }
  }

  List<ToolCall> _finalizeToolCalls(
    Map<int, _AccumulatedToolCall> accumulator,
  ) {
    if (accumulator.isEmpty) {
      return const [];
    }
    final indices = accumulator.keys.toList()..sort();
    final result = <ToolCall>[];
    for (final index in indices) {
      final acc = accumulator[index]!;
      if (acc.id.isEmpty || acc.name.isEmpty) {
        continue;
      }
      Map<String, dynamic> arguments;
      try {
        arguments =
            jsonDecode(acc.arguments.toString()) as Map<String, dynamic>;
      } catch (_) {
        arguments = _parseErrorArguments(acc.arguments.toString());
      }
      result.add(ToolCall(id: acc.id, name: acc.name, arguments: arguments));
    }
    return result;
  }

  void _updateStreamingMessage(
    String id, {
    String? content,
    String? reasoning,
  }) {
    final messages = state.messages.toList();
    for (var i = 0; i < messages.length; i++) {
      if (messages[i].id == id) {
        messages[i] = messages[i].copyWith(
          content: content ?? messages[i].content,
          reasoning: reasoning ?? messages[i].reasoning,
        );
        state = state.copyWith(messages: messages);
        return;
      }
    }
  }

  void _replaceMessage(String id, ChatMessage replacement) {
    final messages = state.messages.toList();
    for (var i = 0; i < messages.length; i++) {
      if (messages[i].id == id) {
        messages[i] = replacement;
        state = state.copyWith(messages: messages);
        return;
      }
    }
  }

  Future<String?> _loadApiKey() async {
    final storage = ref.read(aiProviderStorageProvider);
    return storage.loadApiKey();
  }

  Future<({String? accessToken, List<String>? enabledTools})>
  _loadNotionContext() async {
    final notion = ref.read(notionConnectionProvider);
    if (!notion.connected || !notion.enabled) {
      return (accessToken: null, enabledTools: null);
    }
    final notifier = ref.read(notionConnectionProvider.notifier);
    final accessToken = await notifier.validAccessToken();
    final enabled = notion.enabledTools ?? _defaultEnabledTools(notion);
    return (accessToken: accessToken, enabledTools: enabled);
  }

  List<String> _defaultEnabledTools(NotionConnectionState notion) {
    final tools = notion.tools.isEmpty
        ? NotionToolRegistry.allTools
        : notion.tools;
    return tools
        .where((t) => getToolKind(t.name) == NotionToolKind.read)
        .map((t) => t.name)
        .toList();
  }

  void _appendAssistant(String content) {
    final message = ChatMessage(
      id: _uuid.v4(),
      role: ChatRole.assistant,
      content: content,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(messages: [...state.messages, message]);
  }

  void _finalizeStoppedAssistant({
    required String assistantId,
    required StringBuffer contentBuffer,
    required StringBuffer reasoningBuffer,
    required Map<int, _AccumulatedToolCall> toolCallAccumulator,
    required DateTime createdAt,
    TokenUsage? usage,
  }) {
    final toolCalls = _finalizeToolCalls(toolCallAccumulator);
    final content = contentBuffer.toString().trim();
    final reasoning = reasoningBuffer.toString();
    final finalized = ChatMessage(
      id: assistantId,
      role: ChatRole.assistant,
      content: content.isEmpty && toolCalls.isEmpty && reasoning.isEmpty
          ? '(stopped)'
          : (content.isEmpty ? null : content),
      reasoning: reasoning.isEmpty ? null : reasoning,
      toolCalls: toolCalls,
      createdAt: createdAt,
      usage: usage,
    );
    _replaceMessage(assistantId, finalized);

    if (toolCalls.isEmpty) {
      return;
    }
    _appendStoppedToolResults(toolCalls);
  }

  void _appendStoppedToolResults(List<ToolCall> toolCalls) {
    final existingResultIds = state.messages
        .where((m) => m.role == ChatRole.tool && m.toolCallId != null)
        .map((m) => m.toolCallId!)
        .toSet();
    final stoppedToolMessages = <ChatMessage>[];
    for (final call in toolCalls) {
      if (existingResultIds.contains(call.id)) {
        continue;
      }
      stoppedToolMessages.add(
        ChatMessage(
          id: _uuid.v4(),
          role: ChatRole.tool,
          content: 'Stopped by user.',
          toolCallId: call.id,
          name: call.name,
          createdAt: DateTime.now(),
        ),
      );
    }
    if (stoppedToolMessages.isEmpty) {
      return;
    }
    state = state.copyWith(
      messages: [...state.messages, ...stoppedToolMessages],
    );
  }
}

class _AccumulatedToolCall {
  String id = '';
  String name = '';
  final StringBuffer arguments = StringBuffer();
}

Map<String, dynamic> _parseErrorArguments(String raw) {
  final length = raw.length;
  const maxFragment = 200;
  String fragment;
  if (length <= maxFragment * 2) {
    fragment = raw;
  } else {
    fragment =
        '${raw.substring(0, maxFragment)} ... ${raw.substring(length - maxFragment)}';
  }
  return <String, dynamic>{
    '_parseError': true,
    'length': length,
    'fragment': fragment,
  };
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);
