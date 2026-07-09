import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notion_page_ref.dart';
import '../providers/notion_connection_notifier.dart';
import 'notion_mcp_client.dart';

class NotionPageSearch {
  NotionPageSearch({required NotionMcpClient mcpClient}) : _mcp = mcpClient;

  final NotionMcpClient _mcp;
  final Map<String, List<String>> _breadcrumbCache = {};

  Future<List<NotionPageRef>> search({
    required String accessToken,
    required String query,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const [];
    }
    final result = await _mcp.callTool(
      accessToken: accessToken,
      name: 'notion_search',
      arguments: <String, dynamic>{'query': trimmed},
    );
    if (result.isError) {
      return const [];
    }
    return _parseResults(result.content);
  }

  /// Resolves the full ancestor title chain (root-first) for [pageId] by
  /// fetching the page via `notion_fetch` and parsing the embedded
  /// `<ancestor-path>` markup. Results are cached per page id.
  Future<List<String>> fetchBreadcrumbForPage({
    required String accessToken,
    required String pageId,
  }) async {
    if (_breadcrumbCache.containsKey(pageId)) {
      return _breadcrumbCache[pageId]!;
    }
    final result = await _mcp.callTool(
      accessToken: accessToken,
      name: 'notion_fetch',
      arguments: <String, dynamic>{'id': pageId},
    );
    if (result.isError) return const [];
    final decoded = _tryDecodeJson(result.content);
    if (decoded is! Map<String, dynamic>) return const [];
    final text = decoded['text'];
    if (text is! String) return const [];
    final chain = _parseAncestorPath(text);
    _breadcrumbCache[pageId] = chain;
    return chain;
  }

  List<String> _parseAncestorPath(String text) {
    final pathStart = text.indexOf('<ancestor-path>');
    if (pathStart < 0) return const [];
    final pathEnd = text.indexOf('</ancestor-path>', pathStart);
    if (pathEnd < 0) return const [];
    final segment = text.substring(
      pathStart + '<ancestor-path>'.length,
      pathEnd,
    );
    final names = <String>[];
    final tagRegex = RegExp(
      r'<(?:parent|ancestor-\d+)-(?:page|data-source|database)\b([^>]*)/>',
    );
    for (final match in tagRegex.allMatches(segment)) {
      final attrs = match.group(1) ?? '';
      final name = _readAttr(attrs, 'name') ?? _readAttr(attrs, 'title');
      if (name != null && name.isNotEmpty) {
        names.add(name);
      }
    }
    return names.reversed.toList();
  }

  String? _readAttr(String attrs, String key) {
    final regex = RegExp('$key="([^"]*)"');
    final match = regex.firstMatch(attrs);
    return match?.group(1);
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
    final pagesField = decoded['pages'];
    if (pagesField is List) {
      for (final item in pagesField) {
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
    final title = _readTitle(item);
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

  String _readTitle(Map<String, dynamic> item) {
    final title = item['title'];
    if (title is String) return title;
    final properties = item['properties'];
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
    final name = item['name'];
    if (name is String) return name;
    return '';
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
  return NotionPageSearch(mcpClient: ref.watch(notionMcpClientProvider));
});
