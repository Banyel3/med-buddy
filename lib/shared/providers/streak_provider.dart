import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/streak_model.dart';
import 'auth_provider.dart';
import 'supabase_providers.dart';

final streakProvider = FutureProvider<StreakModel>((ref) async {
  final user = ref.watch(currentSupabaseUserProvider);
  if (user == null) return StreakModel.empty('');
  final svc = ref.read(supabaseServiceProvider);
  final streak = await svc.fetchStreak(user.id);
  return streak ?? StreakModel.empty(user.id);
});
