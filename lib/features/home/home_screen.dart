import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/device_utils.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/medication_provider.dart';
import '../../shared/providers/streak_provider.dart';
import '../../shared/widgets/medbuddy_scaffold.dart';
import '../../shared/widgets/primary_button.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final streak = ref.watch(streakProvider).valueOrNull;
    final nextMed = ref.watch(nextMedicationProvider);
    final isTablet = DeviceUtils.isTablet(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: pagePadding(context),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Greeting(name: user?.name ?? 'friend'),
              const SizedBox(height: AppDimensions.space24),
              if (isTablet)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _StreakCard(streak: streak?.currentStreak ?? 0)),
                      const SizedBox(width: AppDimensions.space20),
                      Expanded(child: _GoalCard()),
                    ],
                  ),
                )
              else ...[
                _StreakCard(streak: streak?.currentStreak ?? 0),
                const SizedBox(height: AppDimensions.space16),
                _GoalCard(),
              ],
              const SizedBox(height: AppDimensions.space24),
              _MedicationCard(
                title: nextMed?.name ?? 'Iron + Creatine',
                time: nextMed?.scheduleTime != null
                    ? nextMed!.scheduleTime.format(context)
                    : '12:30 PM',
                onTake: () => context.goNamed(AppRoute.verification),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  final String name;
  const _Greeting({required this.name});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
            ? 'Good afternoon'
            : 'Good evening';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$greeting, $name 👋',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(AppDateUtils.formatDate(DateTime.now()),
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.onSurface.withValues(alpha: 0.6))),
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  final int streak;
  const _StreakCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space24),
      decoration: BoxDecoration(
        gradient: AppColors.coralGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department_rounded,
              size: 56, color: AppColors.onPrimary),
          const SizedBox(width: AppDimensions.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current streak',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.onPrimary.withValues(alpha: 0.85),
                        )),
                const SizedBox(height: 4),
                Text(
                  '$streak day${streak == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const target = 45.0;
    const current = 33.0;
    final progress = current / target;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_rounded, color: AppColors.secondary),
              const SizedBox(width: 8),
              Text('Health goal',
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppDimensions.space12),
          Text('Reach ${target.toStringAsFixed(0)} kg',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppDimensions.space8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 14,
              backgroundColor: AppColors.surface,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${current.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} kg',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  final String title;
  final String time;
  final VoidCallback onTake;

  const _MedicationCard({
    required this.title,
    required this.time,
    required this.onTake,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.outline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: const Icon(Icons.medication_rounded,
                    color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context).textTheme.titleLarge),
                    Text('Today at $time',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space20),
          PrimaryButton(
            label: 'Take medication',
            icon: Icons.camera_alt_rounded,
            onPressed: onTake,
          ),
        ],
      ),
    );
  }
}
