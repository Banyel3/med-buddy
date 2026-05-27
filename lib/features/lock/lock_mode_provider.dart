import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/accessibility_lock_service.dart';

const _prefsKey = 'medbuddy.lockMode';
const _envKey = 'MEDBUDDY_LOCK_MODE';

/// Priority for resolving the active lock mode (highest wins):
///   1. `--dart-define=MEDBUDDY_LOCK_MODE=hard|soft`         (build flag)
///   2. `.env` MEDBUDDY_LOCK_MODE                            (per-machine override)
///   3. User preference persisted in SharedPreferences
///   4. Default: HARD
///
/// When 1 or 2 is set, the Profile toggle disables (env-pinned).
class LockModeEnv {
  LockModeEnv._();

  /// Compile-time flag. Provide via:
  ///   flutter run --dart-define=MEDBUDDY_LOCK_MODE=soft
  ///   flutter build apk --dart-define=MEDBUDDY_LOCK_MODE=hard
  static const String _dartDefine =
      String.fromEnvironment('MEDBUDDY_LOCK_MODE', defaultValue: '');

  /// Returns the build-or-env-forced mode, or null if neither is set.
  static LockMode? resolve() {
    final candidates = <String?>[
      _dartDefine.isEmpty ? null : _dartDefine,
      _readDotEnv(),
    ];
    for (final raw in candidates) {
      if (raw == null) continue;
      final v = raw.trim().toLowerCase();
      if (v == 'hard') return LockMode.hard;
      if (v == 'soft') return LockMode.soft;
    }
    return null;
  }

  static String? _readDotEnv() {
    try {
      return dotenv.maybeGet(_envKey);
    } catch (_) {
      return null;
    }
  }
}

class LockModeController extends StateNotifier<LockMode> {
  /// True when state was forced by build flag or .env (UI must lock the toggle).
  bool envPinned = false;

  LockModeController() : super(LockMode.hard) {
    _restore();
  }

  Future<void> _restore() async {
    final forced = LockModeEnv.resolve();
    if (forced != null) {
      envPinned = true;
      state = forced;
      if (kDebugMode) {
        debugPrint('[LockMode] env override active: ${forced.name}');
      }
      await AccessibilityLockService.instance.setLockMode(forced);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      state = LockMode.values.firstWhere(
        (m) => m.name == raw,
        orElse: () => LockMode.hard,
      );
    }
    await AccessibilityLockService.instance.setLockMode(state);
  }

  Future<void> set(LockMode mode) async {
    if (envPinned) return; // ignore user toggles when build/env-forced
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode.name);
    await AccessibilityLockService.instance.setLockMode(mode);
  }
}

final lockModeProvider =
    StateNotifierProvider<LockModeController, LockMode>(
        (ref) => LockModeController());
