// Streaming HTTP client for OpenAI-compatible chat completions endpoints.
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/chat_message.dart';

class ToolCallDelta {
  const ToolCallDelta({
    required this.index,
    this.id,
    this.name,
    this.argumentsDelta,
  });

  final int index;
  final String? id;
  final String? name;
  final String? argumentsDelta;
}

class OpenAiChatChunk {
  const OpenAiChatChunk({this.contentDelta, this.toolCallDeltas = const []});

  final String? contentDelta;
  final List<ToolCallDelta> toolCallDeltas;
}

class OpenAiChatError implements Exception {
  OpenAiChatError(this.message, [this.statusCode]);

  final String message;
  final int? statusCode;

  @override
  String toString() => 'OpenAiChatError: $message';
}

class OpenAiChatClient {
  OpenAiChatClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Stream<OpenAiChatChunk> streamComplete({
    required String endpoint,
    required String apiKey,
    required String model,
    required List<ChatMessage> messages,
    List<Map<String, dynamic>> tools = const [],
  }) async* {
    final url = _joinEndpoint(endpoint);
    final body = <String, dynamic>{
      'model': model,
      'messages': messages.map((m) => m.toOpenAiJson()).toList(),
      'stream': true,
    };
    if (tools.isNotEmpty) {
      body['tools'] = tools;
    }

    final request = http.Request('POST', Uri.parse(url))
      ..headers['Authorization'] = 'Bearer $apiKey'
      ..headers['Content-Type'] = 'application/json'
      ..headers['Accept'] = 'text/event-stream'
      ..body = jsonEncode(body);

    final http.StreamedResponse res;
    try {
      res = await _httpClient.send(request);
    } catch (err) {
      throw OpenAiChatError('Failed to connect: $err');
    }

    if (!res.statusCode.toString().startsWith('2')) {
      final buffered = await res.stream.bytesToString();
      throw OpenAiChatError(
        _extractErrorMessage(buffered) ??
            'Chat completions request failed (${res.statusCode})',
        res.statusCode,
      );
    }

    final lineBuffer = <int>[];
    final dataLines = <String>[];

    await for (final chunk in res.stream) {
      lineBuffer.addAll(chunk);
      final text = utf8.decode(lineBuffer, allowMalformed: true);
      if (!text.contains('\n')) {
        continue;
      }
      final lines = const LineSplitter().convert(text);
      final lastNewline = text.lastIndexOf('\n');
      final hasTrailingNewline = lastNewline == text.length - 1;
      final processableLines = hasTrailingNewline
          ? lines
          : lines.sublist(0, lines.length - 1);
      if (!hasTrailingNewline) {
        lineBuffer.clear();
        lineBuffer.addAll(utf8.encode(text.substring(lastNewline + 1)));
      } else {
        lineBuffer.clear();
      }

      for (final line in processableLines) {
        final parsed = _processLine(line, dataLines);
        if (parsed != null) {
          yield parsed;
        }
      }
    }

    if (lineBuffer.isNotEmpty) {
      final remaining = utf8.decode(lineBuffer, allowMalformed: true);
      final lines = const LineSplitter().convert(remaining);
      for (final line in lines) {
        final parsed = _processLine(line, dataLines);
        if (parsed != null) {
          yield parsed;
        }
      }
    }
    if (dataLines.isNotEmpty) {
      final parsed = _parseDataEvent(dataLines.join('\n'));
      if (parsed != null) {
        yield parsed;
      }
    }
  }

  OpenAiChatChunk? _processLine(String line, List<String> dataLines) {
    final trimmed = line.trimRight();
    if (trimmed.isEmpty) {
      if (dataLines.isNotEmpty) {
        final parsed = _parseDataEvent(dataLines.join('\n'));
        dataLines.clear();
        return parsed;
      }
      return null;
    }
    if (trimmed.startsWith('data:')) {
      dataLines.add(trimmed.substring(5).trimLeft());
      return null;
    }
    if (trimmed.startsWith('event:') ||
        trimmed.startsWith(':') ||
        trimmed.startsWith('id:') ||
        trimmed.startsWith('retry:')) {
      return null;
    }
    dataLines.add(trimmed);
    return null;
  }

  OpenAiChatChunk? _parseDataEvent(String data) {
    if (data.isEmpty) return null;
    if (data == '[DONE]') return null;
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
    final choices = json['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      return null;
    }
    final choice = choices[0] as Map<String, dynamic>;
    final delta = choice['delta'] as Map<String, dynamic>? ?? const {};
    final content = delta['content'] as String?;

    final toolCallDeltas = <ToolCallDelta>[];
    final toolCallsRaw = delta['tool_calls'] as List?;
    if (toolCallsRaw != null) {
      for (final tc in toolCallsRaw) {
        if (tc is! Map<String, dynamic>) continue;
        final index = tc['index'] as int? ?? 0;
        final id = tc['id'] as String?;
        final function = tc['function'] as Map<String, dynamic>?;
        final name = function?['name'] as String?;
        final argumentsDelta = function?['arguments'] as String?;
        toolCallDeltas.add(
          ToolCallDelta(
            index: index,
            id: id,
            name: name,
            argumentsDelta: argumentsDelta,
          ),
        );
      }
    }

    if (content == null && toolCallDeltas.isEmpty) {
      return null;
    }
    return OpenAiChatChunk(
      contentDelta: content,
      toolCallDeltas: toolCallDeltas,
    );
  }

  String _joinEndpoint(String endpoint) {
    final trimmed = endpoint.trim();
    if (trimmed.endsWith('/chat/completions')) return trimmed;
    if (trimmed.endsWith('/')) {
      return '${trimmed}chat/completions';
    }
    return '$trimmed/chat/completions';
  }

  String? _extractErrorMessage(String body) {
    if (body.isEmpty) return null;
    try {
      final parsed = jsonDecode(body) as Map<String, dynamic>;
      final error = parsed['error'];
      if (error is Map<String, dynamic>) {
        return error['message'] as String?;
      }
      if (error is String) return error;
    } catch (_) {
      return null;
    }
    return null;
  }

  void close() {
    _httpClient.close();
  }

  Future<String?> complete({
    required String endpoint,
    required String apiKey,
    required String model,
    required List<ChatMessage> messages,
  }) async {
    final url = _joinEndpoint(endpoint);
    final body = <String, dynamic>{
      'model': model,
      'messages': messages.map((m) => m.toOpenAiJson()).toList(),
      'stream': false,
    };
    final request = http.Request('POST', Uri.parse(url))
      ..headers['Authorization'] = 'Bearer $apiKey'
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode(body);

    final res = await _httpClient.send(request);
    final responseBody = await res.stream.bytesToString();
    if (!res.statusCode.toString().startsWith('2')) {
      throw OpenAiChatError(
        _extractErrorMessage(responseBody) ??
            'Chat completions request failed (${res.statusCode})',
        res.statusCode,
      );
    }
    try {
      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      final choices = json['choices'] as List?;
      if (choices == null || choices.isEmpty) return null;
      final choice = choices[0] as Map<String, dynamic>;
      final message = choice['message'] as Map<String, dynamic>?;
      return message?['content'] as String?;
    } catch (_) {
      return null;
    }
  }
}
