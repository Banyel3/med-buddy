import 'package:intl/intl.dart';

/// Date helpers. App default timezone Asia/Manila (configured per user in DB).
class AppDateUtils {
  AppDateUtils._();

  static DateTime startOfDay(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  static DateTime endOfDay(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day, 23, 59, 59, 999);

  static String formatTime(DateTime dt) => DateFormat.jm().format(dt);

  static String formatDate(DateTime dt) => DateFormat.yMMMMd().format(dt);

  static String formatShortDate(DateTime dt) => DateFormat.MMMd().format(dt);

  static String formatDayName(DateTime dt) => DateFormat.EEEE().format(dt);

  static int daysBetween(DateTime a, DateTime b) {
    final start = startOfDay(a);
    final end = startOfDay(b);
    return end.difference(start).inDays;
  }

  static List<DateTime> currentMonthDays(DateTime ref) {
    final first = DateTime(ref.year, ref.month, 1);
    final next = DateTime(ref.year, ref.month + 1, 1);
    final daysInMonth = next.difference(first).inDays;
    return List.generate(daysInMonth, (i) => first.add(Duration(days: i)));
  }
}
