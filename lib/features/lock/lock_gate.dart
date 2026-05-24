import 'package:flutter/material.dart';

import 'lock_screen.dart';
import 'services/accessibility_lock_service.dart';

/// Wraps the entire app. Whenever AccessibilityLockService.lockedNotifier
/// flips to true (notification fires, manual arm, etc.), an opaque
/// LockScreen modal is laid on top of whatever the user was viewing.
/// On Android the native overlay also fires; this gate makes sure iOS
/// (and any Android device where overlay perm is denied) still has a
/// blocking in-app lock.
class LockGate extends StatelessWidget {
  final Widget child;
  const LockGate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AccessibilityLockService.instance.lockedNotifier,
      builder: (context, locked, _) {
        return Stack(
          children: [
            child,
            if (locked)
              const Positioned.fill(
                child: Material(
                  type: MaterialType.transparency,
                  child: LockScreen(),
                ),
              ),
          ],
        );
      },
    );
  }
}
