import 'dart:io';

Future<void> revealInFileManager(File file) async {
  final path = file.path;
  final dir = file.parent.path;
  if (Platform.isMacOS) {
    await Process.run('open', ['-R', path]);
  } else if (Platform.isWindows) {
    await Process.run('explorer', ['/select,$path']);
  } else if (Platform.isLinux) {
    await Process.run('xdg-open', [dir]);
  }
}