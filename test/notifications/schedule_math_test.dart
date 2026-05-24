import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medbuddy/core/notifications/schedule_math.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(() {
    tzdata.initializeTimeZones();
  });

  group('ScheduleMath.addMinutes', () {
    test('adds within same hour', () {
      final t = ScheduleMath.addMinutes(const TimeOfDay(hour: 12, minute: 30), 15);
      expect(t.hour, 12);
      expect(t.minute, 45);
    });

    test('wraps over the hour', () {
      final t = ScheduleMath.addMinutes(const TimeOfDay(hour: 12, minute: 55), 30);
      expect(t.hour, 13);
      expect(t.minute, 25);
    });

    test('wraps across midnight', () {
      final t = ScheduleMath.addMinutes(const TimeOfDay(hour: 23, minute: 50), 30);
      expect(t.hour, 0);
      expect(t.minute, 20);
    });

    test('handles 24h add (identity)', () {
      const start = TimeOfDay(hour: 7, minute: 5);
      final t = ScheduleMath.addMinutes(start, 24 * 60);
      expect(t.hour, 7);
      expect(t.minute, 5);
    });

    test('negative minutes wrap backwards', () {
      final t = ScheduleMath.addMinutes(const TimeOfDay(hour: 0, minute: 10), -20);
      expect(t.hour, 23);
      expect(t.minute, 50);
    });
  });

  group('ScheduleMath.nextInstanceOf', () {
    late tz.Location manila;
    setUpAll(() {
      manila = tz.getLocation('Asia/Manila');
    });

    test('returns today if scheduled time is later today', () {
      final now = tz.TZDateTime(manila, 2026, 5, 24, 10, 0);
      final next = ScheduleMath.nextInstanceOf(
        const TimeOfDay(hour: 12, minute: 30),
        manila,
        now: now,
      );
      expect(next.day, 24);
      expect(next.hour, 12);
      expect(next.minute, 30);
    });

    test('rolls to tomorrow when current time has passed', () {
      final now = tz.TZDateTime(manila, 2026, 5, 24, 14, 0);
      final next = ScheduleMath.nextInstanceOf(
        const TimeOfDay(hour: 12, minute: 30),
        manila,
        now: now,
      );
      expect(next.day, 25);
      expect(next.hour, 12);
      expect(next.minute, 30);
    });

    test('exact match counts as past (rolls to tomorrow)', () {
      final now = tz.TZDateTime(manila, 2026, 5, 24, 12, 30);
      final next = ScheduleMath.nextInstanceOf(
        const TimeOfDay(hour: 12, minute: 30),
        manila,
        now: now,
      );
      expect(next.day, 25);
    });
  });
}
