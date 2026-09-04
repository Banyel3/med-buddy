import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/medication_model.dart';
import 'auth_provider.dart';
import 'supabase_providers.dart';

final medicationsProvider = FutureProvider<List<MedicationModel>>((ref) async {
  final user = ref.watch(currentSupabaseUserProvider);
  if (user == null) return const [];
  return ref.read(supabaseServiceProvider).fetchMedications(user.id);
});

/// The medication a dose right now most likely belongs to: the active one
/// whose scheduled time sits closest to the current clock time, measured
/// around the 24h circle so a 23:00 dose still wins at 00:30.
///
/// Every dose-crediting path reads this, so a wrong answer here credits the
/// wrong medication everywhere at once. Previously this returned `meds.first`
/// — the earliest med of the day — which credited the 08:00 dose for an
/// 20:00 verification.
final nextMedicationProvider = Provider<MedicationModel?>((ref) {
  final meds = ref.watch(medicationsProvider).valueOrNull;
  if (meds == null) return null;
  final active = meds.where((m) => m.active).toList();
  if (active.isEmpty) return null;
  final now = TimeOfDay.fromDateTime(DateTime.now());
  return nearestScheduled(active, now);
});

/// Picks the medication scheduled nearest to [now] on a wrap-around clock.
/// Exposed for testing.
@visibleForTesting
MedicationModel nearestScheduled(List<MedicationModel> meds, TimeOfDay now) {
  int minutesOfDay(TimeOfDay t) => t.hour * 60 + t.minute;
  const dayMinutes = 24 * 60;
  final nowMinutes = minutesOfDay(now);

  int distance(MedicationModel m) {
    final delta = (minutesOfDay(m.scheduleTime) - nowMinutes).abs();
    return delta > dayMinutes ~/ 2 ? dayMinutes - delta : delta;
  }

  return meds.reduce((a, b) => distance(b) < distance(a) ? b : a);
}
