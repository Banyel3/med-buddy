import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/compliance_log_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/lock_provider.dart';
import '../../../shared/providers/medication_provider.dart';
import '../../../shared/providers/supabase_providers.dart';
import '../services/face_detection_service.dart';
import '../services/pill_detection_service.dart';

class VerificationResult {
  final double faceConfidence;
  final double pillConfidence;
  final String capturedPath;
  final bool passed;

  const VerificationResult({
    required this.faceConfidence,
    required this.pillConfidence,
    required this.capturedPath,
    required this.passed,
  });

  static const faceThreshold = 0.80;
  static const pillThreshold = 0.75;
}

class VerificationState {
  final bool analyzing;
  final bool submitting;
  final VerificationResult? lastResult;
  final String? error;

  const VerificationState({
    this.analyzing = false,
    this.submitting = false,
    this.lastResult,
    this.error,
  });

  VerificationState copyWith({
    bool? analyzing,
    bool? submitting,
    VerificationResult? lastResult,
    String? error,
    bool clearResult = false,
    bool clearError = false,
  }) =>
      VerificationState(
        analyzing: analyzing ?? this.analyzing,
        submitting: submitting ?? this.submitting,
        lastResult: clearResult ? null : (lastResult ?? this.lastResult),
        error: clearError ? null : (error ?? this.error),
      );
}

class VerificationController extends StateNotifier<VerificationState> {
  VerificationController(this._ref) : super(const VerificationState());

  final Ref _ref;
  final _face = FaceDetectionService();
  final _pill = PillDetectionService();

  Future<void> analyzeCapture(String filePath) async {
    state = state.copyWith(
        analyzing: true, clearError: true, clearResult: true);
    try {
      final faceConf = await _face.detectFromFile(filePath);
      final pillConf = await _pill.detectFromFile(filePath);
      final passed = faceConf >= VerificationResult.faceThreshold &&
          pillConf >= VerificationResult.pillThreshold;
      state = state.copyWith(
        analyzing: false,
        lastResult: VerificationResult(
          faceConfidence: faceConf,
          pillConfidence: pillConf,
          capturedPath: filePath,
          passed: passed,
        ),
      );
    } catch (e, st) {
      debugPrint('VerificationController.analyzeCapture error: $e\n$st');
      state = state.copyWith(analyzing: false, error: e.toString());
    }
  }

  Future<bool> confirmDose() async {
    final result = state.lastResult;
    if (result == null || !result.passed) return false;
    state = state.copyWith(submitting: true, clearError: true);
    try {
      final user = _ref.read(currentSupabaseUserProvider);
      if (user == null) throw StateError('Not signed in');
      final med = _ref.read(nextMedicationProvider);
      final bytes = await File(result.capturedPath).readAsBytes();
      final svc = _ref.read(supabaseServiceProvider);
      final now = DateTime.now();
      final imageUrl = await svc.uploadVerificationPhoto(
        userId: user.id,
        bytes: bytes,
        timestamp: now,
      );
      await svc.writeLog(
        ComplianceLogModel(
          id: '',
          medicationId: med?.id ?? '',
          userId: user.id,
          date: DateTime(now.year, now.month, now.day),
          status: ComplianceStatus.verified,
          imageUrl: imageUrl,
          verifiedAt: now,
          faceConfidence: result.faceConfidence,
          pillConfidence: result.pillConfidence,
        ),
      );
      // Release the lock if active (Phase 3).
      await _ref.read(lockServiceProvider).deactivate();
      state = state.copyWith(submitting: false);
      return true;
    } catch (e, st) {
      debugPrint('VerificationController.confirmDose error: $e\n$st');
      state = state.copyWith(submitting: false, error: e.toString());
      return false;
    }
  }

  void resetForRetake() {
    state = const VerificationState();
  }

  @override
  void dispose() {
    _face.dispose();
    _pill.dispose();
    super.dispose();
  }
}

final verificationControllerProvider =
    StateNotifierProvider.autoDispose<VerificationController, VerificationState>(
        (ref) => VerificationController(ref));
