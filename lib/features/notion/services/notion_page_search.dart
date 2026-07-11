import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notion_page_ref.dart';
import '../providers/notion_connection_notifier.dart';
import 'notion_api_client.dart';

class NotionPageSearch {
  NotionPageSearch({required NotionApiClient apiClient}) : _api = apiClient;

  final NotionApiClient _api;
  final Map<String, List<String>> _breadcrumbCache = {};

  Future<List<NotionPageRef>> search({
    required String accessToken,
    required String query,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const [];
    }
    final result = await _api.callTool(
      accessToken: accessToken,
      name: 'notion_search',
      arguments: <String, dynamic>{'query': trimmed},
    );
    if (result.isError) {
      return const [];
    }
    return _parseResults(result.content);
  }

  Future<List<String>> fetchBreadcrumbForPage({
    required String accessToken,
    required String pageId,
  }) async {
    if (_breadcrumbCache.containsKey(pageId)) {
      return _breadcrumbCache[pageId]!;
    }

    final chain = <String>[];
    var currentId = pageId;
    final visited = <String>{};

    while (currentId.isNotEmpty && !visited.contains(currentId)) {
      visited.add(currentId);
      final result = await _api.callTool(
        accessToken: accessToken,
        name: 'notion_fetch_page',
        arguments: <String, dynamic>{'page_id': currentId},
      );
      if (result.isError) break;

      final decoded = _tryDecodeJson(result.content);
      if (decoded is! Map<String, dynamic>) break;

      final title = _extractTitle(decoded);
      if (title.isNotEmpty) {
        chain.insert(0, title);
      }

      final parent = decoded['parent'];
      if (parent is! Map<String, dynamic>) break;

      final parentType = parent['type'] as String?;
      if (parentType == 'page_id') {
        currentId = parent['page_id'] as String? ?? '';
      } else {
        break;
      }
    }

    _breadcrumbCache[pageId] = chain;
    return chain;
  }

  String _extractTitle(Map<String, dynamic> page) {
    final properties = page['properties'];
    if (properties is Map<String, dynamic>) {
      final titleProp = properties['title'];
      if (titleProp is Map<String, dynamic>) {
        final titleArray = titleProp['title'];
        if (titleArray is List) {
          final parts = <String>[];
          for (final part in titleArray) {
            if (part is Map<String, dynamic>) {
              final plain = part['plain_text'];
              if (plain is String) parts.add(plain);
            }
          }
          if (parts.isNotEmpty) return parts.join();
        }
      }
    }
    final title = page['title'];
    if (title is String) return title;
    final name = page['name'];
    if (name is String) return name;
    return '';
  }

  List<NotionPageRef> _parseResults(String content) {
    if (content.isEmpty) return const [];
    final decoded = _tryDecodeJson(content);
    if (decoded == null) return const [];
    return _extractPages(decoded);
  }

  dynamic _tryDecodeJson(String content) {
    try {
      return jsonDecode(content);
    } catch (_) {
      return null;
    }
  }

  List<NotionPageRef> _extractPages(dynamic decoded) {
    final results = <NotionPageRef>[];
    if (decoded is! Map<String, dynamic>) return results;
    final candidates = <Map<String, dynamic>>[];
    final resultsField = decoded['results'];
    if (resultsField is List) {
      for (final item in resultsField) {
        if (item is Map<String, dynamic>) candidates.add(item);
      }
    }
    if (candidates.isEmpty && decoded.containsKey('id')) {
      candidates.add(decoded);
    }
    for (final item in candidates) {
      final ref = _mapPage(item);
      if (ref != null) results.add(ref);
    }
    return results;
  }

  NotionPageRef? _mapPage(Map<String, dynamic> item) {
    final id = _readId(item);
    final title = _extractTitle(item);
    if (id == null || title.isEmpty) return null;
    final icon = _readIcon(item);
    final url = item['url'] as String?;
    return NotionPageRef(id: id, title: title, icon: icon, url: url);
  }

  String? _readId(Map<String, dynamic> item) {
    final id = item['id'];
    if (id is String && id.isNotEmpty) return id;
    return null;
  }

  String? _readIcon(Map<String, dynamic> item) {
    final icon = item['icon'];
    if (icon is Map<String, dynamic>) {
      final emoji = icon['emoji'];
      if (emoji is String) return emoji;
    }
    return null;
  }
}

final notionPageSearchProvider = Provider<NotionPageSearch>((ref) {
  return NotionPageSearch(apiClient: ref.watch(notionApiClientProvider));
});