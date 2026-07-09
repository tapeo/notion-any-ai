import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const _installBackendUrl = String.fromEnvironment(
  'INSTALL_BACKEND_URL',
  defaultValue: 'https://notion-any-ai-backend-824089784983.europe-west1.run.app',
);

const _installationIdKey = 'installation_id';
const _installSentKey = 'install_sent';

class InstallService {
  InstallService({
    required this._secureStorage,
    required this._sharedPrefs,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _sharedPrefs;
  final http.Client _httpClient;
  final Uuid _uuid = const Uuid();

  Future<void> sendInstallPing() async {
    if (_sharedPrefs.getBool(_installSentKey) == true) return;

    final installationId = await _getOrCreateInstallationId();
    if (installationId == null) return;

    final packageInfo = await PackageInfo.fromPlatform();
    final platform = _platformName();

    final payload = {
      'appName': packageInfo.appName,
      'installationId': installationId,
      'platform': platform,
      'appVersion': packageInfo.version,
      'buildNumber': packageInfo.buildNumber,
    };

    try {
      final response = await _httpClient.post(
        Uri.parse('$_installBackendUrl/install'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        await _sharedPrefs.setBool(_installSentKey, true);
      }
    } catch (_) {
      // Silent failure: install ping is best-effort.
    }
  }

  Future<String?> _getOrCreateInstallationId() async {
    try {
      final existing = await _secureStorage.read(key: _installationIdKey);
      if (existing != null && existing.isNotEmpty) return existing;
      final id = _uuid.v4();
      await _secureStorage.write(key: _installationIdKey, value: id);
      return id;
    } catch (_) {
      return null;
    }
  }

  String _platformName() {
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  void dispose() {
    _httpClient.close();
  }
}