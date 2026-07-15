import 'package:equatable/equatable.dart';

class NotionTokens extends Equatable {
  const NotionTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresAt,
    this.workspaceId,
    this.workspaceName,
    this.userName,
    this.botId,
    required this.connectedAt,
  });

  final String accessToken;
  final String refreshToken;
  final int accessTokenExpiresAt;
  final String? workspaceId;
  final String? workspaceName;
  final String? userName;
  final String? botId;
  final int connectedAt;

  bool get isExpired =>
      DateTime.now().millisecondsSinceEpoch >= accessTokenExpiresAt;

  NotionTokens copyWith({
    String? accessToken,
    String? refreshToken,
    int? accessTokenExpiresAt,
    String? workspaceId,
    String? workspaceName,
    String? userName,
    String? botId,
  }) {
    return NotionTokens(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      accessTokenExpiresAt: accessTokenExpiresAt ?? this.accessTokenExpiresAt,
      workspaceId: workspaceId ?? this.workspaceId,
      workspaceName: workspaceName ?? this.workspaceName,
      userName: userName ?? this.userName,
      botId: botId ?? this.botId,
      connectedAt: connectedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'access_token_expires_at': accessTokenExpiresAt,
      'workspace_id': workspaceId,
      'workspace_name': workspaceName,
      'user_name': userName,
      'bot_id': botId,
      'connected_at': connectedAt,
    };
  }

  factory NotionTokens.fromJson(Map<String, dynamic> json) {
    return NotionTokens(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      accessTokenExpiresAt: json['access_token_expires_at'] as int,
      workspaceId: json['workspace_id'] as String?,
      workspaceName: json['workspace_name'] as String?,
      userName: json['user_name'] as String?,
      botId: json['bot_id'] as String?,
      connectedAt: json['connected_at'] as int,
    );
  }

  @override
  List<Object?> get props => [
    accessToken,
    refreshToken,
    accessTokenExpiresAt,
    workspaceId,
    workspaceName,
    userName,
    botId,
    connectedAt,
  ];
}
