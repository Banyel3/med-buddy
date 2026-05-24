import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

class StreakBadge extends StatelessWidget {
  final int days;
  final bool compact;

  const StreakBadge({super.key, required this.days, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: AppColors.coralGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department_rounded,
              color: AppColors.onPrimary, size: compact ? 18 : 22),
          const SizedBox(width: 6),
          Text(
            '$days day${days == 1 ? '' : 's'}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: compact ? 13 : 15,
              fontWeight: FontWeight.w700,
              color: AppColors.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
