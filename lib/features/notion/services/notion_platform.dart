import 'dart:io';

import '../../../app/theme/app_spacing.dart';

bool get isDesktopPlatform {
  return Platform.isMacOS || Platform.isLinux || Platform.isWindows;
}

bool get isMobilePlatform {
  return Platform.isAndroid || Platform.isIOS;
}

double get appBarIconSize => isMobilePlatform ? AppIconSize.lg : AppIconSize.md;
