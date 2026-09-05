import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'app_router.dart';

/// Leaves a full-screen route safely.
///
/// Screens like /verification, /medication/edit and /credits are top-level
/// GoRoutes. When they are reached with `go`/`goNamed` the root Navigator
/// holds a single page and `context.pop()` throws
/// `GoError('There is nothing to pop')` — the close button silently does
/// nothing and hardware Back exits the app. Callers should `pushNamed` these
/// screens; this helper covers the case where they were `go`ne to anyway
/// (deep link, notification tap, lock screen).
extension SafeExit on BuildContext {
  void popOrHome() {
    if (canPop()) {
      pop();
    } else {
      goNamed(AppRoute.home);
    }
  }
}
