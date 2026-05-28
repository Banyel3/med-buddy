import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final bool gradient;

  const PrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
    this.gradient = true,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;
    final child = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onPressed,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: gradient && !disabled ? AppColors.coralGradient : null,
            color: !gradient || disabled
                ? (disabled ? AppColors.outline : AppColors.primary)
                : null,
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            // Softer, cuter elevation. Half the blur + offset of before,
            // brand-tinted but airy.
            boxShadow: disabled
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: AppColors.onPrimary,
                    strokeWidth: 2.4,
                  ),
                )
              else if (icon != null) ...[
                Icon(icon, color: AppColors.onPrimary, size: 22),
                const SizedBox(width: 10),
              ],
              if (!loading)
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.onPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    return SizedBox(width: double.infinity, child: child);
  }
}
