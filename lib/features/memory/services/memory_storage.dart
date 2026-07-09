import 'dart:io';

class MemoryStorage {
  MemoryStorage({required Directory appDir})
      : _dir = Directory('${appDir.path}/memory');

  final Directory _dir;

  File get _file => File('${_dir.path}/memory.md');

  File get memoryFile => _file;

  String get filePath => _file.path;

  Future<void> ensureDir() async {
    if (!_dir.existsSync()) {
      await _dir.create(recursive: true);
    }
  }

  String load() {
    if (!_file.existsSync()) return '';
    try {
      final raw = _file.readAsStringSync();
      return raw;
    } catch (_) {
      return '';
    }
  }

  Future<void> save(String content) async {
    await ensureDir();
    final temp = File('${_file.path}.tmp');
    await temp.writeAsString(content, flush: true);
    await temp.rename(_file.path);
  }

  Future<void> clear() async {
    if (!_file.existsSync()) return;
    await save('');
  }
}