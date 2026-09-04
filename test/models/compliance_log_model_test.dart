import 'package:flutter_test/flutter_test.dart';
import 'package:medbuddy/shared/models/compliance_log_model.dart';

void main() {
  group('ComplianceLogModel.fromJson status parsing', () {
    ComplianceLogModel parse(String status) => ComplianceLogModel.fromJson({
      'medication_id': 'm',
      'user_id': 'u',
      'date': '2026-05-24',
      'status': status,
    });

    test(
      'verified',
      () => expect(parse('verified').status, ComplianceStatus.verified),
    );
    test('late', () => expect(parse('late').status, ComplianceStatus.late));
    test(
      'missed',
      () => expect(parse('missed').status, ComplianceStatus.missed),
    );
    test(
      'pending',
      () => expect(parse('pending').status, ComplianceStatus.pending),
    );
    test(
      'unknown → pending',
      () => expect(parse('garbage').status, ComplianceStatus.pending),
    );
    test('null → pending', () {
      final log = ComplianceLogModel.fromJson({
        'medication_id': 'm',
        'user_id': 'u',
        'date': '2026-05-24',
      });
      expect(log.status, ComplianceStatus.pending);
    });
  });

  test('toJson date serializes as ISO-10 string', () {
    final log = ComplianceLogModel(
      id: '',
      medicationId: 'm',
      userId: 'u',
      date: DateTime.utc(2026, 5, 24, 12, 30),
      status: ComplianceStatus.verified,
      verifiedAt: DateTime.utc(2026, 5, 24, 12, 30),
      faceConfidence: 0.92,
      pillConfidence: 0.81,
    );
    final json = log.toJson();
    expect(json['date'], '2026-05-24');
    expect(json['status'], 'verified');
    expect(json['face_confidence'], 0.92);
    expect(json['pill_confidence'], 0.81);
    expect(json.containsKey('id'), isFalse);
    expect(json['medication_id'], 'm');
  });

  test('empty medicationId round-trips as SQL NULL, never as ""', () {
    final json = ComplianceLogModel(
      id: '',
      medicationId: '',
      userId: 'u',
      date: DateTime.utc(2026, 5, 24),
      status: ComplianceStatus.late,
    ).toJson();
    // Postgres rejects '' as a uuid — this must be null on the wire.
    expect(json['medication_id'], isNull);

    final back = ComplianceLogModel.fromJson({
      'medication_id': null,
      'user_id': 'u',
      'date': '2026-05-24',
      'status': 'late',
    });
    expect(back.medicationId, '');
  });

  group('skippedAt', () {
    test('omitted from toJson when the dose was not actively declined', () {
      final json = ComplianceLogModel(
        id: '',
        medicationId: 'm',
        userId: 'u',
        date: DateTime.utc(2026, 5, 24),
        status: ComplianceStatus.missed,
      ).toJson();
      expect(json.containsKey('skipped_at'), isFalse);
    });

    test('round-trips when the patient said they could not take it', () {
      final at = DateTime.utc(2026, 5, 24, 8, 40);
      final json = ComplianceLogModel(
        id: '',
        medicationId: 'm',
        userId: 'u',
        date: DateTime.utc(2026, 5, 24),
        // A declined dose is still medically missed — skippedAt is what
        // separates "they told us" from silence.
        status: ComplianceStatus.missed,
        skippedAt: at,
      ).toJson();
      expect(json['status'], 'missed');
      expect(json['skipped_at'], at.toIso8601String());

      final back = ComplianceLogModel.fromJson({
        'medication_id': 'm',
        'user_id': 'u',
        'date': '2026-05-24',
        'status': 'missed',
        'skipped_at': at.toIso8601String(),
      });
      expect(back.skippedAt, at);
      expect(back.status, ComplianceStatus.missed);
    });
  });
}
