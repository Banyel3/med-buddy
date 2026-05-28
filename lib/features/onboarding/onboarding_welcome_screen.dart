import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/router/app_router.dart';
import '../../shared/widgets/primary_button.dart';

class OnboardingWelcomeScreen extends StatelessWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.space24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      gradient: AppColors.coralGradient,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusXl,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.favorite_rounded,
                        size: 96,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space32),
                  Text(
                    'Welcome to MedBuddy',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: AppDimensions.space12),
                  Text(
                    'Your gentle daily nudge to take your meds — verified with a quick selfie + pill check.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppDimensions.space40),
                  PrimaryButton(
                    label: 'Get started',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () =>
                        context.goNamed(AppRoute.onboardingMedication),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
