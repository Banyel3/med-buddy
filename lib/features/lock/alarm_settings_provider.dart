import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/accessibility_lock_service.dart';

const _prefsKey = 'medbuddy.alarmEnabled';
const _envKey = 'MEDBUDDY_ALARM';

/// Priority for resolving whether dose alarms ring (highest wins):
///   1. `--dart-define=MEDBUDDY_ALARM=on|off`   (build flag)
///   2. `.env` MEDBUDDY_ALARM                   (per-machine override)
///   3. User preference in SharedPreferences
///   4. Default: on
///
/// When 1 or 2 is set the Profile toggle disables (env-pinned). Keep the alarm
/// off on dev machines: a QA build that rings the device every 15 minutes gets
/// uninstalled fast.
class AlarmEnabledEnv {
  AlarmEnabledEnv._();

  /// Compile-time flag. Provide via:
  ///   flutter run --dart-define=MEDBUDDY_ALARM=off
  ///   flutter build apk --dart-define=MEDBUDDY_ALARM=on
  static const String _dartDefine = String.fromEnvironment(
    'MEDBUDDY_ALARM',
    defaultValue: '',
  );

  /// Returns the build-or-env-forced setting, or null if neither is set.
  static bool? resolve() {
    final candidates = <String?>[
      _dartDefine.isEmpty ? null : _dartDefine,
      _readDotEnv(),
    ];
    for (final raw in candidates) {
      if (raw == null) continue;
      final parsed = parseFlag(raw);
      if (parsed != null) return parsed;
    }
    return null;
  }

  /// Accepts on/off, true/false, 1/0. Returns null for anything else so a
  /// typo falls through to the next source rather than silently disabling
  /// the alarm.
  @visibleForTesting
  static bool? parseFlag(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'on':
      case 'true':
      case '1':
        return true;
      case 'off':
      case 'false':
      case '0':
        return false;
      default:
        return null;
    }
  }

  static String? _readDotEnv() {
    try {
      return dotenv.maybeGet(_envKey);
    } catch (_) {
      return null;
    }
  }
}

class AlarmSettingsController extends StateNotifier<bool> {
  /// True when the setting was forced by build flag or .env, so the UI must
  /// lock the toggle.
  bool envPinned = false;

  AlarmSettingsController() : super(true) {
    _restore();
  }

  Future<void> _restore() async {
    final forced = AlarmEnabledEnv.resolve();
    if (forced != null) {
      envPinned = true;
      state = forced;
      if (kDebugMode) {
        debugPrint('[Alarm] env override active: $forced');
      }
      await AccessibilityLockService.instance.setAlarmEnabled(forced);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_prefsKey) ?? true;
    await AccessibilityLockService.instance.setAlarmEnabled(state);
  }

  Future<void> set(bool enabled) async {
    if (envPinned) return; // ignore user toggles when build/env-forced
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, enabled);
    await AccessibilityLockService.instance.setAlarmEnabled(enabled);
  }
}

final alarmEnabledProvider =
    StateNotifierProvider<AlarmSettingsController, bool>(
      (ref) => AlarmSettingsController(),
    );
