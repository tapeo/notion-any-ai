import 'dart:convert';
import 'dart:io';

import '../models/conversation.dart';

class ConversationStorage {
  ConversationStorage({required Directory appDir})
      : _dir = Directory('${appDir.path}/conversations');

  final Directory _dir;

  File get _indexFile => File('${_dir.path}/index.json');

  File _conversationFile(String id) => File('${_dir.path}/$id.json');

  File conversationFile(String id) => _conversationFile(id);

  Directory get conversationsDir => _dir;

  Future<void> ensureDir() async {
    if (!_dir.existsSync()) {
      await _dir.create(recursive: true);
    }
  }

  List<ConversationSummary> loadIndex() {
    if (!_indexFile.existsSync()) {
      return const [];
    }
    try {
      final raw = _indexFile.readAsStringSync();
      if (raw.isEmpty) return const [];
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) =>
              ConversationSummary.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (_) {
      return const [];
    }
  }

  Conversation? loadConversation(String id) {
    final file = _conversationFile(id);
    if (!file.existsSync()) return null;
    try {
      final raw = file.readAsStringSync();
      if (raw.isEmpty) return null;
      return Conversation.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveConversation(Conversation conversation) async {
    await ensureDir();
    final file = _conversationFile(conversation.id);
    final encoded = jsonEncode(conversation.toJson());
    await _writeAtomic(file, encoded);
    await _upsertIndex(conversation.toSummary());
  }

  Future<void> deleteConversation(String id) async {
    final file = _conversationFile(id);
    if (file.existsSync()) {
      await file.delete();
    }
    await _removeFromIndex(id);
  }

  Future<void> _upsertIndex(ConversationSummary summary) async {
    final current = loadIndex();
    final updated = current.where((s) => s.id != summary.id).toList()
      ..insert(0, summary)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    await _writeIndex(updated);
  }

  Future<void> _removeFromIndex(String id) async {
    final current = loadIndex();
    final updated = current.where((s) => s.id != id).toList();
    await _writeIndex(updated);
  }

  Future<void> _writeIndex(List<ConversationSummary> summaries) async {
    await ensureDir();
    final encoded = jsonEncode(summaries.map((s) => s.toJson()).toList());
    await _writeAtomic(_indexFile, encoded);
  }

  Future<void> _writeAtomic(File file, String content) async {
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(content, flush: true);
    await temp.rename(file.path);
  }
}