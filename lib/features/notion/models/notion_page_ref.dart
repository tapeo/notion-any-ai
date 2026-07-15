import 'package:equatable/equatable.dart';

class NotionPageRef extends Equatable {
  const NotionPageRef({
    required this.id,
    required this.title,
    this.icon,
    this.url,
    this.objectType,
    this.breadcrumb = const [],
  });

  final String id;
  final String title;
  final String? icon;
  final String? url;
  final String? objectType;
  final List<String> breadcrumb;

  bool get isDataSource => objectType == 'data_source';

  NotionPageRef copyWith({List<String>? breadcrumb}) {
    return NotionPageRef(
      id: id,
      title: title,
      icon: icon,
      url: url,
      objectType: objectType,
      breadcrumb: breadcrumb ?? this.breadcrumb,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    if (icon != null) 'icon': icon,
    if (url != null) 'url': url,
    if (objectType != null) 'object_type': objectType,
    'breadcrumb': breadcrumb,
  };

  factory NotionPageRef.fromJson(Map<String, dynamic> json) {
    final breadcrumbRaw = json['breadcrumb'];
    return NotionPageRef(
      id: json['id'] as String,
      title: json['title'] as String,
      icon: json['icon'] as String?,
      url: json['url'] as String?,
      objectType:
          (json['object_type'] as String?) ?? (json['object'] as String?),
      breadcrumb: breadcrumbRaw is List
          ? breadcrumbRaw.whereType<String>().toList()
          : const [],
    );
  }

  @override
  List<Object?> get props => [id, title, icon, url, objectType, breadcrumb];
}
