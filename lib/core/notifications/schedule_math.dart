import 'package:flutter/material.dart' show TimeOfDay;
import 'package:timezone/timezone.dart' as tz;

/// Pure helpers extracted from NotificationService so they can be unit
/// tested without booting the plugin / platform channels.
class ScheduleMath {
  ScheduleMath._();

  /// Adds [minutes] to a TimeOfDay, wrapping over midnight (mod 24h).
  static TimeOfDay addMinutes(TimeOfDay t, int minutes) {
    final total = t.hour * 60 + t.minute + minutes;
    final normalized = total % (24 * 60);
    final wrapped = normalized < 0 ? normalized + 24 * 60 : normalized;
    return TimeOfDay(hour: wrapped ~/ 60, minute: wrapped % 60);
  }

  /// Returns the next [tz.TZDateTime] whose time-of-day matches [t]
  /// in the given [location]. If today's instance is already past
  /// [now], shifts to tomorrow.
  static tz.TZDateTime nextInstanceOf(
    TimeOfDay t,
    tz.Location location, {
    tz.TZDateTime? now,
  }) {
    final current = now ?? tz.TZDateTime.now(location);
    var scheduled = tz.TZDateTime(
      location,
      current.year,
      current.month,
      current.day,
      t.hour,
      t.minute,
    );
    if (!scheduled.isAfter(current)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
