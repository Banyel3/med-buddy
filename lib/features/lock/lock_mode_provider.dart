import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/accessibility_lock_service.dart';

const _prefsKey = 'medbuddy.lockMode';

class LockModeController extends StateNotifier<LockMode> {
  LockModeController() : super(LockMode.hard) {
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      state = LockMode.values.firstWhere(
        (m) => m.name == raw,
        orElse: () => LockMode.hard,
      );
    }
    // Sync to native (idempotent — overlay reads native prefs at fire time).
    await AccessibilityLockService.instance.setLockMode(state);
  }

  Future<void> set(LockMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode.name);
    await AccessibilityLockService.instance.setLockMode(mode);
  }
}

final lockModeProvider =
    StateNotifierProvider<LockModeController, LockMode>(
        (ref) => LockModeController());
