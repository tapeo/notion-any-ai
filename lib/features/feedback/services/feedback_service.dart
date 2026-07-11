import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

const _feedbackBackendUrl = String.fromEnvironment(
  'INSTALL_BACKEND_URL',
  defaultValue: '',
);

const _installationIdKey = 'installation_id';

class FeedbackService {
  FeedbackService({
    required this.secureStorage,
    http.Client? httpClient,
  }) : httpClient = httpClient ?? http.Client();

  final FlutterSecureStorage secureStorage;
  final http.Client httpClient;

  Future<bool> sendFeedback({required String message, required String email}) async {
    if (_feedbackBackendUrl.isEmpty) return false;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final installationId = await secureStorage.read(key: _installationIdKey);
      final platform = _platformName();

      final payload = <String, dynamic>{
        'appName': packageInfo.appName,
        'message': message,
        'platform': ?platform,
        if (email.isNotEmpty) 'email': email,
        if (installationId != null && installationId.isNotEmpty)
          'installationId': installationId,
      };

      final response = await httpClient.post(
        Uri.parse('$_feedbackBackendUrl/feedback'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      rethrow;
    }
  }

  String? _platformName() {
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return null;
  }

  void dispose() {
    httpClient.close();
  }
}