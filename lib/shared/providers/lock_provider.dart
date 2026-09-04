import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/lock/services/accessibility_lock_service.dart';

final lockServiceProvider = Provider<AccessibilityLockService>(
  (ref) => AccessibilityLockService.instance,
);
