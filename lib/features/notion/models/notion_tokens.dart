import 'package:equatable/equatable.dart';

class NotionTokens extends Equatable {
  const NotionTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresAt,
    required this.clientId,
    this.clientSecret,
    this.workspaceId,
    this.workspaceName,
    this.userName,
    required this.connectedAt,
  });

  final String accessToken;
  final String refreshToken;
  final int accessTokenExpiresAt;
  final String clientId;
  final String? clientSecret;
  final String? workspaceId;
  final String? workspaceName;
  final String? userName;
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
  }) {
    return NotionTokens(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      accessTokenExpiresAt: accessTokenExpiresAt ?? this.accessTokenExpiresAt,
      clientId: clientId,
      clientSecret: clientSecret,
      workspaceId: workspaceId ?? this.workspaceId,
      workspaceName: workspaceName ?? this.workspaceName,
      userName: userName ?? this.userName,
      connectedAt: connectedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'access_token_expires_at': accessTokenExpiresAt,
      'client_id': clientId,
      'client_secret': clientSecret,
      'workspace_id': workspaceId,
      'workspace_name': workspaceName,
      'user_name': userName,
      'connected_at': connectedAt,
    };
  }

  factory NotionTokens.fromJson(Map<String, dynamic> json) {
    return NotionTokens(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      accessTokenExpiresAt: json['access_token_expires_at'] as int,
      clientId: json['client_id'] as String,
      clientSecret: json['client_secret'] as String?,
      workspaceId: json['workspace_id'] as String?,
      workspaceName: json['workspace_name'] as String?,
      userName: json['user_name'] as String?,
      connectedAt: json['connected_at'] as int,
    );
  }

  @override
  List<Object?> get props => [
    accessToken,
    refreshToken,
    accessTokenExpiresAt,
    clientId,
    clientSecret,
    workspaceId,
    workspaceName,
    userName,
    connectedAt,
  ];
}

class NotionPendingFlow extends Equatable {
  const NotionPendingFlow({
    required this.clientId,
    required this.clientSecret,
    required this.codeVerifier,
    required this.state,
    required this.redirectUri,
    required this.startedAt,
    required this.expiresAt,
  });

  final String clientId;
  final String? clientSecret;
  final String codeVerifier;
  final String state;
  final String redirectUri;
  final int startedAt;
  final int expiresAt;

  bool get isExpired => DateTime.now().millisecondsSinceEpoch >= expiresAt;

  Map<String, dynamic> toJson() {
    return {
      'client_id': clientId,
      'client_secret': clientSecret,
      'code_verifier': codeVerifier,
      'state': state,
      'redirect_uri': redirectUri,
      'started_at': startedAt,
      'expires_at': expiresAt,
    };
  }

  factory NotionPendingFlow.fromJson(Map<String, dynamic> json) {
    return NotionPendingFlow(
      clientId: json['client_id'] as String,
      clientSecret: json['client_secret'] as String?,
      codeVerifier: json['code_verifier'] as String,
      state: json['state'] as String,
      redirectUri: json['redirect_uri'] as String,
      startedAt: json['started_at'] as int,
      expiresAt: json['expires_at'] as int,
    );
  }

  @override
  List<Object?> get props => [
    clientId,
    clientSecret,
    codeVerifier,
    state,
    redirectUri,
    startedAt,
    expiresAt,
  ];
}
