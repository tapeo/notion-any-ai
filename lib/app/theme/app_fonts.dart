import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppFonts {
  AppFonts._();

  static TextStyle display() => GoogleFonts.lora(
    fontWeight: FontWeight.w600,
    letterSpacing: -0.72,
    height: 1.3,
  );

  static TextStyle displayHero() =>
      display().copyWith(fontSize: 72, letterSpacing: -1.8, height: 1.1);

  static TextStyle displayLg() =>
      display().copyWith(fontSize: 56, letterSpacing: -1.4, height: 1.15);

  static TextStyle displayMd() =>
      display().copyWith(fontSize: 48, letterSpacing: -1.2, height: 1.2);

  static TextStyle headingLg() => GoogleFonts.lora(
    fontSize: 36,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.72,
    height: 1.3,
  );

  static TextStyle headingMd() => GoogleFonts.lora(
    fontSize: 30,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.45,
    height: 1.3,
  );

  static TextStyle headingSm() => GoogleFonts.lora(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.24,
    height: 1.35,
  );

  static TextStyle bodyLg() =>
      const TextStyle(fontSize: 18, fontWeight: FontWeight.w400, height: 1.6);

  static TextStyle bodyMd() =>
      const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.55);

  static TextStyle bodySm() =>
      const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);

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
