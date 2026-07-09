import 'dart:io';

import 'package:http/http.dart' as http;

class TranscriptionClient {
  TranscriptionClient._();

  static const endpoint = 'https://api.openai.com/v1';

  static Future<String> transcribe({
    required String apiKey,
    required String model,
    required String audioPath,
    required String language,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$endpoint/audio/transcriptions'),
    );
    request.headers['Authorization'] = 'Bearer $apiKey';
    request.fields['model'] = model;
    request.fields['language'] = language;
    request.fields['response_format'] = 'json';
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        audioPath,
        filename: 'recording.m4a',
      ),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Transcription failed (${response.statusCode}): ${response.body}',
      );
    }

    final body = response.body;
    final textMatch = RegExp(
      r'"text"\s*:\s*"((?:[^"\\]|\\.)*)"',
    ).firstMatch(body);
    final text = textMatch != null
        ? textMatch.group(1)!.replaceAll('\\n', '\n').replaceAll('\\"', '"')
        : '';

    if (text.trim().isEmpty) {
      throw Exception('No speech detected');
    }
    return text.trim();
  }

  static void cleanupFile(String path) {
    final file = File(path);
    if (file.existsSync()) {
      file.deleteSync();
    }
  }
}
