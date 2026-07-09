// App entry: ProviderScope + MaterialApp with light/dark themes.
import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/services/shared_prefs_provider.dart';
import 'app/theme/app_colors.dart';
import 'app/theme/app_fonts.dart';
import 'app/theme/app_shapes.dart';
import 'app/theme/app_spacing.dart';
import 'features/ai_provider/providers/ai_provider_notifier.dart';
import 'features/builtin_tools/providers/builtin_tools_notifier.dart';
import 'features/chat/widgets/chat_screen.dart';
import 'features/conversations/providers/conversation_storage_provider.dart';
import 'features/conversations/providers/conversations_notifier.dart';
import 'features/memory/providers/memory_notifier.dart';
import 'features/notifications/providers/notifications_provider.dart';
import 'features/notifications/services/notifications_service_provider.dart';
import 'features/notion/providers/notion_connection_notifier.dart';
import 'features/notion/services/notion_platform.dart';
import 'features/system_prompt/providers/system_prompt_notifier.dart';
import 'features/voice_input/providers/voice_input_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSharedPrefs();
  await initAppDir();
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerStatefulWidget {
  const MainApp({super.key});

  @override
  ConsumerState<MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp> {
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aiProviderProvider.notifier).init();
      ref.read(voiceInputProvider.notifier).init();
      ref.read(notionConnectionProvider.notifier).init();
      ref.read(systemPromptProvider.notifier).init();
      ref.read(builtinToolsProvider.notifier).init();
      ref.read(conversationsProvider.notifier).init();
      ref.read(memoryProvider.notifier).init();
      () async {
        await ref.read(notificationsServiceProvider).init();
        await ref.read(notificationsServiceProvider).requestPermissions();
        await ref.read(notificationsProvider.notifier).init();
      }();
    });
  }

  void _initDeepLinks() {
    if (isDesktopPlatform) return;
    final appLinks = AppLinks();
    _linkSub = appLinks.uriLinkStream.listen(
      (uri) => _handleUri(uri),
      onError: (_) {},
    );
    appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleUri(uri);
    });
  }

  void _handleUri(Uri uri) {
    if (uri.scheme != 'notionopenai' || uri.host != 'oauth') return;
    final code = uri.queryParameters['code'];
    final state = uri.queryParameters['state'];
    final error = uri.queryParameters['error'];
    if (error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notion connection failed: $error')),
        );
      });
      return;
    }
    if (code == null || state == null) return;
    ref.read(notionConnectionProvider.notifier).handleCallback(code, state);
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notion Any AI',
      debugShowCheckedModeBanner: false,
      theme: _lightTheme(),
      darkTheme: _darkTheme(),
      themeMode: ThemeMode.system,
      home: const ChatScreen(),
    );
  }

  ThemeData _lightTheme() {
    final b = Brightness.light;
    final scheme = ColorScheme(
      brightness: b,
      primary: AppColors.accent,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.accent.withValues(alpha: 0.12),
      onPrimaryContainer: AppColors.accent,
      secondary: AppColors.ink,
      onSecondary: AppColors.white,
      tertiary: AppColors.accent,
      onTertiary: AppColors.white,
      error: AppColors.error,
      onError: AppColors.white,
      surface: AppColors.bgPrimary(b),
      onSurface: AppColors.textPrimary(b),
      surfaceContainerLowest: AppColors.bgPrimary(b),
      surfaceContainerLow: AppColors.bgPrimary(b),
      surfaceContainer: AppColors.bgSecondary(b),
      surfaceContainerHigh: AppColors.bgTertiary(b),
      surfaceContainerHighest: AppColors.bgTertiary(b),
      onSurfaceVariant: AppColors.textSecondary(b),
      outline: AppColors.borderDefault(b),
      outlineVariant: AppColors.borderSubtle(b),
    );
    return _baseTheme(scheme, b);
  }

  ThemeData _darkTheme() {
    final b = Brightness.dark;
    final scheme = ColorScheme(
      brightness: b,
      primary: AppColors.accent,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.accent.withValues(alpha: 0.16),
      onPrimaryContainer: AppColors.accent,
      secondary: AppColors.ink,
      onSecondary: AppColors.white,
      tertiary: AppColors.accent,
      onTertiary: AppColors.white,
      error: AppColors.error,
      onError: AppColors.white,
      surface: AppColors.bgPrimary(b),
      onSurface: AppColors.textPrimary(b),
      surfaceContainerLowest: AppColors.bgPrimary(b),
      surfaceContainerLow: AppColors.bgPrimary(b),
      surfaceContainer: AppColors.bgSecondary(b),
      surfaceContainerHigh: AppColors.bgTertiary(b),
      surfaceContainerHighest: AppColors.bgTertiary(b),
      onSurfaceVariant: AppColors.textSecondary(b),
      outline: AppColors.borderDefault(b),
      outlineVariant: AppColors.borderSubtle(b),
    );
    return _baseTheme(scheme, b);
  }

  ThemeData _baseTheme(ColorScheme scheme, Brightness b) {
    final ink = AppColors.textPrimary(b);
    final secondary = AppColors.textSecondary(b);
    final tertiary = AppColors.textTertiary(b);
    final border = AppColors.borderDefault(b);
    final subtleBorder = AppColors.borderSubtle(b);
    final touch = isMobilePlatform;
    final iconButtonMin = touch ? const Size(44, 44) : const Size(28, 28);
    final iconButtonPadding = touch
        ? const EdgeInsets.all(AppSpacing.space2)
        : const EdgeInsets.all(AppSpacing.space2 - 2);

    TextTheme textTheme = TextTheme(
      displayLarge: AppFonts.displayHero().copyWith(color: ink),
      displayMedium: AppFonts.displayLg().copyWith(color: ink),
      displaySmall: AppFonts.displayMd().copyWith(color: ink),
      headlineLarge: AppFonts.headingLg().copyWith(color: ink),
      headlineMedium: AppFonts.headingMd().copyWith(color: ink),
      headlineSmall: AppFonts.headingSm().copyWith(color: ink),
      titleLarge: AppFonts.labelLg().copyWith(color: ink),
      titleMedium: AppFonts.labelMd().copyWith(color: ink),
      titleSmall: AppFonts.labelSm().copyWith(color: ink),
      bodyLarge: AppFonts.bodyLg().copyWith(color: ink),
      bodyMedium: AppFonts.bodyMd().copyWith(color: ink),
      bodySmall: AppFonts.bodySm().copyWith(color: secondary),
      labelLarge: AppFonts.labelLg().copyWith(color: ink),
      labelMedium: AppFonts.labelMd().copyWith(color: ink),
      labelSmall: AppFonts.micro().copyWith(color: secondary),
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      borderSide: BorderSide(width: 1, color: border),
    );
    final inputBorderFocus = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      borderSide: const BorderSide(width: 1, color: AppColors.accent),
    );
    final inputBorderError = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      borderSide: const BorderSide(width: 1, color: AppColors.error),
    );

    final buttonShape = AppShapes.sm();

    return ThemeData(
      brightness: b,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bgSecondary(b),
      canvasColor: AppColors.bgSecondary(b),
      splashFactory: NoSplash.splashFactory,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgSecondary(b),
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: AppFonts.labelLg().copyWith(color: ink),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        isDense: true,
        labelStyle: AppFonts.bodySm().copyWith(color: secondary),
        hintStyle: AppFonts.bodySm().copyWith(color: tertiary),
        floatingLabelStyle: AppFonts.bodySm().copyWith(color: AppColors.accent),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space2,
        ),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorderFocus,
        errorBorder: inputBorderError,
        focusedErrorBorder: inputBorderError,
        outlineBorder: BorderSide(width: 1, color: border),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.4),
          disabledForegroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space3,
            vertical: AppSpacing.space2 - 2,
          ),
          minimumSize: const Size(0, 32),
          shape: buttonShape,
          textStyle: AppFonts.labelMd(),
          elevation: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.bgPrimary(b),
          foregroundColor: ink,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space3,
            vertical: AppSpacing.space2 - 2,
          ),
          minimumSize: const Size(0, 32),
          shape: buttonShape,
          textStyle: AppFonts.labelMd(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          disabledForegroundColor: AppColors.textDisabled(b),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space3,
            vertical: AppSpacing.space2 - 2,
          ),
          minimumSize: const Size(0, 32),
          shape: buttonShape,
          side: BorderSide(width: 1, color: border),
          textStyle: AppFonts.labelMd(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          disabledForegroundColor: AppColors.textDisabled(b),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space2,
            vertical: AppSpacing.space1,
          ),
          minimumSize: const Size(0, 28),
          shape: buttonShape,
          textStyle: AppFonts.bodySm(),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: secondary,
          disabledForegroundColor: AppColors.textDisabled(b),
          minimumSize: iconButtonMin,
          padding: iconButtonPadding,
          shape: buttonShape,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgPrimary(b),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: AppShapes.lg(),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(
        color: subtleBorder,
        thickness: 1,
        space: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.white.withValues(alpha: 0.5);
          }
          return AppColors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.accent.withValues(alpha: 0.4);
            }
            return AppColors.accent;
          }
          return AppColors.borderDefault(b);
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        trackOutlineWidth: WidgetStateProperty.all(0),
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accent;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.white),
        side: BorderSide(width: 1.5, color: AppColors.borderDefault(b)),
        shape: AppShapes.xs(),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.accent,
        linearTrackColor: AppColors.borderSubtle(b),
        linearMinHeight: 3,
        circularTrackColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: AppFonts.bodySm().copyWith(color: AppColors.white),
        behavior: SnackBarBehavior.floating,
        shape: AppShapes.md(),
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.bgPrimary(b),
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppFonts.bodyLg().copyWith(
          color: ink,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: AppFonts.bodySm().copyWith(color: ink),
        shape: AppShapes.lg(),
        elevation: 0,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.bgPrimary(b),
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.bgPrimary(b),
        modalElevation: 0,
        shape: const RoundedSuperellipseBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        textStyle: AppFonts.caption().copyWith(color: AppColors.white),
        waitDuration: const Duration(milliseconds: 500),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.accent,
        selectionColor: AppColors.accent.withValues(alpha: 0.2),
        selectionHandleColor: AppColors.accent,
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
    );
  }
}
