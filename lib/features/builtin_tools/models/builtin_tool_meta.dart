// Metadata and registry for built-in (local) tools the assistant can call.
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../chat/models/tool_call.dart' show ToolCall;
import '../../memory/models/memory_section.dart';
import '../../memory/providers/memory_notifier.dart';
import '../../notifications/providers/notifications_provider.dart';
import '../models/pending_question.dart';
import '../providers/pending_question_provider.dart';

typedef BuiltinToolExecutor =
    Future<String> Function(Map<String, dynamic> arguments, Ref ref);

class BuiltinToolMeta extends Equatable {
  const BuiltinToolMeta({
    required this.id,
    required this.name,
    required this.description,
    required this.parameters,
    required this.executor,
  });

  final String id;
  final String name;
  final String description;
  final Map<String, dynamic> parameters;
  final BuiltinToolExecutor executor;

  Map<String, dynamic> toOpenAiSchema() {
    return {
      'type': 'function',
      'function': {
        'name': name,
        'description': description,
        'parameters': parameters,
      },
    };
  }

  @override
  List<Object?> get props => [id, name, description, parameters];
}

Future<String> _formatGetCurrentDateTime(
  Map<String, dynamic> arguments,
  Ref ref,
) async {
  final now = DateTime.now();
  final iso = now.toIso8601String();
  final humanReadable =
      '${_weekdayName(now.weekday)}, ${now.day.toString().padLeft(2, '0')} '
      '${_monthName(now.month)} ${now.year} '
      '${now.hour.toString().padLeft(2, '0')}:'
      '${now.minute.toString().padLeft(2, '0')}:'
      '${now.second.toString().padLeft(2, '0')} '
      '(local, UTC${now.timeZoneOffset.isNegative ? '-' : '+'}'
      '${now.timeZoneOffset.inHours.abs().toString().padLeft(2, '0')}:00)';
  return '$iso\n$humanReadable';
}

String _weekdayName(int weekday) {
  const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return names[weekday - 1];
}

String _monthName(int month) {
  const names = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return names[month - 1];
}

String _formatLocalDateTime(DateTime dt) {
  final local = dt.toLocal();
  return '${_weekdayName(local.weekday)}, ${local.day} ${_monthName(local.month)} '
      '${local.year} ${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')} '
      '(local, UTC${local.timeZoneOffset.isNegative ? '-' : '+'}'
      '${local.timeZoneOffset.inHours.abs().toString().padLeft(2, '0')}:00)';
}

Future<String> _scheduleReminder(
  Map<String, dynamic> arguments,
  Ref ref,
) async {
  final title = arguments['title'] as String?;
  final scheduledAtRaw = arguments['scheduled_at'] as String?;
  if (title == null || title.isEmpty) {
    return 'Tool error: Missing required parameter \'title\' for schedule_reminder.';
  }
  if (scheduledAtRaw == null || scheduledAtRaw.isEmpty) {
    return 'Tool error: Missing required parameter \'scheduled_at\' for schedule_reminder.';
  }
  DateTime scheduledAt;
  try {
    scheduledAt = DateTime.parse(scheduledAtRaw);
  } catch (_) {
    return 'Tool error: \'scheduled_at\' must be an ISO 8601 timestamp with '
        'timezone offset. Got: $scheduledAtRaw';
  }
  final body = arguments['body'] as String?;
  final notionPageUrl = arguments['notion_page_url'] as String?;
  final notifier = ref.read(notificationsProvider.notifier);
  final idOrError = await notifier.add(
    title: title,
    scheduledAt: scheduledAt,
    body: body,
    notionPageUrl: notionPageUrl,
  );
  if (idOrError.startsWith('Scheduled time is in the past')) {
    return 'Tool error: $idOrError';
  }
  return 'Scheduled reminder \'$idOrError\' for "$title" at '
      '${_formatLocalDateTime(scheduledAt)}.'
      '${notionPageUrl != null ? ' Linked Notion page: $notionPageUrl.' : ''}';
}

Future<String> _readMemory(Map<String, dynamic> arguments, Ref ref) async {
  final content = ref.read(memoryProvider).content;
  if (content.trim().isEmpty) {
    return 'Memory is empty.';
  }
  return content;
}

Future<String> _searchMemory(Map<String, dynamic> arguments, Ref ref) async {
  final query = arguments['query'] as String?;
  if (query == null || query.trim().isEmpty) {
    return 'Tool error: Missing required parameter \'query\' for search_memory.';
  }
  final content = ref.read(memoryProvider).content;
  final doc = parseMemory(content);
  final matches = searchSections(doc, query);
  if (matches.isEmpty) {
    return 'No memory sections matching "$query".';
  }
  final lines = <String>[];
  for (final s in matches) {
    final block = StringBuffer('## ${s.title}');
    if (s.content.trim().isNotEmpty) {
      block.writeln();
      block.write(s.content.trim());
    }
    lines.add(block.toString());
  }
  return lines.join('\n\n---\n\n');
}

Future<String> _addMemory(Map<String, dynamic> arguments, Ref ref) async {
  final title = arguments['title'] as String?;
  final content = arguments['content'] as String?;
  if (title == null || title.trim().isEmpty) {
    return 'Tool error: Missing required parameter \'title\' for add_memory.';
  }
  if (content == null) {
    return 'Tool error: Missing required parameter \'content\' for add_memory.';
  }
  return ref.read(memoryProvider.notifier).addSection(title, content);
}

Future<String> _deleteMemory(Map<String, dynamic> arguments, Ref ref) async {
  final title = arguments['title'] as String?;
  if (title == null || title.trim().isEmpty) {
    return 'Tool error: Missing required parameter \'title\' for delete_memory.';
  }
  return ref.read(memoryProvider.notifier).deleteSection(title);
}

Future<String> _listReminders(Map<String, dynamic> arguments, Ref ref) async {
  final reminders = ref.read(notificationsProvider).reminders;
  if (reminders.isEmpty) {
    return 'No scheduled reminders.';
  }
  final lines = <String>[];
  for (var i = 0; i < reminders.length; i++) {
    final r = reminders[i];
    final line =
        '${i + 1}. ${r.title} — ${_formatLocalDateTime(r.scheduledAt)}'
        ' (id: ${r.id})';
    if (r.notionPageUrl != null) {
      lines.add('$line [notion: ${r.notionPageUrl}]');
    } else {
      lines.add(line);
    }
  }
  return lines.join('\n');
}

Future<String> _cancelReminder(Map<String, dynamic> arguments, Ref ref) async {
  final id = arguments['id'] as String?;
  if (id == null || id.isEmpty) {
    return 'Tool error: Missing required parameter \'id\' for cancel_reminder.';
  }
  final reminders = ref.read(notificationsProvider).reminders;
  final exists = reminders.any((r) => r.id == id);
  if (!exists) {
    return 'No reminder with id \'$id\'.';
  }
  final notifier = ref.read(notificationsProvider.notifier);
  await notifier.remove(id);
  return 'Cancelled reminder \'$id\'.';
}

Future<String> _fetchUrl(Map<String, dynamic> arguments, Ref ref) async {
  final url = arguments['url'] as String?;
  if (url == null || url.trim().isEmpty) {
    return 'Tool error: Missing required parameter \'url\' for fetch_url.';
  }
  Uri uri;
  try {
    uri = Uri.parse(url.trim());
  } catch (_) {
    return 'Tool error: Invalid URL: $url';
  }
  if (!uri.hasScheme || !uri.hasAuthority) {
    return 'Tool error: Invalid URL: $url';
  }
  final client = http.Client();
  try {
    final res = await client
        .get(
          uri,
          headers: {
            'User-Agent': 'notion_any_ai/0.1 (+https://notion.so)',
            'Accept': 'text/html,application/xhtml+xml,text/plain,*/*',
          },
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      return 'Tool error: HTTP ${res.statusCode} fetching $url';
    }
    final document = html_parser.parse(res.body);
    document
        .querySelectorAll('script, style, noscript, template')
        .forEach((el) => el.remove());
    final text = document.body?.text ?? '';
    final collapsed = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (collapsed.isEmpty) {
      return 'Fetched $url but no readable text was found.';
    }
    return collapsed;
  } on TimeoutException {
    return 'Tool error: Request to $url timed out after 10 seconds.';
  } catch (err) {
    return 'Tool error: $err';
  } finally {
    client.close();
  }
}

Future<String> _askUser(Map<String, dynamic> arguments, Ref ref) async {
  final question = arguments['question'] as String?;
  if (question == null || question.trim().isEmpty) {
    return 'Tool error: Missing required parameter \'question\' for ask_user.';
  }
  final pendingState = ref.read(pendingQuestionProvider);
  if (pendingState.pending != null) {
    return 'Tool error: Another question is already pending. '
        'Ask one question at a time.';
  }
  final optionsRaw = arguments['options'] as List?;
  final options = optionsRaw
      ?.map((e) => e.toString())
      .where((s) => s.isNotEmpty)
      .toList();
  final context = arguments['context'] as String?;
  final uuid = const Uuid().v4();
  final pending = PendingQuestion(
    id: uuid,
    question: question.trim(),
    options: options,
    context: context,
  );
  return ref.read(pendingQuestionProvider.notifier).ask(pending);
}

class BuiltinToolRegistry {
  BuiltinToolRegistry._();

  static const String getCurrentDateTimeId = 'get_current_datetime';
  static const String scheduleReminderId = 'schedule_reminder';
  static const String listRemindersId = 'list_reminders';
  static const String cancelReminderId = 'cancel_reminder';
  static const String readMemoryId = 'read_memory';
  static const String searchMemoryId = 'search_memory';
  static const String addMemoryId = 'add_memory';
  static const String deleteMemoryId = 'delete_memory';
  static const String fetchUrlId = 'fetch_url';
  static const String askUserId = 'ask_user';

  static const Set<String> memoryToolIds = {
    readMemoryId,
    searchMemoryId,
    addMemoryId,
    deleteMemoryId,
  };

  static bool isMemoryTool(String id) => memoryToolIds.contains(id);

  static final List<BuiltinToolMeta> all = [
    BuiltinToolMeta(
      id: getCurrentDateTimeId,
      name: 'get_current_datetime',
      description:
          'Get the current date and time in the user\'s local '
          'timezone. Returns an ISO 8601 timestamp and a human-readable '
          'string. Takes no parameters. Use when the user asks about the '
          'current date, time, day of the week, or anything that requires '
          'knowing "now".',
      parameters: const {
        'type': 'object',
        'properties': <String, dynamic>{},
        'required': <String>[],
      },
      executor: _formatGetCurrentDateTime,
    ),
    BuiltinToolMeta(
      id: scheduleReminderId,
      name: 'schedule_reminder',
      description:
          'Schedule a local push notification reminder to fire on '
          'the user\'s device at a specified future time. Use this when the '
          'user asks to be reminded of something, especially for tasks with a '
          'due date. The scheduled_at must be an ISO 8601 timestamp with '
          'timezone offset (e.g. 2026-07-10T09:00:00+02:00). Returns the '
          'reminder id and confirmation. The reminder persists across app '
          'restarts on iOS, Android, macOS, and Windows. On Linux it only '
          'fires while the app is running.',
      parameters: const {
        'type': 'object',
        'properties': {
          'title': {
            'type': 'string',
            'description': 'Short title shown in the notification.',
          },
          'scheduled_at': {
            'type': 'string',
            'description':
                'ISO 8601 timestamp with timezone offset for when '
                'the reminder should fire, e.g. 2026-07-10T09:00:00+02:00.',
          },
          'body': {
            'type': 'string',
            'description': 'Optional longer body text for the notification.',
          },
          'notion_page_url': {
            'type': 'string',
            'description':
                'Optional URL of a related Notion page to '
                'associate with the reminder for future deep-linking.',
          },
        },
        'required': ['title', 'scheduled_at'],
      },
      executor: _scheduleReminder,
    ),
    BuiltinToolMeta(
      id: listRemindersId,
      name: 'list_reminders',
      description:
          'List all currently scheduled local reminders with their '
          'id, title, scheduled time, and optional Notion page link. Use when '
          'the user asks what reminders are set. Takes no parameters.',
      parameters: const {
        'type': 'object',
        'properties': <String, dynamic>{},
        'required': <String>[],
      },
      executor: _listReminders,
    ),
    BuiltinToolMeta(
      id: cancelReminderId,
      name: 'cancel_reminder',
      description:
          'Cancel a previously scheduled local reminder by its id. '
          'Use the id returned by schedule_reminder or shown by '
          'list_reminders. Returns confirmation or an error if no reminder '
          'matches the id.',
      parameters: const {
        'type': 'object',
        'properties': {
          'id': {
            'type': 'string',
            'description': 'The id of the reminder to cancel.',
          },
        },
        'required': ['id'],
      },
      executor: _cancelReminder,
    ),
    BuiltinToolMeta(
      id: readMemoryId,
      name: 'read_memory',
      description:
          'Read the full contents of the shared persistent memory '
          'file (memory.md). Returns the raw markdown content, or '
          '"Memory is empty." if no memory has been stored. Use when the user '
          'asks what you remember, or when you need to recall facts, '
          'preferences, or context stored earlier. Takes no parameters.',
      parameters: const {
        'type': 'object',
        'properties': <String, dynamic>{},
        'required': <String>[],
      },
      executor: _readMemory,
    ),
    BuiltinToolMeta(
      id: searchMemoryId,
      name: 'search_memory',
      description:
          'Search the shared persistent memory for sections whose '
          'title or content contains the query string (case-insensitive). '
          'Returns matching sections as markdown joined by "---", or a '
          '"no matches" message. Use when you need a specific fact from '
          'memory without loading the whole file.',
      parameters: const {
        'type': 'object',
        'properties': {
          'query': {
            'type': 'string',
            'description':
                'Text to search for across memory section titles '
                'and contents.',
          },
        },
        'required': ['query'],
      },
      executor: _searchMemory,
    ),
    BuiltinToolMeta(
      id: addMemoryId,
      name: 'add_memory',
      description:
          'Add or update a titled section in the shared persistent '
          'memory. If a section with the same title already exists (case-'
          'insensitive), its content is replaced. Otherwise a new section '
          'is appended. The section is written as "## {title}\\n{content}" '
          'in memory.md. Use when the user asks you to remember a fact, '
          'preference, or piece of context for later. Returns a confirmation '
          'stating whether the section was added or updated.',
      parameters: const {
        'type': 'object',
        'properties': {
          'title': {
            'type': 'string',
            'description':
                'Title of the memory section. Becomes the "## " '
                'heading in memory.md.',
          },
          'content': {
            'type': 'string',
            'description':
                'Body content of the memory section. Free-form '
                'markdown text.',
          },
        },
        'required': ['title', 'content'],
      },
      executor: _addMemory,
    ),
    BuiltinToolMeta(
      id: deleteMemoryId,
      name: 'delete_memory',
      description:
          'Delete a titled section from the shared persistent '
          'memory by its title (case-insensitive match). Returns a '
          'confirmation, or a "no section" message if the title does not '
          'exist. Use when the user asks you to forget something or remove '
          'outdated information from memory.',
      parameters: const {
        'type': 'object',
        'properties': {
          'title': {
            'type': 'string',
            'description': 'Title of the memory section to delete.',
          },
        },
        'required': ['title'],
      },
      executor: _deleteMemory,
    ),
    BuiltinToolMeta(
      id: fetchUrlId,
      name: 'fetch_url',
      description:
          'Fetch the content of a web page at a given URL and return '
          'it as readable plain text with HTML tags, scripts, styles, and '
          'templates stripped. Useful when the user asks about the contents '
          'of a web page or when up-to-date information from a specific URL is '
          'needed. Only HTTP and HTTPS URLs are supported. The request times '
          'out after 10 seconds. Returns the cleaned text, or an error '
          'message prefixed with "Tool error:".',
      parameters: const {
        'type': 'object',
        'properties': {
          'url': {
            'type': 'string',
            'description':
                'The absolute URL (including http:// or https://) '
                'of the web page to fetch.',
          },
        },
        'required': ['url'],
      },
      executor: _fetchUrl,
    ),
    BuiltinToolMeta(
      id: askUserId,
      name: 'ask_user',
      description:
          'Ask the user a question when you need more information to '
          'proceed. Use this when the request is ambiguous, missing required '
          'details, or when you need confirmation before taking an action. '
          'Pass \'question\' with the text to show. Optionally pass \'options\' '
          'as a list of strings for a multiple-choice question. If \'options\' '
          'is omitted the user can type a free-text answer. Optionally pass '
          '\'context\' to explain why you are asking. The tool returns the '
          'user\'s answer as a string, or \'User dismissed the question.\' if '
          'they skipped it. Only one question can be pending at a time.',
      parameters: const {
        'type': 'object',
        'properties': {
          'question': {
            'type': 'string',
            'description': 'The question to ask the user.',
          },
          'options': {
            'type': 'array',
            'items': {'type': 'string'},
            'description':
                'Optional list of choices. If provided, the user '
                'selects one (or types "Other"). If omitted, the user types '
                'a free-text answer.',
          },
          'context': {
            'type': 'string',
            'description':
                'Optional explanation of why you are asking, shown as '
                'helper text below the question.',
          },
        },
        'required': ['question'],
      },
      executor: _askUser,
    ),
  ];

  static BuiltinToolMeta? byId(String id) {
    for (final tool in all) {
      if (tool.id == id) {
        return tool;
      }
    }
    return null;
  }

  static BuiltinToolMeta? byName(String name) {
    for (final tool in all) {
      if (tool.name == name) {
        return tool;
      }
    }
    return null;
  }
}

bool isBuiltinTool(String name) => BuiltinToolRegistry.byName(name) != null;

Future<String> executeBuiltinTool(ToolCall call, Ref ref) async {
  final tool = BuiltinToolRegistry.byName(call.name);
  if (tool == null) {
    return 'Tool error: Unknown built-in tool "${call.name}".';
  }
  try {
    return await tool.executor(call.arguments, ref);
  } catch (err) {
    return 'Tool error: $err';
  }
}
