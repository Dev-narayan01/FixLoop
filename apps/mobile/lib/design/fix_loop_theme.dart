import 'package:flutter/material.dart';

/// Tokens from the supplied Fix Loop Stitch design system.
abstract final class FixPalette {
  static const ink = Color(0xFF221A14);
  static const muted = Color(0xFF51443B);
  static const cream = Color(0xFFFFF8F5);
  static const low = Color(0xFFFBF2EC);
  static const card = Color(0xFFF5EAE2);
  static const high = Color(0xFFEFE4DC);
  static const outline = Color(0xFFD6C3B7);
  static const brown = Color(0xFF6C3A08);
  static const brownLight = Color(0xFF89511F);
  static const peach = Color(0xFFFFDCC4);
  static const darkSurface = Color(0xFF19120D);
  static const darkLow = Color(0xFF201712);
  static const darkCard = Color(0xFF261E18);
  static const darkHigh = Color(0xFF312822);
  static const darkText = Color(0xFFEFDFD6);
  static const darkMuted = Color(0xFFD6C3B7);
  static const darkPrimary = Color(0xFFFFB780);
  static const green = Color(0xFF1B5E20);
}

ThemeData fixLoopTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: FixPalette.brown,
    brightness: brightness,
  ).copyWith(
    primary: dark ? FixPalette.darkPrimary : FixPalette.brown,
    onPrimary: dark ? const Color(0xFF4E2600) : Colors.white,
    primaryContainer: dark ? FixPalette.darkCard : FixPalette.peach,
    onPrimaryContainer: dark ? FixPalette.peach : FixPalette.brown,
    surface: dark ? FixPalette.darkSurface : FixPalette.cream,
    onSurface: dark ? FixPalette.darkText : FixPalette.ink,
    onSurfaceVariant: dark ? FixPalette.darkMuted : FixPalette.muted,
    surfaceContainerLowest: dark ? FixPalette.darkLow : Colors.white,
    surfaceContainerLow: dark ? FixPalette.darkLow : FixPalette.low,
    surfaceContainer: dark ? FixPalette.darkCard : FixPalette.card,
    surfaceContainerHigh: dark ? FixPalette.darkHigh : FixPalette.high,
    outlineVariant: dark ? FixPalette.muted : FixPalette.outline,
  );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  final text = base.textTheme
      .apply(
        fontFamily: 'Atkinson Hyperlegible Next',
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      )
      .copyWith(
        displaySmall: TextStyle(
          fontFamily: 'Bricolage Grotesque',
          fontSize: 36,
          height: 1.22,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Bricolage Grotesque',
          fontSize: 32,
          height: 1.25,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Bricolage Grotesque',
          fontSize: 24,
          height: 1.33,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Atkinson Hyperlegible Next',
          fontSize: 18,
          height: 1.35,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Atkinson Hyperlegible Next',
          fontSize: 16,
          height: 1.5,
          color: scheme.onSurface,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Atkinson Hyperlegible Next',
          fontSize: 14,
          height: 1.43,
          color: scheme.onSurface,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Atkinson Hyperlegible Next',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      );
  return base.copyWith(
    scaffoldBackgroundColor: scheme.surface,
    textTheme: text,
    dividerColor: scheme.outlineVariant.withValues(alpha: 0.7),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        textStyle: text.labelLarge,
        shape: const StadiumBorder(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 52),
        textStyle: text.labelLarge,
        shape: const StadiumBorder(),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );
}
