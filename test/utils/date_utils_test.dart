import 'package:flutter_test/flutter_test.dart';
import 'package:medbuddy/core/utils/date_utils.dart';

void main() {
  group('AppDateUtils', () {
    test('startOfDay zeroes time', () {
      final d = AppDateUtils.startOfDay(DateTime(2026, 5, 24, 15, 30, 7));
      expect(d, DateTime(2026, 5, 24));
    });

    test('endOfDay is 23:59:59.999', () {
      final d = AppDateUtils.endOfDay(DateTime(2026, 5, 24));
      expect(d.hour, 23);
      expect(d.minute, 59);
      expect(d.second, 59);
      expect(d.millisecond, 999);
    });

    test('daysBetween counts whole calendar days', () {
      expect(
        AppDateUtils.daysBetween(
          DateTime(2026, 5, 24, 22, 0),
          DateTime(2026, 5, 25, 1, 0),
        ),
        1,
      );
      expect(
        AppDateUtils.daysBetween(
          DateTime(2026, 5, 1),
          DateTime(2026, 5, 31),
        ),
        30,
      );
    });

    test('currentMonthDays returns every day of the month', () {
      final days = AppDateUtils.currentMonthDays(DateTime(2026, 2, 15));
      expect(days, hasLength(28));
      expect(days.first, DateTime(2026, 2, 1));
      expect(days.last, DateTime(2026, 2, 28));
    });

    test('currentMonthDays handles 31-day months', () {
      final days = AppDateUtils.currentMonthDays(DateTime(2026, 1, 15));
      expect(days, hasLength(31));
    });
  });
}
