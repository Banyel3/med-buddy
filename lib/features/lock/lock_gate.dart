import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import 'lock_screen.dart';
import 'services/accessibility_lock_service.dart';

/// Wraps the entire app. Whenever AccessibilityLockService.lockedNotifier
/// flips to true (native alarm fired, "Verify now" on the overlay, cold start
/// mid-alarm), an opaque LockScreen modal is laid on top of whatever the user
/// was viewing. On Android the native overlay also fires; this gate makes sure
/// iOS (and any Android device where overlay perm is denied) still has a
/// blocking in-app lock.
///
/// The gate lives *above* the Router, so it would also cover the verification
/// screen the lock itself opens. It steps aside while the current route is
/// /verification and comes back the moment the user leaves it unverified.
class LockGate extends ConsumerWidget {
  final Widget child;
  const LockGate({super.key, required this.child});

  static const _passthroughPaths = ['/verification'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final delegate = ref.watch(routerProvider).routerDelegate;
    return ValueListenableBuilder<bool>(
      valueListenable: AccessibilityLockService.instance.lockedNotifier,
      builder: (context, locked, _) {
        // routerDelegate, not routeInformationProvider: the latter only tracks
        // declarative go() and still reports /verification after the pushed
        // camera route has been popped.
        return AnimatedBuilder(
          animation: delegate,
          builder: (context, _) {
            final matches = delegate.currentConfiguration.matches;
            final path = matches.isEmpty ? '' : matches.last.matchedLocation;
            final passthrough = _passthroughPaths.any(path.startsWith);
            return Stack(
              children: [
                child,
                if (locked && !passthrough)
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
      },
    );
  }
}
