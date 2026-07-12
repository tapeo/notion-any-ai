import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/scheduled_reminder.dart';
import '../services/notifications_service_provider.dart';
import '../services/reminder_storage.dart';
import '../states/notifications_state.dart';

class NotificationsNotifier extends Notifier<NotificationsState> {
  late ReminderStorage _storage;
  final Uuid _uuid = const Uuid();

  @override
  NotificationsState build() {
    _storage = ref.watch(reminderStorageProvider);
    return const NotificationsState();
  }

  Future<void> init() async {
    final reminders = _storage.load();
    final now = DateTime.now().toUtc();
    final future = <ScheduledReminder>[];
    for (final reminder in reminders) {
      if (reminder.scheduledAt.isAfter(now)) {
        await ref.read(notificationsServiceProvider).schedule(reminder);
        future.add(reminder);
      }
    }
    await _storage.save(future);
    state = state.copyWith(reminders: future, initialized: true);
  }

  Future<String> add({
    required String title,
    required DateTime scheduledAt,
    String? body,
    String? notionPageUrl,
  }) async {
    final now = DateTime.now().toUtc();
    if (!scheduledAt.isAfter(now)) {
      return 'Scheduled time is in the past.';
    }
    final reminder = ScheduledReminder(
      id: _uuid.v4(),
      title: title,
      body: body,
      scheduledAt: scheduledAt.toUtc(),
      notionPageUrl: notionPageUrl,
    );
    state = state.copyWith(saving: true);
    await ref.read(notificationsServiceProvider).schedule(reminder);
    final next = [...state.reminders, reminder];
    await _storage.save(next);
    state = state.copyWith(reminders: next, saving: false);
    return reminder.id;
  }

  Future<void> remove(String id) async {
    state = state.copyWith(saving: true);
    await ref.read(notificationsServiceProvider).cancel(id);
    final next = state.reminders.where((r) => r.id != id).toList();
    await _storage.save(next);
    state = state.copyWith(reminders: next, saving: false);
  }

  Future<void> removeAll() async {
    state = state.copyWith(saving: true);
    await ref.read(notificationsServiceProvider).cancelAll();
    await _storage.clear();
    state = state.copyWith(reminders: const [], saving: false);
  }
}

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, NotificationsState>(
      NotificationsNotifier.new,
    );
