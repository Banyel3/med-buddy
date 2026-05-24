import 'package:flutter_test/flutter_test.dart';
import 'package:medbuddy/shared/models/user_model.dart';

void main() {
  test('UserModel.fromJson defaults role=patient when missing', () {
    final u = UserModel.fromJson({
      'id': 'abc',
      'created_at': '2026-05-24T00:00:00.000Z',
    });
    expect(u.role, UserRole.patient);
    expect(u.timezone, 'Asia/Manila');
    expect(u.name, '');
  });

  test('UserModel.fromJson parses monitor role', () {
    final u = UserModel.fromJson({
      'id': 'abc',
      'role': 'monitor',
      'name': 'Ban',
      'timezone': 'UTC',
      'created_at': '2026-05-24T00:00:00.000Z',
    });
    expect(u.role, UserRole.monitor);
    expect(u.name, 'Ban');
    expect(u.timezone, 'UTC');
  });

  test('toJson serializes role enum name', () {
    final u = UserModel(
      id: 'a',
      name: 'X',
      role: UserRole.monitor,
      timezone: 'Asia/Manila',
      createdAt: DateTime.utc(2026, 5, 24),
    );
    expect(u.toJson()['role'], 'monitor');
  });
}
