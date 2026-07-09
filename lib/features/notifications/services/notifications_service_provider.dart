import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/services/shared_prefs_provider.dart';
import 'local_notifications_service.dart';
import 'reminder_storage.dart';

final notificationsServiceProvider = Provider<LocalNotificationsService>((ref) {
  final service = LocalNotificationsService();
  ref.onDispose(service.close);
  return service;
});

final reminderStorageProvider = Provider<ReminderStorage>((ref) {
  return ReminderStorage(sharedPrefs: ref.watch(sharedPrefsProvider));
});