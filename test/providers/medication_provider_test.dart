import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medbuddy/shared/models/medication_model.dart';
import 'package:medbuddy/shared/providers/medication_provider.dart';

MedicationModel _med(String name, int hour, int minute) => MedicationModel(
  id: name,
  userId: 'u1',
  name: name,
  scheduleTime: TimeOfDay(hour: hour, minute: minute),
  notes: '',
  active: true,
  createdAt: DateTime.utc(2026, 1, 1),
);

void main() {
  group('nearestScheduled', () {
    final morning = _med('morning', 8, 0);
    final evening = _med('evening', 20, 0);
    final meds = [morning, evening];

    test('picks the morning dose just after it is due', () {
      expect(
        nearestScheduled(meds, const TimeOfDay(hour: 9, minute: 0)).name,
        'morning',
      );
    });

    test('picks the evening dose in the evening — not meds.first', () {
      expect(
        nearestScheduled(meds, const TimeOfDay(hour: 20, minute: 10)).name,
        'evening',
      );
    });

    test('prefers the upcoming dose when it is the nearer one', () {
      expect(
        nearestScheduled(meds, const TimeOfDay(hour: 18, minute: 0)).name,
        'evening',
      );
    });

    test('wraps around midnight', () {
      final overnight = [_med('noon', 12, 0), _med('late', 23, 0)];
      expect(
        nearestScheduled(overnight, const TimeOfDay(hour: 0, minute: 30)).name,
        'late',
      );
    });

    test('single medication is always the answer', () {
      expect(
        nearestScheduled([morning], const TimeOfDay(hour: 23, minute: 59)).name,
        'morning',
      );
    });
  });
}
