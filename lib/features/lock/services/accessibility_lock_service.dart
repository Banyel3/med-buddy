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
}
