// Converts an MCP tool inputSchema into a clean OpenAI function-calling schema
// by stripping JSON Schema constructs that OpenAI does not reliably support
// ($ref/$defs, anyOf, oneOf, allOf) and ensuring the top-level shape is a
// flat {type: object, properties, required} document.
Map<String, dynamic> normalizeOpenAiSchema(Map<String, dynamic> inputSchema) {
  final defs = <String, Map<String, dynamic>>{};
  final defsField = inputSchema['\$defs'] ?? inputSchema['definitions'];
  if (defsField is Map<String, dynamic>) {
    for (final entry in defsField.entries) {
      if (entry.value is Map<String, dynamic>) {
        defs[entry.key] = entry.value as Map<String, dynamic>;
      }
    }
  }
  final normalized = _normalizeNode(inputSchema, defs);
  if (normalized['type'] != 'object') {
    normalized['type'] = 'object';
  }
  normalized['properties'] ??= <String, dynamic>{};
  normalized['required'] ??= <String>[];
  return normalized;
}

Map<String, dynamic> _normalizeNode(
  Map<String, dynamic> node,
  Map<String, Map<String, dynamic>> defs,
) {
  if (node['\$ref'] is String) {
    final resolved = _resolveRef(node['\$ref'] as String, defs);
    if (resolved != null) {
      return _normalizeNode(resolved, defs);
    }
    return {'type': 'string'};
  }

  final result = <String, dynamic>{};

  if (node['anyOf'] is List || node['oneOf'] is List) {
    final branches = (node['anyOf'] as List?) ?? (node['oneOf'] as List?)!;
    final picked = _pickBranch(branches, defs);
    if (picked != null) {
      result.addAll(picked);
    }
  } else if (node['allOf'] is List) {
    for (final branch in node['allOf'] as List) {
      if (branch is Map<String, dynamic>) {
        final normalized = _normalizeNode(branch, defs);
        _mergeAllOf(result, normalized);
      }
    }
  }

  for (final entry in node.entries) {
    final key = entry.key;
    if (key == '\$ref' ||
        key == '\$defs' ||
        key == 'definitions' ||
        key == 'anyOf' ||
        key == 'oneOf' ||
        key == 'allOf') {
      continue;
    }
    if (result.containsKey(key)) {
      continue;
    }
    result[key] = _normalizeValue(entry.value, defs);
  }

  return result;
}

Map<String, dynamic>? _pickBranch(
  List branches,
  Map<String, Map<String, dynamic>> defs,
) {
  Map<String, dynamic>? firstNonNull;
  for (final branch in branches) {
    if (branch is! Map<String, dynamic>) continue;
    final normalized = _normalizeNode(branch, defs);
    final type = normalized['type'];
    if (type == 'null') continue;
    firstNonNull ??= normalized;
    if (type is String && type != 'object' && type != 'array') {
      return normalized;
    }
  }
  return firstNonNull;
}

void _mergeAllOf(
  Map<String, dynamic> target,
  Map<String, dynamic> source,
) {
  final sourceProps = source['properties'];
  final targetProps = target['properties'];
  if (sourceProps is Map<String, dynamic> && targetProps is Map<String, dynamic>) {
    targetProps.addAll(sourceProps);
  } else if (sourceProps is Map<String, dynamic>) {
    target['properties'] = Map<String, dynamic>.from(sourceProps);
  }
  final sourceRequired = source['required'];
  final targetRequired = target['required'];
  if (sourceRequired is List && targetRequired is List) {
    for (final r in sourceRequired) {
      if (!targetRequired.contains(r)) targetRequired.add(r);
    }
  } else if (sourceRequired is List) {
    target['required'] = List<dynamic>.from(sourceRequired);
  }
  for (final entry in source.entries) {
    if (entry.key == 'properties' || entry.key == 'required') continue;
    if (!target.containsKey(entry.key)) {
      target[entry.key] = entry.value;
    }
  }
}

Map<String, dynamic>? _resolveRef(
  String ref,
  Map<String, Map<String, dynamic>> defs,
) {
  if (ref.startsWith('#/')) {
    final segments = ref.substring(2).split('/');
    Map<String, dynamic>? current;
    if (segments.isNotEmpty &&
        (segments[0] == '\$defs' || segments[0] == 'definitions') &&
        segments.length == 2) {
      current = defs[segments[1]];
    }
    return current;
  }
  return null;
}

dynamic _normalizeValue(
  dynamic value,
  Map<String, Map<String, dynamic>> defs,
) {
  if (value is Map<String, dynamic>) {
    if (value['\$ref'] is String ||
        value['anyOf'] is List ||
        value['oneOf'] is List ||
        value['allOf'] is List) {
      return _normalizeNode(value, defs);
    }
    final normalized = <String, dynamic>{};
    for (final entry in value.entries) {
      normalized[entry.key] = _normalizeValue(entry.value, defs);
    }
    return normalized;
  }
  if (value is List) {
    return value.map((e) => _normalizeValue(e, defs)).toList();
  }
  return value;
}