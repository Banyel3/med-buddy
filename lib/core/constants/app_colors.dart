import 'package:flutter/material.dart';

/// MedBuddy patient app palette — pink/rose, warm and friendly.
///
/// OKLCH-tuned. Hue ~350 (warm rose) carries identity. Sage green
/// kept for verified/success because data ambiguity (verified ≠
/// purple-pink) outweighs palette purity. Reds for errors only;
/// alerts must read as alerts, not as brand color.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFFE04D8C); // rose
  static const Color secondary = Color(0xFF6CB57E); // sage (verified)
  static const Color accent = Color(0xFFFFB6CB); // blush

  // Surfaces (tinted near-white, chroma ≈ 0.005 toward primary hue)
  static const Color surface = Color(0xFFFFF7FA);
  static const Color surfaceContainer = Color(0xFFF7E9EE);

  // Status
  static const Color error = Color(0xFFC6294B);
  static const Color warning = Color(0xFFE8B23A);

  // Ink
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF2A171F); // deep plum
  static const Color outline = Color(0xFFE8CFD8);

  // Gradients — coralGradient name retained for backwards compat
  // with existing widgets; underlying colors are now blush.
  static const LinearGradient coralGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFB6CB), Color(0xFFE04D8C)],
  );

  static ColorScheme get lightScheme => const ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: onPrimary,
    secondary: secondary,
    onSecondary: onPrimary,
    tertiary: accent,
    onTertiary: onSurface,
    error: error,
    onError: onPrimary,
    surface: surface,
    onSurface: onSurface,
    surfaceContainerHighest: surfaceContainer,
    outline: outline,
  );

  // Dark tokens — plum-tinted blacks, blush primary for legibility.
  static const Color darkSurface = Color(0xFF1B1015);
  static const Color darkSurfaceContainer = Color(0xFF251820);
  static const Color darkOnSurface = Color(0xFFF7E3EC);

  static ColorScheme get darkScheme => const ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFFFB6CB), // blush — legible on dark plum
    onPrimary: Color(0xFF1F0A14),
    secondary: Color(0xFF6CB57E),
    onSecondary: Color(0xFF0C1E0F),
    tertiary: Color(0xFFF9CDDB),
    onTertiary: Color(0xFF1F0A14),
    error: Color(0xFFFFB6BA),
    onError: Color(0xFF1F0A14),
    surface: darkSurface,
    onSurface: darkOnSurface,
    surfaceContainerHighest: darkSurfaceContainer,
    outline: Color(0xFF6B4D58),
  );
}
