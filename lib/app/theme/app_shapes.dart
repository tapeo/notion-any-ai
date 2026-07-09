import 'package:flutter/material.dart';

import 'app_spacing.dart';

class AppShapes {
  AppShapes._();

  static RoundedSuperellipseBorder superellipse(
    double radius, {
    BorderSide side = BorderSide.none,
  }) {
    return RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(radius),
      side: side,
    );
  }

  static RoundedSuperellipseBorder sm({BorderSide side = BorderSide.none}) =>
      superellipse(AppRadius.xxl, side: side);

  static RoundedSuperellipseBorder md({BorderSide side = BorderSide.none}) =>
      superellipse(AppRadius.xxl, side: side);

  static RoundedSuperellipseBorder lg({BorderSide side = BorderSide.none}) =>
      superellipse(AppRadius.xxl, side: side);

  static RoundedSuperellipseBorder xs({BorderSide side = BorderSide.none}) =>
      superellipse(AppRadius.xs, side: side);
}
