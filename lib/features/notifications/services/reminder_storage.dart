import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/scheduled_reminder.dart';

class ReminderStorage {
  ReminderStorage({required this._sharedPrefs});

  final SharedPreferences _sharedPrefs;

  static const _key = 'notifications_reminders';

  List<ScheduledReminder> load() {
    final raw = _sharedPrefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => ScheduledReminder.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      rethrow;
    }
  }

  Future<void> save(List<ScheduledReminder> reminders) {
    final encoded = jsonEncode(reminders.map((r) => r.toJson()).toList());
    return _sharedPrefs.setString(_key, encoded);
  }

  Future<void> clear() => _sharedPrefs.remove(_key);
}
