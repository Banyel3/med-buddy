import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/compliance_log_model.dart';
import 'auth_provider.dart';
import 'supabase_providers.dart';

final complianceLogsProvider = FutureProvider<List<ComplianceLogModel>>((
  ref,
) async {
  final user = ref.watch(currentSupabaseUserProvider);
  if (user == null) return const [];
  final now = DateTime.now();
  return ref
      .read(supabaseServiceProvider)
      .fetchLogs(
        user.id,
        from: DateTime(now.year, now.month - 2, 1),
        to: DateTime(now.year, now.month + 1, 0),
      );
});

final todayLogProvider = Provider<ComplianceLogModel?>((ref) {
  final logs = ref.watch(complianceLogsProvider).valueOrNull;
  if (logs == null) return null;
  final now = DateTime.now();
  for (final log in logs) {
    if (log.date.year == now.year &&
        log.date.month == now.month &&
        log.date.day == now.day) {
      return log;
    }
  }
  return null;
});
