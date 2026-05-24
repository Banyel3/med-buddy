import 'package:flutter/material.dart';

/// MedBuddy brand palette. Source of truth — Stitch design system, PRD §8.1.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFAE2F34);
  static const Color secondary = Color(0xFF006E29);
  static const Color accent = Color(0xFFFF6B6B);
  static const Color surface = Color(0xFFFDF8F8);
  static const Color surfaceContainer = Color(0xFFF2EDEC);
  static const Color error = Color(0xFFBA1A1A);
  static const Color warning = Color(0xFFE8C426);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1E1A1A);
  static const Color outline = Color(0xFFCBBCBB);

  // Gradients
  static const LinearGradient coralGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6B6B), Color(0xFFAE2F34)],
  );

  static const LinearGradient softSurfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFDF8F8), Color(0xFFF2EDEC)],
  );

  static ColorScheme get lightScheme => const ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: onPrimary,
        secondary: secondary,
        onSecondary: onPrimary,
        tertiary: accent,
        onTertiary: onPrimary,
        error: error,
        onError: onPrimary,
        surface: surface,
        onSurface: onSurface,
        surfaceContainerHighest: surfaceContainer,
        outline: outline,
      );
}
