import 'package:equatable/equatable.dart';

class NotionPageRef extends Equatable {
  const NotionPageRef({
    required this.id,
    required this.title,
    this.icon,
    this.url,
    this.breadcrumb = const [],
  });

  final String id;
  final String title;
  final String? icon;
  final String? url;
  final List<String> breadcrumb;

  NotionPageRef copyWith({List<String>? breadcrumb}) {
    return NotionPageRef(
      id: id,
      title: title,
      icon: icon,
      url: url,
      breadcrumb: breadcrumb ?? this.breadcrumb,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (icon != null) 'icon': icon,
        if (url != null) 'url': url,
        'breadcrumb': breadcrumb,
      };

  factory NotionPageRef.fromJson(Map<String, dynamic> json) {
    final breadcrumbRaw = json['breadcrumb'];
    return NotionPageRef(
      id: json['id'] as String,
      title: json['title'] as String,
      icon: json['icon'] as String?,
      url: json['url'] as String?,
      breadcrumb: breadcrumbRaw is List
          ? breadcrumbRaw.whereType<String>().toList()
          : const [],
    );
  }

  @override
  List<Object?> get props => [id, title, icon, url, breadcrumb];
}