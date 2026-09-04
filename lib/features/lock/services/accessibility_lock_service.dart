import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Dart-side bridge to the Android MedBuddyAccessibility +
/// LockOverlayService pair. On iOS (sandbox prohibits true system
/// overlay) the service flips a [lockedNotifier] flag that the
/// Flutter UI listens to and renders a full-screen modal LockScreen
/// inside MedBuddy. See LockGate widget.
class AccessibilityLockService {
  AccessibilityLockService._();
  static final AccessibilityLockService instance = AccessibilityLockService._();

  static const _channel = MethodChannel('medbuddy/lock');

  /// True while the lock is armed — drives the in-app modal fallback
  /// when the native overlay can't run (iOS, missing perms on Android).
  final ValueNotifier<bool> lockedNotifier = ValueNotifier<bool>(false);

  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  Future<bool> isAccessibilityEnabled() async {
    if (!_isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('isAccessibilityEnabled') ??
          false;
    } catch (e) {
      return false;
    }
  }

  Future<void> openAccessibilitySettings() async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } catch (e) {
      debugPrint('openAccessibilitySettings error: $e');
    }
  }

  Future<bool> canDrawOverlays() async {
    if (!_isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('canDrawOverlays') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> requestOverlayPermission() async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } catch (e) {
      debugPrint('requestOverlayPermission error: $e');
    }
  }

  /// Schedule the native exact alarm that flips the lock on regardless
  /// of whether the app is foregrounded. Fires at `hour:minute + 30min`
  /// each day until cancelled. No-op on non-Android.
  Future<void> scheduleLockAlarm({
    required String medId,
    required String medName,
    required int hour,
    required int minute,
  }) async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod('scheduleLockAlarm', {
        'medId': medId,
        'medName': medName,
        'hour': hour,
        'minute': minute,
      });
    } catch (e) {
      debugPrint('scheduleLockAlarm error: $e');
    }
  }

  Future<void> cancelLockAlarm(String medId) async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod('cancelLockAlarm', {'medId': medId});
    } catch (e) {
      debugPrint('cancelLockAlarm error: $e');
    }
  }

  Future<void> cancelAllLockAlarms() async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod('cancelAllLockAlarms');
    } catch (e) {
      debugPrint('cancelAllLockAlarms error: $e');
    }
  }

  /// Persist whether dose alarms are on in native SharedPreferences, so the
  /// AlarmManager-driven receiver can read it without starting the Flutter VM
  /// (works even if the app is killed).
  Future<void> setAlarmEnabled(bool enabled) async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod('setAlarmEnabled', {'enabled': enabled});
    } catch (e) {
      debugPrint('setAlarmEnabled error: $e');
    }
  }

  Future<bool> isAlarmEnabled() async {
    if (!_isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('isAlarmEnabled') ?? true;
    } catch (e) {
      return true;
    }
  }

  /// Silence a ringing alarm. Called the moment a dose is verified.
  Future<void> stopAlarm() async {
    lockedNotifier.value = false;
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod('stopAlarm');
    } catch (e) {
      debugPrint('stopAlarm error: $e');
    }
  }

  /// The escape hatch: the user says they can't take this dose right now.
  /// Stops the alarm and queues the outcome so it reaches the monitor.
  Future<void> skipDose() async {
    lockedNotifier.value = false;
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod('skipDose');
    } catch (e) {
      debugPrint('skipDose error: $e');
    }
  }

  /// How long an alarm rings before it gives up. Native owns the value so the
  /// countdown on the overlay and the one in Flutter can't drift apart.
  Future<int> alarmCeilingMinutes() async {
    if (!_isAndroid) return 5;
    try {
      return await _channel.invokeMethod<int>('alarmCeilingMinutes') ?? 5;
    } catch (e) {
      return 5;
    }
  }

  /// Outcomes of alarms that ended while Dart wasn't running. Each entry is
  /// `medId|reason|epochMillis`; draining is destructive.
  Future<List<AlarmOutcome>> drainPendingOutcomes() async {
    if (!_isAndroid) return const [];
    try {
      final raw = await _channel.invokeListMethod<String>(
        'drainPendingOutcomes',
      );
      if (raw == null) return const [];
      return raw
          .map(AlarmOutcome.tryParse)
          .whereType<AlarmOutcome>()
          .toList(growable: false);
    } catch (e) {
      debugPrint('drainPendingOutcomes error: $e');
      return const [];
    }
  }
}

/// Why a dose alarm stopped without a verified photo.
enum AlarmEndReason {
  /// The user pressed "I can't take it now".
  skipped,

  /// The alarm rang for its full window and gave up.
  ceiling,
}

/// One alarm that ended without a verification, waiting to be logged.
class AlarmOutcome {
  final String medicationId;
  final AlarmEndReason reason;
  final DateTime endedAt;

  const AlarmOutcome({
    required this.medicationId,
    required this.reason,
    required this.endedAt,
  });

  /// Parses `medId|reason|epochMillis`. Returns null on anything malformed
  /// rather than throwing — a corrupt queue entry must not block the rest.
  static AlarmOutcome? tryParse(String raw) {
    final parts = raw.split('|');
    if (parts.length != 3) return null;
    final millis = int.tryParse(parts[2]);
    if (millis == null) return null;
    final reason = switch (parts[1]) {
      'skipped' => AlarmEndReason.skipped,
      'ceiling' => AlarmEndReason.ceiling,
      _ => null,
    };
    if (reason == null) return null;
    return AlarmOutcome(
      medicationId: parts[0],
      reason: reason,
      endedAt: DateTime.fromMillisecondsSinceEpoch(millis),
    );
  }
}
