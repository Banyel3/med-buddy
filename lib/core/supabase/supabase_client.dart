import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Boots Supabase from .env. Call once from main() before runApp.
class SupabaseBootstrap {
  SupabaseBootstrap._();

  static Future<void> init() async {
    final url = dotenv.maybeGet('SUPABASE_URL') ?? '';
    final anon = dotenv.maybeGet('SUPABASE_ANON_KEY') ?? '';

    if (url.isEmpty || anon.isEmpty || url.contains('placeholder')) {
      // Soft-init so the app still boots in pre-config dev. Auth/db will no-op.
      // ignore: avoid_print
      print(
        '[SupabaseBootstrap] WARN: .env missing real credentials — '
        'using placeholder. Fill .env to enable backend.',
      );
    }

    // `publishableKey` is the current name for what the Supabase dashboard
    // still labels the anon key — same value, `anonKey` is deprecated.
    await Supabase.initialize(
      url: url.isEmpty ? 'https://placeholder.supabase.co' : url,
      publishableKey: anon.isEmpty ? 'placeholder' : anon,
      debug: false,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
