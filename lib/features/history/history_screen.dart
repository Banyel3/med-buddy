import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/device_utils.dart';
import '../../shared/models/compliance_log_model.dart';
import '../../shared/providers/compliance_provider.dart';
import '../../shared/providers/streak_provider.dart';
import '../../shared/widgets/medbuddy_scaffold.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakProvider).valueOrNull;
    final logs = ref.watch(complianceLogsProvider).valueOrNull ?? const [];
    final isTablet = DeviceUtils.isTablet(context);

    final body = SingleChildScrollView(
      padding: pagePadding(context),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StreakHero(
              current: streak?.currentStreak ?? 0,
              longest: streak?.longestStreak ?? 0,
            ),
            const SizedBox(height: AppDimensions.space24),
            if (isTablet)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _MonthlyRing(
                          rate: _monthRate(logs)),
                    ),
                    const SizedBox(width: AppDimensions.space20),
                    Expanded(
                      flex: 2,
                      child: _ComplianceCalendar(logs: logs),
                    ),
                  ],
                ),
              )
            else ...[
              _MonthlyRing(rate: _monthRate(logs)),
              const SizedBox(height: AppDimensions.space16),
              _ComplianceCalendar(logs: logs),
            ],
            const SizedBox(height: AppDimensions.space24),
            _LogList(logs: logs),
          ],
        ),
      ),
    );

    return SafeArea(child: body);
  }

  double _monthRate(List<ComplianceLogModel> logs) {
    final now = DateTime.now();
    final monthLogs = logs.where(
        (l) => l.date.year == now.year && l.date.month == now.month);
    if (monthLogs.isEmpty) return 0;
    final verified =
        monthLogs.where((l) => l.status == ComplianceStatus.verified).length;
    return verified / monthLogs.length;
  }
}

class _StreakHero extends StatelessWidget {
  final int current;
  final int longest;
  const _StreakHero({required this.current, required this.longest});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space24),
      decoration: BoxDecoration(
        gradient: AppColors.coralGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.30),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.local_fire_department_rounded,
              size: 64, color: AppColors.onPrimary),
          const SizedBox(height: 8),
          Text('$current',
              style: Theme.of(context)
                  .textTheme
                  .displayLarge
                  ?.copyWith(color: AppColors.onPrimary, fontSize: 96)),
          Text('day streak',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: AppColors.onPrimary)),
          const SizedBox(height: 8),
          Text('Longest: $longest days',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onPrimary.withValues(alpha: 0.85))),
        ],
      ),
    );
  }
}

class _MonthlyRing extends StatelessWidget {
  final double rate;
  const _MonthlyRing({required this.rate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Column(
        children: [
          Text('This month',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppDimensions.space16),
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: rate,
                    strokeWidth: 14,
                    backgroundColor: AppColors.surface,
                    color: AppColors.secondary,
                  ),
                ),
                Text('${(rate * 100).round()}%',
                    style: Theme.of(context).textTheme.headlineMedium),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.space12),
          Text('Compliance rate',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ComplianceCalendar extends StatelessWidget {
  final List<ComplianceLogModel> logs;
  const _ComplianceCalendar({required this.logs});

  Color _colorFor(DateTime day) {
    final now = DateTime.now();
    if (day.isAfter(now)) return AppColors.surface;
    final log = logs.firstWhere(
      (l) =>
          l.date.year == day.year &&
          l.date.month == day.month &&
          l.date.day == day.day,
      orElse: () => ComplianceLogModel(
        id: '',
        medicationId: '',
        userId: '',
        date: day,
        status: ComplianceStatus.missed,
      ),
    );
    switch (log.status) {
      case ComplianceStatus.verified:
        return AppColors.secondary;
      case ComplianceStatus.late:
        return AppColors.warning;
      case ComplianceStatus.missed:
        return AppColors.outline.withValues(alpha: 0.5);
      case ComplianceStatus.pending:
        return AppColors.surface;
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = AppDateUtils.currentMonthDays(DateTime.now());
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Daily history',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppDimensions.space12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1,
            ),
            itemBuilder: (_, i) {
              final day = days[i];
              return Container(
                decoration: BoxDecoration(
                  color: _colorFor(day),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  border: Border.all(color: AppColors.outline, width: 0.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${day.day}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: day.isAfter(DateTime.now())
                          ? AppColors.onSurface.withValues(alpha: 0.4)
                          : AppColors.onSurface),
                ),
              );
            },
          ),
          const SizedBox(height: AppDimensions.space12),
          Row(
            children: [
              _LegendDot(color: AppColors.secondary, label: 'Verified'),
              const SizedBox(width: 12),
              _LegendDot(color: AppColors.warning, label: 'Late'),
              const SizedBox(width: 12),
              _LegendDot(
                  color: AppColors.outline.withValues(alpha: 0.5),
                  label: 'Missed'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      );
}

class _LogList extends StatelessWidget {
  final List<ComplianceLogModel> logs;
  const _LogList({required this.logs});

  @override
  Widget build(BuildContext context) {
    final recent = logs.take(10).toList();
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent doses',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppDimensions.space12),
          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppDimensions.space16),
              child: Text('No doses logged yet — your history will show here.',
                  style: Theme.of(context).textTheme.bodyMedium),
            )
          else
            ...recent.map((l) => _LogRow(log: l)),
        ],
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  final ComplianceLogModel log;
  const _LogRow({required this.log});

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    String label;
    switch (log.status) {
      case ComplianceStatus.verified:
        badgeColor = AppColors.secondary;
        label = 'Verified';
        break;
      case ComplianceStatus.late:
        badgeColor = AppColors.warning;
        label = 'Late';
        break;
      case ComplianceStatus.missed:
        badgeColor = AppColors.error;
        label = 'Missed';
        break;
      case ComplianceStatus.pending:
        badgeColor = AppColors.outline;
        label = 'Pending';
        break;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppDateUtils.formatDate(log.date),
                    style: Theme.of(context).textTheme.bodyLarge),
                if (log.verifiedAt != null)
                  Text(AppDateUtils.formatTime(log.verifiedAt!),
                      style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              border: Border.all(color: badgeColor, width: 1),
            ),
            child: Text(label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: badgeColor, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
