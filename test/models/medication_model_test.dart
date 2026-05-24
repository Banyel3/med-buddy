import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medbuddy/shared/models/medication_model.dart';

void main() {
  group('MedicationModel', () {
    test('parses HH:MM:SS schedule_time string', () {
      final med = MedicationModel.fromJson({
        'id': 'm1',
        'user_id': 'u',
        'name': 'Iron',
        'schedule_time': '12:30:00',
        'created_at': '2026-05-24T00:00:00.000Z',
      });
      expect(med.scheduleTime.hour, 12);
      expect(med.scheduleTime.minute, 30);
      expect(med.active, isTrue);
    });

    test('toJson serializes schedule_time with zero-padded HH:MM:SS', () {
      final med = MedicationModel(
        id: 'm',
        userId: 'u',
        name: 'X',
        scheduleTime: const TimeOfDay(hour: 7, minute: 5),
        notes: 'with food',
        active: true,
        createdAt: DateTime.utc(2026, 5, 24),
      );
      final json = med.toJson();
      expect(json['schedule_time'], '07:05:00');
      expect(json['notes'], 'with food');
    });

    test('omits empty id from toJson (insert path)', () {
      final med = MedicationModel(
        id: '',
        userId: 'u',
        name: 'X',
        scheduleTime: const TimeOfDay(hour: 0, minute: 0),
        notes: '',
        active: true,
        createdAt: DateTime.now(),
      );
      expect(med.toJson().containsKey('id'), isFalse);
    });

    test('falls back to 12:30:00 default if schedule_time missing', () {
      final med = MedicationModel.fromJson({
        'id': 'x',
        'user_id': 'u',
        'name': 'X',
      });
      expect(med.scheduleTime.hour, 12);
      expect(med.scheduleTime.minute, 30);
    });
  });
}
