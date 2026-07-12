import 'package:flutter/material.dart';

class AppFonts {
  AppFonts._();

  static TextStyle display() => const TextStyle(
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    height: 1.3,
  );

  static TextStyle displayHero() =>
      display().copyWith(fontSize: 56, letterSpacing: -1.4, height: 1.1);

  static TextStyle displayLg() =>
      display().copyWith(fontSize: 44, letterSpacing: -1.0, height: 1.15);

  static TextStyle displayMd() =>
      display().copyWith(fontSize: 36, letterSpacing: -0.72, height: 1.2);

  static TextStyle headingLg() => const TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    height: 1.3,
  );

  static TextStyle headingMd() => const TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.32,
    height: 1.3,
  );

  static TextStyle headingSm() => const TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.16,
    height: 1.35,
  );

  static TextStyle bodyLg() =>
      const TextStyle(fontSize: 18, fontWeight: FontWeight.w400, height: 1.5);

  static TextStyle bodyMd() =>
      const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.45);

  static TextStyle bodySm() =>
      const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.45);

  static TextStyle labelLg() =>
      const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.5);

  static TextStyle labelMd() =>
      const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.4);

  static TextStyle labelSm() =>
      const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.4);

  static TextStyle caption() =>
      const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.4);

  static TextStyle micro() => const TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    height: 1.3,
  );

  static TextStyle codeMd() => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
    fontFamily: 'Menlo',
    fontFamilyFallback: ['Courier', 'Courier New', 'monospace'],
  );

  static TextStyle codeSm() => const TextStyle(
    fontSize: 12,
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
