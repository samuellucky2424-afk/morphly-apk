import 'package:flutter/material.dart';

class MorphlyColors {
  const MorphlyColors._();

  static const background = Color(0xFF050505);
  static const surface = Color(0xFF090909);
  static const card = Color(0xFF111111);
  static const surfaceContainer = Color(0xFF1E1F26);
  static const surfaceContainerHigh = Color(0xFF282A31);
  static const border = Color(0xFF27272A);
  static const outline = Color(0xFF988D9F);
  static const outlineVariant = Color(0xFF4D4354);
  static const onSurface = Color(0xFFE2E1EB);
  static const onSurfaceVariant = Color(0xFFCFC2D6);
  static const primary = Color(0xFFDDB7FF);
  static const primaryContainer = Color(0xFFB76DFF);
  static const onPrimaryContainer = Color(0xFF400071);
  static const secondary = Color(0xFF4AE176);
  static const onSecondary = Color(0xFF003915);
  static const tertiary = Color(0xFFFFB3AD);
  static const danger = Color(0xFFFF5451);
  static const white = Color(0xFFFFFFFF);
}

class MorphlySpacing {
  const MorphlySpacing._();

  static const base = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const page = 20.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

class MorphlyRadius {
  const MorphlyRadius._();

  static const small = Radius.circular(8);
  static const medium = Radius.circular(12);
  static const large = Radius.circular(16);
  static const xLarge = Radius.circular(24);
  static const pill = Radius.circular(999);
}

class MorphlyShadows {
  const MorphlyShadows._();

  static List<BoxShadow> purpleGlow([double opacity = 0.28]) => [
        BoxShadow(
          color: MorphlyColors.primary.withValues(alpha: opacity),
          blurRadius: 28,
          spreadRadius: -8,
        ),
      ];

  static List<BoxShadow> greenGlow([double opacity = 0.42]) => [
        BoxShadow(
          color: MorphlyColors.secondary.withValues(alpha: opacity),
          blurRadius: 32,
          spreadRadius: -6,
        ),
      ];
}
