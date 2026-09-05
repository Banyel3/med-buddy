import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/router/app_router.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/widgets/primary_button.dart';

class OnboardingMonitorScreen extends ConsumerWidget {
  const OnboardingMonitorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supaUser = ref.watch(currentSupabaseUserProvider);
    final fullCode = supaUser?.id ?? '';
    final shortCode = supaUser != null
        ? 'MB-${supaUser.id.substring(0, 6).toUpperCase()}'
        : 'MB-XXXXXX';

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
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
                  Text(
                    'Share with whoever\'s checking in',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: AppDimensions.space8),
                  Text(
                    'A family member (spouse, parent, child) can follow along on the web dashboard. Send them this code; you can always find it again on the Profile tab.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppDimensions.space32),
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.space24),
                    decoration: BoxDecoration(
                      gradient: AppColors.coralGradient,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusLg,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          shortCode,
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(color: AppColors.onPrimary),
                        ),
                        const SizedBox(height: AppDimensions.space12),
                        if (fullCode.isNotEmpty)
                          Text(
                            fullCode,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.onPrimary.withValues(
                                    alpha: 0.85,
                                  ),
                                  fontFamily: 'monospace',
                                ),
                          ),
                        const SizedBox(height: AppDimensions.space12),
                        TextButton.icon(
                          onPressed: fullCode.isEmpty
                              ? null
                              : () {
                                  Clipboard.setData(
                                    ClipboardData(text: fullCode),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Full link code copied to clipboard',
                                      ),
                                    ),
                                  );
                                },
                          icon: const Icon(
                            Icons.copy_rounded,
                            color: AppColors.onPrimary,
                          ),
                          label: const Text(
                            'Copy code',
                            style: TextStyle(color: AppColors.onPrimary),
                          ),
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
