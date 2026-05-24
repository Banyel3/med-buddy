import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/router/app_router.dart';
import '../../shared/widgets/primary_button.dart';

class OnboardingMonitorScreen extends StatelessWidget {
  const OnboardingMonitorScreen({super.key});

  String _generateCode() {
    final now = DateTime.now();
    return 'MB-${now.millisecondsSinceEpoch.toString().substring(7)}';
  }

  @override
  Widget build(BuildContext context) {
    final code = _generateCode();
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Step 3 of 3'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.space24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Link your monitor',
                      style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: AppDimensions.space8),
                  Text(
                    'Share this code with your partner. They enter it on the web dashboard to follow your streak.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppDimensions.space32),
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.space24),
                    decoration: BoxDecoration(
                      gradient: AppColors.coralGradient,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusLg),
                    ),
                    child: Column(
                      children: [
                        Text(
                          code,
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(color: AppColors.onPrimary),
                        ),
                        const SizedBox(height: AppDimensions.space12),
                        TextButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: code));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Code copied')),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded,
                              color: AppColors.onPrimary),
                          label: const Text('Copy code',
                              style:
                                  TextStyle(color: AppColors.onPrimary)),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  PrimaryButton(
                    label: 'Continue',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () =>
                        context.goNamed(AppRoute.onboardingAccessibility),
                  ),
                  const SizedBox(height: AppDimensions.space12),
                  TextButton(
                    onPressed: () =>
                        context.goNamed(AppRoute.onboardingAccessibility),
                    child: const Text('Skip for now'),
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
