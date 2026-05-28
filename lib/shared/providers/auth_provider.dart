import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_client.dart';
import '../models/user_model.dart';
import 'supabase_providers.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  return SupabaseBootstrap.client.auth.onAuthStateChange;
});

final currentSupabaseUserProvider = Provider<User?>((ref) {
  ref.watch(authStateProvider);
  return SupabaseBootstrap.client.auth.currentUser;
});

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  ref.watch(authStateProvider);
  return ref.read(supabaseServiceProvider).fetchCurrentUser();
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController() : super(const AsyncValue.data(null));

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseBootstrap.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signUp(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseBootstrap.client.auth.signUp(
        email: email,
        password: password,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await SupabaseBootstrap.client.auth.signOut();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>(
      (ref) => AuthController(),
    );
