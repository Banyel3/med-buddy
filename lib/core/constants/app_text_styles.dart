import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography — Plus Jakarta Sans for headlines, Be Vietnam Pro for body.
class AppTextStyles {
  AppTextStyles._();

  static TextTheme get textTheme => TextTheme(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 56,
          fontWeight: FontWeight.w800,
          color: AppColors.onSurface,
          height: 1.05,
          letterSpacing: -1.5,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 44,
          fontWeight: FontWeight.w800,
          color: AppColors.onSurface,
          height: 1.1,
          letterSpacing: -1,
        ),
        displaySmall: GoogleFonts.plusJakartaSans(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
        ),
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
        ),
        headlineSmall: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
        titleMedium: GoogleFonts.beVietnamPro(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
        titleSmall: GoogleFonts.beVietnamPro(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
        bodyLarge: GoogleFonts.beVietnamPro(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurface,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.beVietnamPro(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurface,
          height: 1.45,
        ),
        bodySmall: GoogleFonts.beVietnamPro(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurface,
        ),
        labelLarge: GoogleFonts.beVietnamPro(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
          letterSpacing: 0.3,
        ),
        labelMedium: GoogleFonts.beVietnamPro(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
          letterSpacing: 0.4,
        ),
        labelSmall: GoogleFonts.beVietnamPro(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurface,
          letterSpacing: 0.5,
        ),
      );

  /// Streak counter — large, expressive number.
  static TextStyle get streakNumber => GoogleFonts.plusJakartaSans(
        fontSize: 88,
        fontWeight: FontWeight.w900,
        color: AppColors.onPrimary,
        height: 1,
        letterSpacing: -3,
      );
}
