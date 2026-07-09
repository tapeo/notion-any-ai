import 'package:equatable/equatable.dart';

import '../models/scheduled_reminder.dart';

class NotificationsState extends Equatable {
  const NotificationsState({
    this.reminders = const [],
    this.initialized = false,
    this.saving = false,
  });

  final List<ScheduledReminder> reminders;
  final bool initialized;
  final bool saving;

  NotificationsState copyWith({
    List<ScheduledReminder>? reminders,
    bool? initialized,
    bool? saving,
  }) {
    return NotificationsState(
      reminders: reminders ?? this.reminders,
      initialized: initialized ?? this.initialized,
      saving: saving ?? this.saving,
    );
  }

  @override
  List<Object?> get props => [reminders, initialized, saving];
}