import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_service.dart';

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});
