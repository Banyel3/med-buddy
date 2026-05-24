import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Dart-side bridge to the Android MedBuddyAccessibility + LockOverlayService
/// pair. On iOS every call is a no-op (sandbox does not permit a true
/// system overlay — Phase 1 modal acts as the iOS lock).
class AccessibilityLockService {
  AccessibilityLockService._();
  static final AccessibilityLockService instance = AccessibilityLockService._();

  static const _channel = MethodChannel('medbuddy/lock');

  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  Future<bool> activate() async {
    if (!_isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('activate') ?? false;
    } catch (e) {
      debugPrint('AccessibilityLockService.activate error: $e');
      return false;
    }
  }

  Future<bool> deactivate() async {
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
