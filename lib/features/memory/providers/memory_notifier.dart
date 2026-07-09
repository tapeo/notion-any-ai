import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/memory_section.dart';
import '../services/memory_storage.dart';
import '../states/memory_state.dart';
import 'memory_storage_provider.dart';

class MemoryNotifier extends Notifier<MemoryState> {
  late MemoryStorage _storage;

  @override
  MemoryState build() {
    _storage = ref.watch(memoryStorageProvider);
    return const MemoryState();
  }

  Future<void> init() async {
    final content = _storage.load();
    state = state.copyWith(content: content);
  }

  Future<void> save(String content) async {
    state = state.copyWith(saving: true);
    await _storage.save(content);
    state = state.copyWith(content: content, saving: false);
  }

  Future<void> clear() async {
    state = state.copyWith(saving: true);
    await _storage.clear();
    state = state.copyWith(content: '', saving: false);
  }

  Future<String> addSection(String title, String content) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      return 'Tool error: Missing required parameter \'title\' for add_memory.';
    }
    final current = state.content;
    final doc = parseMemory(current);
    final updated = upsertSection(doc, MemorySection(
      title: trimmedTitle,
      content: content.trim(),
    ));
    final serialized = serializeMemory(updated);
    await save(serialized);
    final action = doc.sections.any((s) =>
            s.title.toLowerCase() == trimmedTitle.toLowerCase())
        ? 'Updated'
        : 'Added';
    return '$action memory section "$trimmedTitle".';
  }

  Future<String> deleteSection(String title) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      return 'Tool error: Missing required parameter \'title\' for delete_memory.';
    }
    final current = state.content;
    final doc = parseMemory(current);
    final existed = doc.sections
        .any((s) => s.title.toLowerCase() == trimmedTitle.toLowerCase());
    if (!existed) {
      return 'No memory section titled "$trimmedTitle".';
    }
    final updated = removeSection(doc, trimmedTitle);
    final serialized = serializeMemory(updated);
    await save(serialized);
    return 'Deleted memory section "$trimmedTitle".';
  }
}

final memoryProvider =
    NotifierProvider<MemoryNotifier, MemoryState>(
  MemoryNotifier.new,
);