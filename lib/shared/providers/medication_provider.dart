import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/medication_model.dart';
import 'auth_provider.dart';
import 'supabase_providers.dart';

final medicationsProvider = FutureProvider<List<MedicationModel>>((ref) async {
  final user = ref.watch(currentSupabaseUserProvider);
  if (user == null) return const [];
  return ref.read(supabaseServiceProvider).fetchMedications(user.id);
});

final nextMedicationProvider = Provider<MedicationModel?>((ref) {
  final meds = ref.watch(medicationsProvider).valueOrNull;
  if (meds == null || meds.isEmpty) return null;
  return meds.first;
});
