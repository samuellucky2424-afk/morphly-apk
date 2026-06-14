import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'morphly_tokens.dart';

class MorphlyTheme {
  const MorphlyTheme._();

  static ThemeData get dark {
    final baseText = GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme,
    ).apply(
      bodyColor: MorphlyColors.onSurface,
      displayColor: MorphlyColors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: MorphlyColors.background,
      colorScheme: const ColorScheme.dark(
        primary: MorphlyColors.primary,
        onPrimary: MorphlyColors.onPrimaryContainer,
        secondary: MorphlyColors.secondary,
        onSecondary: MorphlyColors.onSecondary,
        surface: MorphlyColors.surface,
        onSurface: MorphlyColors.onSurface,
        error: MorphlyColors.danger,
      ),
      textTheme: baseText.copyWith(
        headlineLarge: baseText.headlineLarge?.copyWith(
          fontSize: 30,
          height: 1.1,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        headlineMedium: baseText.headlineMedium?.copyWith(
          fontSize: 24,
          height: 1.25,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        titleLarge: baseText.titleLarge?.copyWith(
          fontSize: 22,
          height: 1.25,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
          color: MorphlyColors.primary,
        ),
        titleMedium: baseText.titleMedium?.copyWith(
          fontSize: 18,
          height: 1.33,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        bodyLarge: baseText.bodyLarge?.copyWith(
          fontSize: 16,
          height: 1.5,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
        ),
        bodyMedium: baseText.bodyMedium?.copyWith(
          fontSize: 14,
          height: 1.42,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
        ),
        labelLarge: baseText.labelLarge?.copyWith(
          fontSize: 15,
          height: 1.33,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        labelSmall: baseText.labelSmall?.copyWith(
          fontSize: 12,
          height: 1.33,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MorphlyColors.surface,
        hintStyle: TextStyle(
          color: MorphlyColors.outline.withValues(alpha: 0.55),
        ),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(MorphlyRadius.pill),
          borderSide: BorderSide(color: MorphlyColors.border),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(MorphlyRadius.pill),
          borderSide: BorderSide(color: MorphlyColors.border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(MorphlyRadius.pill),
          borderSide: BorderSide(color: MorphlyColors.primary),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: MorphlyColors.surfaceContainerHigh,
        contentTextStyle: TextStyle(color: MorphlyColors.white),
      ),
    );
  }
}
