import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/scheduled_reminder.dart';

const _androidChannelId = 'notion_any_ai_reminders';
const _androidChannelName = 'Reminders';
const _androidChannelDescription = 'Scheduled reminders from Notion Any AI.';
const _windowsAppUserModelId = 'it.ricu.notionOpenAi';
const _windowsGuid = 'a3f1b2c4-5d6e-4f7a-9b8c-1d2e3f4a5b6c';

class LocalNotificationsService {
  LocalNotificationsService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  final Map<int, Timer> _linuxTimers = {};

  bool get isInitialized => _initialized;

  Future<void> init() async {
    if (_initialized) {
      return;
    }
    tz_data.initializeTimeZones();

    final settings = InitializationSettings(
      android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: const DarwinInitializationSettings(),
      macOS: const DarwinInitializationSettings(),
      linux: const LinuxInitializationSettings(defaultActionName: 'Open'),
      windows: const WindowsInitializationSettings(
        appName: 'Notion Any AI',
        appUserModelId: _windowsAppUserModelId,
        guid: _windowsGuid,
      ),
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
    _initialized = true;
  }

  void _onNotificationResponse(NotificationResponse response) {
    // Tap-to-open deep linking is out of scope for this iteration.
    // Payload carries the reminder id (String) for future use.
  }

  Future<void> requestPermissions() async {
    if (!_initialized) {
      return;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        await android.requestNotificationsPermission();
        await android.requestExactAlarmsPermission();
      }
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        await ios.requestPermissions(alert: true, badge: true, sound: true);
      }
    } else if (defaultTargetPlatform == TargetPlatform.macOS) {
      final macos = _plugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >();
      if (macos != null) {
        await macos.requestPermissions(alert: true, badge: true, sound: true);
      }
    }
  }

  int _toIntId(String id) {
    return id.hashCode & 0x7FFFFFFF;
  }

  NotificationDetails _buildDetails() {
    return NotificationDetails(
      android: const AndroidNotificationDetails(
        _androidChannelId,
        _androidChannelName,
        channelDescription: _androidChannelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      macOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      linux: const LinuxNotificationDetails(
        urgency: LinuxNotificationUrgency.normal,
      ),
      windows: const WindowsNotificationDetails(),
    );
  }

  Future<void> schedule(ScheduledReminder reminder) async {
    if (!_initialized) {
      return;
    }
    final intId = _toIntId(reminder.id);
    final details = _buildDetails();
    final utc = reminder.scheduledAt.toUtc();
    final scheduledDate = tz.TZDateTime.utc(
      utc.year,
      utc.month,
      utc.day,
      utc.hour,
      utc.minute,
      utc.second,
    );

    if (isLinuxPlatform) {
      _scheduleLinuxTimer(intId, reminder, scheduledDate);
      return;
    }

    await _plugin.zonedSchedule(
      id: intId,
      title: reminder.title,
      body: reminder.body,
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: reminder.id,
    );
  }

  void _scheduleLinuxTimer(
    int intId,
    ScheduledReminder reminder,
    tz.TZDateTime scheduledDate,
  ) {
    final now = tz.TZDateTime.now(tz.UTC);
    final delay = scheduledDate.difference(now);
    if (delay.isNegative) {
      return;
    }
    _linuxTimers[intId]?.cancel();
    _linuxTimers[intId] = Timer(delay, () async {
      _linuxTimers.remove(intId);
      await _plugin.show(
        id: intId,
        title: reminder.title,
        body: reminder.body,
        notificationDetails: _buildDetails(),
        payload: reminder.id,
      );
    });
  }

  Future<void> cancel(String id) async {
    if (!_initialized) {
      return;
    }
    final intId = _toIntId(id);
    if (isLinuxPlatform) {
      _linuxTimers[intId]?.cancel();
      _linuxTimers.remove(intId);
    }
    await _plugin.cancel(id: intId);
  }

  Future<void> cancelAll() async {
    if (!_initialized) {
      return;
    }
    if (isLinuxPlatform) {
      for (final timer in _linuxTimers.values) {
        timer.cancel();
      }
      _linuxTimers.clear();
    }
    await _plugin.cancelAll();
  }

  Future<List<int>> pendingIntIds() async {
    if (!_initialized) {
      return const [];
    }
    if (isLinuxPlatform) {
      return _linuxTimers.keys.toList();
    }
    final pending = await _plugin.pendingNotificationRequests();
    return pending.map((p) => p.id).toList();
  }

  void close() {
    for (final timer in _linuxTimers.values) {
      timer.cancel();
    }
    _linuxTimers.clear();
  }
}

bool get isLinuxPlatform => !kIsWeb && Platform.isLinux;
