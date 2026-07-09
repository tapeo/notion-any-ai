import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/services/shared_prefs_provider.dart';
import '../models/notion_page_ref.dart';

class NotionRecentPagesStorage {
  NotionRecentPagesStorage({required this.sharedPrefs});

  final SharedPreferences sharedPrefs;
  static const _key = 'notion_recent_pages';
  static const _maxEntries = 20;

  List<NotionPageRef> load() {
    final raw = sharedPrefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final pages = <NotionPageRef>[];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          pages.add(NotionPageRef.fromJson(item));
        }
      }
      return pages;
    } catch (_) {
      return const [];
    }
  }

  Future<void> record(NotionPageRef page) async {
    final current = load();
    final deduped = current.where((p) => p.id != page.id).toList();
    deduped.insert(0, page);
    final trimmed = deduped.length > _maxEntries
        ? deduped.sublist(0, _maxEntries)
        : deduped;
    await _save(trimmed);
  }

  Future<void> clear() async {
    await sharedPrefs.remove(_key);
  }

  Future<void> _save(List<NotionPageRef> pages) async {
    final encoded = jsonEncode(pages.map((p) => p.toJson()).toList());
    await sharedPrefs.setString(_key, encoded);
  }
}

final notionRecentPagesStorageProvider =
    Provider<NotionRecentPagesStorage>((ref) {
  return NotionRecentPagesStorage(
    sharedPrefs: ref.watch(sharedPrefsProvider),
  );
});