import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/device_utils.dart';
import '../../shared/widgets/primary_button.dart';

/// Phase 1 placeholder. Phase 3 wires the AccessibilityService overlay.
class LockScreen extends StatelessWidget {
  const LockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = DeviceUtils.isTablet(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.coralGradient),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isTablet ? 520 : 480),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.space24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.medication_liquid_rounded,
                        size: 128, color: AppColors.onPrimary),
                    const SizedBox(height: AppDimensions.space24),
                    Text(
                      "Hey! Don't forget your meds today 💊",
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(color: AppColors.onPrimary),
                    ),
                    const SizedBox(height: AppDimensions.space12),
                    Text(
                      'Pop in for a quick verify — takes 30 seconds.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(
                              color: AppColors.onPrimary
                                  .withValues(alpha: 0.85)),
                    ),
                    const SizedBox(height: AppDimensions.space40),
                    PrimaryButton(
                      label: 'Take it now',
                      icon: Icons.camera_alt_rounded,
                      gradient: false,
                      onPressed: () => context.goNamed(AppRoute.verification),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
