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

  Future<bool> activate() async {
    lockedNotifier.value = true;
    if (!_isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('activate') ?? false;
    } catch (e) {
      debugPrint('AccessibilityLockService.activate error: $e');
      return false;
    }
  }

  Future<bool> deactivate() async {
    lockedNotifier.value = false;
    if (!_isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('deactivate') ?? false;
    } catch (e) {
      debugPrint('AccessibilityLockService.deactivate error: $e');
      return false;
    }
  }

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

  /// Persist the lock mode in native SharedPreferences so the
  /// AlarmManager-driven overlay can read it without bouncing through
  /// Flutter (works even if app is killed). Mode is one of 'hard' / 'soft'.
  Future<void> setLockMode(LockMode mode) async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod('setLockMode', {'mode': mode.name});
    } catch (e) {
      debugPrint('setLockMode error: $e');
    }
  }

  Future<LockMode> getLockMode() async {
    if (!_isAndroid) return LockMode.hard;
    try {
      final raw = await _channel.invokeMethod<String>('getLockMode');
      return LockMode.values.firstWhere(
        (m) => m.name.toUpperCase() == raw?.toUpperCase(),
        orElse: () => LockMode.hard,
      );
    } catch (e) {
      return LockMode.hard;
    }
  }
}

enum LockMode { hard, soft }
