import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medbuddy/features/lock/services/accessibility_lock_service.dart';
import 'package:medbuddy/features/verification/controllers/verification_controller.dart'
    as vc;
import 'package:medbuddy/features/verification/controllers/verification_controller.dart'
    show
        faceDetectionServiceProvider,
        pillDetectionServiceProvider,
        verificationControllerProvider;
import 'package:medbuddy/features/verification/services/face_detection_service.dart';
import 'package:medbuddy/features/verification/services/pill_detection_service.dart';
import 'package:medbuddy/shared/models/compliance_log_model.dart';
import 'package:medbuddy/shared/providers/auth_provider.dart';
import 'package:medbuddy/shared/providers/lock_provider.dart';
import 'package:medbuddy/shared/providers/medication_provider.dart';
import 'package:medbuddy/shared/providers/supabase_providers.dart';
import 'package:medbuddy/core/supabase/supabase_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeFace implements FaceDetectionService {
  _FakeFace(this.value);
  final double value;
  @override
  Future<double> detectFromFile(String path) async => value;
  @override
  Future<double> detectFromCameraImage(image, camera) async => value;
  @override
  Future<void> dispose() async {}
}

class _FakePill implements PillDetectionService {
  _FakePill(this.value);
  final double value;
  @override
  Future<bool> ensureLoaded() async => true;
  @override
  Future<double> detectFromFile(String path) async => value;
  @override
  Future<double> detectFromBytes(bytes) async => value;
  @override
  void dispose() {}
}

class _MockSupabaseService extends Mock implements SupabaseService {}

class _MockLockService extends Mock implements AccessibilityLockService {}

class _FakeUser extends Fake implements User {
  @override
  String get id => 'user-1';
  @override
  String? get email => 'x@y';
}

ProviderContainer _container({
  required FaceDetectionService face,
  required PillDetectionService pill,
  required SupabaseService supabase,
  required AccessibilityLockService lock,
  User? user,
}) {
  final c = ProviderContainer(overrides: [
    faceDetectionServiceProvider.overrideWithValue(face),
    pillDetectionServiceProvider.overrideWithValue(pill),
    supabaseServiceProvider.overrideWithValue(supabase),
    lockServiceProvider.overrideWithValue(lock),
    currentSupabaseUserProvider.overrideWith((ref) => user),
    nextMedicationProvider.overrideWith((ref) => null),
  ]);
  // Keep the autoDispose controller alive for the duration of the test.
  c.listen(verificationControllerProvider, (_, _) {}, fireImmediately: true);
  return c;
}

void main() {
  setUpAll(() {
    registerFallbackValue(ComplianceLogModel(
      id: '',
      medicationId: '',
      userId: 'u',
      date: DateTime(2026, 5, 24),
      status: ComplianceStatus.verified,
    ));
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(DateTime(2026, 5, 24));
  });

  group('VerificationController.analyzeCapture', () {
    test('marks passed=true when both confidences clear thresholds',
        () async {
      final supa = _MockSupabaseService();
      final lock = _MockLockService();
      final c = _container(
        face: _FakeFace(0.95),
        pill: _FakePill(0.85),
        supabase: supa,
        lock: lock,
        user: _FakeUser(),
      );
      addTearDown(c.dispose);
      final ctrl = c.read(verificationControllerProvider.notifier);
      await ctrl.analyzeCapture('/tmp/nonexistent.jpg');
      final state = c.read(verificationControllerProvider);
      expect(state.analyzing, false);
      expect(state.lastResult, isNotNull);
      expect(state.lastResult!.passed, true);
      expect(state.lastResult!.faceConfidence, 0.95);
      expect(state.lastResult!.pillConfidence, 0.85);
    });

    test('marks passed=false when face below threshold', () async {
      final c = _container(
        face: _FakeFace(0.50),
        pill: _FakePill(0.90),
        supabase: _MockSupabaseService(),
        lock: _MockLockService(),
        user: _FakeUser(),
      );
      addTearDown(c.dispose);
      // Stub writeLog so the fire-and-forget late-attempt call succeeds.
      when(() => (c.read(supabaseServiceProvider) as _MockSupabaseService)
              .writeLog(any()))
          .thenAnswer((_) async => ComplianceLogModel(
                id: 'x',
                medicationId: '',
                userId: 'user-1',
                date: DateTime(2026, 5, 24),
                status: ComplianceStatus.late,
              ));
      final ctrl = c.read(verificationControllerProvider.notifier);
      await ctrl.analyzeCapture('/tmp/nonexistent.jpg');
      final state = c.read(verificationControllerProvider);
      expect(state.lastResult!.passed, false);
    });

    test('marks passed=false when pill below threshold', () async {
      final c = _container(
        face: _FakeFace(0.95),
        pill: _FakePill(0.50),
        supabase: _MockSupabaseService(),
        lock: _MockLockService(),
        user: _FakeUser(),
      );
      addTearDown(c.dispose);
      when(() => (c.read(supabaseServiceProvider) as _MockSupabaseService)
              .writeLog(any()))
          .thenAnswer((_) async => ComplianceLogModel(
                id: 'x',
                medicationId: '',
                userId: 'user-1',
                date: DateTime(2026, 5, 24),
                status: ComplianceStatus.late,
              ));
      final ctrl = c.read(verificationControllerProvider.notifier);
      await ctrl.analyzeCapture('/tmp/nonexistent.jpg');
      expect(
          c.read(verificationControllerProvider).lastResult!.passed, false);
    });

    test('exact threshold values pass', () async {
      final c = _container(
        face: _FakeFace(vc.VerificationResult.faceThreshold),
        pill: _FakePill(vc.VerificationResult.pillThreshold),
        supabase: _MockSupabaseService(),
        lock: _MockLockService(),
        user: _FakeUser(),
      );
      addTearDown(c.dispose);
      final ctrl = c.read(verificationControllerProvider.notifier);
      await ctrl.analyzeCapture('/tmp/x.jpg');
      expect(
          c.read(verificationControllerProvider).lastResult!.passed, true);
    });
  });

  group('VerificationController.confirmDose', () {
    test('returns false when no lastResult', () async {
      final c = _container(
        face: _FakeFace(0),
        pill: _FakePill(0),
        supabase: _MockSupabaseService(),
        lock: _MockLockService(),
        user: _FakeUser(),
      );
      addTearDown(c.dispose);
      final ok = await c
          .read(verificationControllerProvider.notifier)
          .confirmDose();
      expect(ok, false);
    });

    test('returns false when lastResult.passed=false', () async {
      final c = _container(
        face: _FakeFace(0.10),
        pill: _FakePill(0.10),
        supabase: _MockSupabaseService(),
        lock: _MockLockService(),
        user: _FakeUser(),
      );
      addTearDown(c.dispose);
      // Stub late-attempt log to avoid noise.
      when(() => (c.read(supabaseServiceProvider) as _MockSupabaseService)
              .writeLog(any()))
          .thenAnswer((_) async => ComplianceLogModel(
                id: 'x',
                medicationId: '',
                userId: 'user-1',
                date: DateTime(2026, 5, 24),
                status: ComplianceStatus.late,
              ));
      final ctrl = c.read(verificationControllerProvider.notifier);
      await ctrl.analyzeCapture('/tmp/x.jpg');
      final ok = await ctrl.confirmDose();
      expect(ok, false);
    });

    test('uploads bytes + writes verified log + deactivates lock on success',
        () async {
      final supa = _MockSupabaseService();
      final lock = _MockLockService();
      final tmp = await File(
              '${Directory.systemTemp.createTempSync('vc').path}/cap.jpg')
          .writeAsBytes(List<int>.filled(8, 0xFF));
      when(() => supa.uploadVerificationPhoto(
            userId: any(named: 'userId'),
            bytes: any(named: 'bytes'),
            timestamp: any(named: 'timestamp'),
          )).thenAnswer((_) async => 'https://signed.example/url');
      when(() => supa.writeLog(any())).thenAnswer(
        (_) async => ComplianceLogModel(
          id: 'log-1',
          medicationId: '',
          userId: 'user-1',
          date: DateTime(2026, 5, 24),
          status: ComplianceStatus.verified,
        ),
      );
      when(() => lock.deactivate()).thenAnswer((_) async => true);

      final c = _container(
        face: _FakeFace(0.95),
        pill: _FakePill(0.85),
        supabase: supa,
        lock: lock,
        user: _FakeUser(),
      );
      addTearDown(c.dispose);
      final ctrl = c.read(verificationControllerProvider.notifier);
      await ctrl.analyzeCapture(tmp.path);
      final ok = await ctrl.confirmDose();
      expect(ok, true);

      verify(() => supa.uploadVerificationPhoto(
            userId: 'user-1',
            bytes: any(named: 'bytes'),
            timestamp: any(named: 'timestamp'),
          )).called(1);
      verify(() => supa.writeLog(any(that: predicate<ComplianceLogModel>(
              (log) => log.status == ComplianceStatus.verified)))).called(1);
      verify(() => lock.deactivate()).called(1);
    });
  });

  group('VerificationController.resetForRetake', () {
    test('clears state back to defaults', () async {
      final c = _container(
        face: _FakeFace(0.95),
        pill: _FakePill(0.85),
        supabase: _MockSupabaseService(),
        lock: _MockLockService(),
        user: _FakeUser(),
      );
      addTearDown(c.dispose);
      final ctrl = c.read(verificationControllerProvider.notifier);
      await ctrl.analyzeCapture('/tmp/x.jpg');
      expect(c.read(verificationControllerProvider).lastResult, isNotNull);
      ctrl.resetForRetake();
      final s = c.read(verificationControllerProvider);
      expect(s.lastResult, isNull);
      expect(s.analyzing, false);
      expect(s.submitting, false);
    });
  });
}
