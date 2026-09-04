import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/compliance_log_model.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/compliance_provider.dart';
import '../../shared/providers/lock_provider.dart';
import '../../shared/providers/supabase_providers.dart';
import 'services/accessibility_lock_service.dart';

/// Writes the compliance rows for alarms that ended without a verified photo.
///
/// The alarm can finish while there is no Flutter engine alive — the phone
/// rang in someone's bag, hit the ceiling, and stopped. The native side parks
/// those outcomes; this drains them the next time the app runs and turns each
/// into a `missed` row.
///
/// `skipped` and `ceiling` both land as `missed`, because medically they are
/// the same thing: the dose wasn't taken. `skippedAt` is what separates them —
/// "they told us they couldn't" reads very differently to a worried monitor
/// than silence does, and that distinction is worth one nullable column rather
/// than a new status across five files.
class AlarmOutcomeSync {
  AlarmOutcomeSync(this._ref);

  final Ref _ref;

  Future<int> drainAndLog() async {
    final outcomes = await _ref
        .read(lockServiceProvider)
        .drainPendingOutcomes();
    if (outcomes.isEmpty) return 0;

    final user = _ref.read(currentSupabaseUserProvider);
    if (user == null) return 0;

    final svc = _ref.read(supabaseServiceProvider);
    var written = 0;

    for (final outcome in outcomes) {
      final day = DateTime(
        outcome.endedAt.year,
        outcome.endedAt.month,
        outcome.endedAt.day,
      );
      try {
        await svc.writeLog(
          ComplianceLogModel(
            id: '',
            medicationId: outcome.medicationId,
            userId: user.id,
            date: day,
            status: ComplianceStatus.missed,
            skippedAt: outcome.reason == AlarmEndReason.skipped
                ? outcome.endedAt
                : null,
          ),
        );
        written++;
      } catch (_) {
        // Offline, or the row is already terminal. Either way the dose is not
        // lost: daily-rollover marks an unverified day missed regardless, so
        // dropping this write costs at most the `skippedAt` annotation.
      }
    }

    if (written > 0) _ref.invalidate(complianceLogsProvider);
    return written;
  }
}

final alarmOutcomeSyncProvider = Provider<AlarmOutcomeSync>(
  (ref) => AlarmOutcomeSync(ref),
);
