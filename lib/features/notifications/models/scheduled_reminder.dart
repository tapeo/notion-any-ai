import 'package:equatable/equatable.dart';

class ScheduledReminder extends Equatable {
  const ScheduledReminder({
    required this.id,
    required this.title,
    required this.scheduledAt,
    this.body,
    this.notionPageUrl,
  });

  final String id;
  final String title;
  final DateTime scheduledAt;
  final String? body;
  final String? notionPageUrl;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'scheduled_at': scheduledAt.toUtc().toIso8601String(),
      if (body != null) 'body': body,
      if (notionPageUrl != null) 'notion_page_url': notionPageUrl,
    };
  }

  factory ScheduledReminder.fromJson(Map<String, dynamic> json) {
    return ScheduledReminder(
      id: json['id'] as String,
      title: json['title'] as String,
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      body: json['body'] as String?,
      notionPageUrl: json['notion_page_url'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, title, scheduledAt, body, notionPageUrl];
}