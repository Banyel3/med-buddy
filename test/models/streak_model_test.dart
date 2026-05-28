import 'package:flutter_test/flutter_test.dart';
import 'package:medbuddy/shared/models/streak_model.dart';

void main() {
  group('StreakModel.fromJson / toJson', () {
    test('roundtrips', () {
      final model = StreakModel(
        id: 'abc',
        userId: 'user-1',
        currentStreak: 7,
        longestStreak: 14,
        lastVerifiedDate: DateTime.utc(2026, 5, 24),
        updatedAt: DateTime.utc(2026, 5, 24, 12, 30),
      );
      final json = model.toJson();
      final back = StreakModel.fromJson({
        ...json,
        'last_verified_date': '2026-05-24',
        'updated_at': '2026-05-24T12:30:00.000Z',
      });
      expect(back.userId, 'user-1');
      expect(back.currentStreak, 7);
      expect(back.longestStreak, 14);
      expect(back.lastVerifiedDate, DateTime.parse('2026-05-24'));
    });

    test('empty constructor zeroes', () {
      final s = StreakModel.empty('u');
      expect(s.currentStreak, 0);
      expect(s.longestStreak, 0);
      expect(s.lastVerifiedDate, isNull);
    });

    test('fromJson tolerates missing fields', () {
      final s = StreakModel.fromJson({'user_id': 'u'});
      expect(s.currentStreak, 0);
      expect(s.longestStreak, 0);
    });
  });

  group('milestoneMessage thresholds', () {
    StreakModel of(int days) => StreakModel(
      id: '',
      userId: 'u',
      currentStreak: days,
      longestStreak: days,
      lastVerifiedDate: null,
      updatedAt: DateTime.now(),
    );

    test('0 days returns fresh start copy', () {
      expect(of(0).milestoneMessage, contains('fresh start'));
    });
    test('1-2 days returns day-1 copy', () {
      expect(of(1).milestoneMessage, contains('single step'));
      expect(of(2).milestoneMessage, contains('single step'));
    });
    test('3-6 days returns 3-day copy', () {
      expect(of(3).milestoneMessage, contains('Three days'));
      expect(of(6).milestoneMessage, contains('Three days'));
    });
    test('7-13 days returns weekly copy', () {
      expect(of(7).milestoneMessage, contains('One full week'));
      expect(of(13).milestoneMessage, contains('One full week'));
    });
    test('14-29 days returns two-week copy', () {
      expect(of(14).milestoneMessage, contains('Two weeks'));
      expect(of(29).milestoneMessage, contains('Two weeks'));
    });
    test('30-59 days returns one-month copy', () {
      expect(of(30).milestoneMessage, contains('One month'));
      expect(of(59).milestoneMessage, contains('One month'));
    });
    test('60+ days returns two-month copy', () {
      expect(of(60).milestoneMessage, contains('Two months'));
      expect(of(365).milestoneMessage, contains('Two months'));
    });
  });
}
