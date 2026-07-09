import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color ink = Color(0xFF37352F);
  static const Color cream = Color(0xFFF7F6F3);
  static const Color graySurface = Color(0xFFEBEAE8);

  static const Color accent = Color(0xFF2383E2);
  static const Color accentHover = Color(0xFF0B6BCB);
  static const Color accentActive = Color(0xFF0A5EAF);

  static const Color success = Color(0xFF0F7B6C);
  static const Color warning = Color(0xFFD9730D);
  static const Color error = Color(0xFFE03E3E);
  static const Color info = Color(0xFF0B6E99);

  static const Color white = Color(0xFFFFFFFF);
  static const Color overlay = Color(0x66000000);

  static const Color inkLight = ink;
  static const Color inkDark = white;

  static Color textPrimary(Brightness b) =>
      b == Brightness.dark ? inkDark : inkLight;
  static Color textSecondary(Brightness b) =>
      b == Brightness.dark ? const Color(0xCCFFFFFF) : const Color(0xA637352F);
  static Color textTertiary(Brightness b) =>
      b == Brightness.dark ? const Color(0x99FFFFFF) : const Color(0x8037352F);
  static Color textDisabled(Brightness b) =>
      b == Brightness.dark ? const Color(0x66FFFFFF) : const Color(0x6637352F);

  static Color bgPrimary(Brightness b) =>
      b == Brightness.dark ? const Color(0xFF191919) : white;
  static Color bgSecondary(Brightness b) =>
      b == Brightness.dark ? const Color(0xFF202020) : cream;
  static Color bgTertiary(Brightness b) =>
      b == Brightness.dark ? const Color(0xFF2A2A2A) : graySurface;

  static Color borderDefault(Brightness b) =>
      b == Brightness.dark ? const Color(0x21FFFFFF) : const Color(0x2937352F);
  static Color borderSubtle(Brightness b) =>
      b == Brightness.dark ? const Color(0x12FFFFFF) : const Color(0x1737352F);

  static const Color hoverFill = Color(0x0F37352F);
  static const Color activeFill = Color(0x1437352F);
  static const Color subtleFill = Color(0x0537352F);

  static Color hoverFillDark = const Color(0x14FFFFFF);

  static Color hoverFillFor(Brightness b) =>
      b == Brightness.dark ? hoverFillDark : hoverFill;
  static Color activeFillFor(Brightness b) =>
      b == Brightness.dark ? const Color(0x1FFFFFFF) : activeFill;
  static Color subtleFillFor(Brightness b) =>
      b == Brightness.dark ? const Color(0x0AFFFFFF) : subtleFill;

  static const Color focusRing = Color(0x472383E2);

  static const Color userBubble = ink;
  static const Color userBubbleText = white;

  static Color assistantBubble(Brightness b) =>
      b == Brightness.dark ? const Color(0xFF2A2A2A) : graySurface;
  static Color assistantBubbleText(Brightness b) => textPrimary(b);
}

class AppShadows {
  AppShadows._();

  static const List<BoxShadow> xs = [
    BoxShadow(color: Color(0x0D0F0F0F), offset: Offset(0, 1), blurRadius: 2),
  ];
  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x120F0F0F), offset: Offset(0, 4), blurRadius: 12),
  ];
  static const List<BoxShadow> md = [
    BoxShadow(color: Color(0x1A0F0F0F), offset: Offset(0, 8), blurRadius: 24),
    BoxShadow(color: Color(0x0A0F0F0F), offset: Offset(0, 2), blurRadius: 8),
  ];
  static const List<BoxShadow> lg = [
    BoxShadow(color: Color(0x210F0F0F), offset: Offset(0, 12), blurRadius: 32),
    BoxShadow(color: Color(0x0D0F0F0F), offset: Offset(0, 4), blurRadius: 12),
  ];
}

class AppTags {
  AppTags._();

  static const Color grayBg = Color(0xFFE3E2E0);
  static const Color grayText = Color(0xFF9B9A97);
  static const Color brownBg = Color(0xFFEEE0DA);
  static const Color brownText = Color(0xFF64473A);
  static const Color orangeBg = Color(0xFFFAEBDD);
  static const Color orangeText = Color(0xFFD9730D);
  static const Color yellowBg = Color(0xFFFBF3DB);
  static const Color yellowText = Color(0xFFDFAB01);
  static const Color greenBg = Color(0xFFDDEDEA);
  static const Color greenText = Color(0xFF0F7B6C);
  static const Color blueBg = Color(0xFFDDEBF1);
  static const Color blueText = Color(0xFF0B6E99);
  static const Color purpleBg = Color(0xFFEAE4F2);
  static const Color purpleText = Color(0xFF6940A5);
  static const Color pinkBg = Color(0xFFF4DFEB);
  static const Color pinkText = Color(0xFFAD1A72);
  static const Color redBg = Color(0xFFFBE4E4);
  static const Color redText = Color(0xFFE03E3E);
}
