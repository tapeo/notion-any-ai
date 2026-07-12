import 'package:flutter/material.dart';

class AppFonts {
  AppFonts._();

  static TextStyle display() => const TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        height: 1.3,
      );

  static TextStyle displayLarge() =>
      display().copyWith(fontSize: 57, letterSpacing: -1.4, height: 1.1);

  static TextStyle displayMedium() =>
      display().copyWith(fontSize: 45, letterSpacing: -1.0, height: 1.15);

  static TextStyle displaySmall() =>
      display().copyWith(fontSize: 36, letterSpacing: -0.72, height: 1.2);

  static TextStyle headlineLarge() => const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        height: 1.3,
      );

  static TextStyle headlineMedium() => const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.32,
        height: 1.3,
      );

  static TextStyle headlineSmall() => const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.16,
        height: 1.35,
      );

  static TextStyle titleLarge() =>
      const TextStyle(fontSize: 22, fontWeight: FontWeight.w500, height: 1.5);

  static TextStyle titleMedium() =>
      const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.4);

  static TextStyle titleSmall() =>
      const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.4);

  static TextStyle bodyLarge() =>
      const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5);

  static TextStyle bodyMedium() =>
      const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.45);

  static TextStyle bodySmall() =>
      const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.45);

  static TextStyle labelLarge() =>
      const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.4);

  static TextStyle labelMedium() =>
      const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.4);

  static TextStyle labelSmall() => const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        height: 1.3,
      );

  static TextStyle caption() =>
      const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.4);

  static TextStyle codeMd() => const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.6,
        fontFamily: 'Menlo',
        fontFamilyFallback: ['Courier', 'Courier New', 'monospace'],
      );

  static TextStyle codeSm() => const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        height: 1.5,
        fontFamily: 'Menlo',
        fontFamilyFallback: ['Courier', 'Courier New', 'monospace'],
      );

  static TextStyle microUpper() => const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.8,
        height: 1.3,
      );
}