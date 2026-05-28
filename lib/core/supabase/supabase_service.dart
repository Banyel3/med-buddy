import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/models/compliance_log_model.dart';
import '../../shared/models/medication_model.dart';
import '../../shared/models/streak_model.dart';
import '../../shared/models/user_model.dart';
import 'supabase_client.dart';

/// Thin wrapper over Supabase for table queries used across the app.
class SupabaseService {
  SupabaseService();

  SupabaseClient get _db => SupabaseBootstrap.client;

  // ---- Users
  Future<UserModel?> fetchCurrentUser() async {
    final auth = _db.auth.currentUser;
    if (auth == null) return null;
    final row =
        await _db.from('users').select().eq('id', auth.id).maybeSingle();
    return row == null ? null : UserModel.fromJson(row);
  }

  Future<void> upsertUser(UserModel user) async {
    await _db.from('users').upsert(user.toJson());
  }

  // ---- Medications
  Future<List<MedicationModel>> fetchMedications(String userId) async {
    final rows = await _db
        .from('medications')
        .select()
        .eq('user_id', userId)
        .eq('active', true)
        .order('schedule_time');
    return rows
        .map<MedicationModel>((r) => MedicationModel.fromJson(r))
        .toList();
  }

  Future<MedicationModel> createMedication(MedicationModel med) async {
    final inserted =
        await _db.from('medications').insert(med.toJson()).select().single();
    return MedicationModel.fromJson(inserted);
  }

  Future<MedicationModel> updateMedication(MedicationModel med) async {
    final auth = _db.auth.currentUser;
    if (auth == null) {
      throw const AuthException('Not signed in.');
    }
    if (auth.id != med.userId) {
      throw const AuthException('You can only edit your own medications.');
    }
    final rows = await _db
        .from('medications')
        .update({
          'name': med.name,
          'schedule_time':
              '${_pad(med.scheduleTime.hour)}:${_pad(med.scheduleTime.minute)}:00',
          'notes': med.notes.isEmpty ? null : med.notes,
          'active': med.active,
        })
        .eq('id', med.id)
        .eq('user_id', med.userId)
        .select();
    if (rows.isEmpty) {
      throw StateError(
          'Medication not found or you no longer have access to it.');
    }
    return MedicationModel.fromJson(rows.first);
  }

  Future<void> deleteMedication(String medicationId) async {
    final auth = _db.auth.currentUser;
    if (auth == null) {
      throw const AuthException('Not signed in.');
    }
    // Soft-delete via active=false so compliance_logs FK to historic rows survives.
    final rows = await _db
        .from('medications')
        .update({'active': false})
        .eq('id', medicationId)
        .eq('user_id', auth.id)
        .select('id');
    if (rows.isEmpty) {
      throw StateError(
          'Medication not found or you no longer have access to it.');
    }
  }

  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? timezone,
  }) async {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (timezone != null) payload['timezone'] = timezone;
    if (payload.isEmpty) return;
    await _db.from('users').update(payload).eq('id', userId);
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');

  // ---- Compliance
  Future<List<ComplianceLogModel>> fetchLogs(
    String userId, {
    DateTime? from,
    DateTime? to,
  }) async {
    var q = _db.from('compliance_logs').select().eq('user_id', userId);
    if (from != null) q = q.gte('date', from.toIso8601String().substring(0, 10));
    if (to != null) q = q.lte('date', to.toIso8601String().substring(0, 10));
    final rows = await q.order('date', ascending: false);
    return rows
        .map<ComplianceLogModel>((r) => ComplianceLogModel.fromJson(r))
        .toList();
  }

  Future<ComplianceLogModel> writeLog(ComplianceLogModel log) async {
    final inserted = await _db
        .from('compliance_logs')
        .insert(log.toJson())
        .select()
        .single();
    return ComplianceLogModel.fromJson(inserted);
  }

  // ---- Streak
  Future<StreakModel?> fetchStreak(String userId) async {
    final row =
        await _db.from('streaks').select().eq('user_id', userId).maybeSingle();
    return row == null ? null : StreakModel.fromJson(row);
  }

  // ---- Storage (verification photos — private bucket, signed URL)
  Future<String> uploadVerificationPhoto({
    required String userId,
    required Uint8List bytes,
    required DateTime timestamp,
  }) async {
    final path =
        '$userId/${timestamp.toIso8601String().replaceAll(':', '-')}.jpg';
    await _db.storage.from('verifications').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );
    final signed = await _db.storage
        .from('verifications')
        .createSignedUrl(path, 60 * 60 * 24);
    return signed;
  }

  // ---- Realtime
  RealtimeChannel watchLogs(String userId, void Function(Map<String, dynamic>) onChange) {
    return _db
        .channel('compliance_logs:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'compliance_logs',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) => onChange(payload.newRecord),
        )
        .subscribe();
  }
}
