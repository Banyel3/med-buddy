import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/device_utils.dart';
import '../../shared/models/compliance_log_model.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/compliance_provider.dart';
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
    final medsAsync = ref.watch(medicationsProvider);
    final logs = ref.watch(complianceLogsProvider).valueOrNull ?? const [];
    final adherence = _AdherenceStats.fromLogs(logs);
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
                      Expanded(
                        child: _StreakCard(streak: streak?.currentStreak ?? 0),
                      ),
                      const SizedBox(width: AppDimensions.space20),
                      Expanded(child: _AdherenceCard(stats: adherence)),
                    ],
                  ),
                )
              else ...[
                _StreakCard(streak: streak?.currentStreak ?? 0),
                const SizedBox(height: AppDimensions.space16),
                _AdherenceCard(stats: adherence),
              ],
              const SizedBox(height: AppDimensions.space24),
              medsAsync.when(
                // `nextMedication` — not `list.first` — so the card names the
                // same medication the verification flow will credit.
                data: (_) {
                  final med = ref.watch(nextMedicationProvider);
                  if (med == null) {
                    return _NoMedsCta(
                      onAdd: () =>
                          context.goNamed(AppRoute.onboardingMedication),
                    );
                  }
                  return _MedicationCard(
                    title: med.name,
                    time: med.scheduleTime.format(context),
                    onTake: () => context.goNamed(AppRoute.verification),
                    onEdit: () => context.goNamed(
                      AppRoute.medicationEdit,
                      extra: med,
                    ),
                  );
                },
                loading: () => const _MedSkeleton(),
                error: (err, _) => _MedError(message: err.toString()),
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
        Text(
          '$greeting, $name 👋',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 4),
        Text(
          AppDateUtils.formatDate(DateTime.now()),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurface.withValues(alpha: 0.6),
          ),
        ),
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
      padding: const EdgeInsets.all(AppDimensions.space20),
      decoration: BoxDecoration(
        gradient: AppColors.coralGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            size: 42,
            color: AppColors.onPrimary,
          ),
          const SizedBox(width: AppDimensions.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current streak',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.onPrimary.withValues(alpha: 0.85),
                  ),
                ),
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

class _MedSkeleton extends StatelessWidget {
  const _MedSkeleton();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}

class _MedError extends StatelessWidget {
  final String message;
  const _MedError({required this.message});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Couldn't load your medications",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.error),
          ),
        ],
      ),
    );
  }
}

class _AdherenceStats {
  final int verified;
  final int total;

  const _AdherenceStats({required this.verified, required this.total});

  factory _AdherenceStats.fromLogs(List<ComplianceLogModel> logs) {
    final now = DateTime.now();
    final cutoff = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));
    var verified = 0;
    var total = 0;
    for (final log in logs) {
      final d = DateTime(log.date.year, log.date.month, log.date.day);
      if (d.isBefore(cutoff)) continue;
      if (d.isAfter(DateTime(now.year, now.month, now.day))) continue;
      total++;
      if (log.status == ComplianceStatus.verified) verified++;
    }
    return _AdherenceStats(verified: verified, total: total);
  }

  double get progress => total == 0 ? 0.0 : verified / total;
  bool get hasData => total > 0;
}

class _AdherenceCard extends StatelessWidget {
  final _AdherenceStats stats;
  const _AdherenceCard({required this.stats});

  @override
  Widget build(BuildContext context) {
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
              const Icon(Icons.bar_chart_rounded, color: AppColors.secondary),
              const SizedBox(width: 8),
              Text(
                'Last 7 days',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space12),
          Text(
            stats.hasData
                ? '${stats.verified} of ${stats.total} on time'
                : 'No doses logged yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppDimensions.space8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            child: LinearProgressIndicator(
              value: stats.hasData ? stats.progress : 0,
              minHeight: 14,
              backgroundColor: AppColors.surface,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            stats.hasData
                ? '${(stats.progress * 100).round()}% verified'
                : 'Verify a dose to build your record.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _NoMedsCta extends StatelessWidget {
  final VoidCallback onAdd;
  const _NoMedsCta({required this.onAdd});

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
          const Icon(
            Icons.medical_information_rounded,
            color: AppColors.primary,
            size: 32,
          ),
          const SizedBox(height: AppDimensions.space8),
          Text(
            'No medications yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Add your first medication to start a streak.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppDimensions.space16),
          PrimaryButton(
            label: 'Add medication',
            icon: Icons.add_rounded,
            onPressed: onAdd,
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
  final VoidCallback onEdit;

  const _MedicationCard({
    required this.title,
    required this.time,
    required this.onTake,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.outline, width: 1),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.space24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                      ),
                      child: const Icon(
                        Icons.medication_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            'Today at $time',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.edit_outlined,
                      color: AppColors.outline,
                      size: 20,
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
          ),
        ),
      ),
    );
  }
}
