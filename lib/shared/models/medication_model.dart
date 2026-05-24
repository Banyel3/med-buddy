import 'package:flutter/material.dart';

class MedicationModel {
  final String id;
  final String userId;
  final String name;
  final TimeOfDay scheduleTime;
  final String notes;
  final bool active;
  final DateTime createdAt;

  const MedicationModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.scheduleTime,
    required this.notes,
    required this.active,
    required this.createdAt,
  });

  factory MedicationModel.fromJson(Map<String, dynamic> json) {
    final parts = ((json['schedule_time'] as String?) ?? '12:30:00').split(':');
    return MedicationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: (json['name'] as String?) ?? '',
      scheduleTime: TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      ),
      notes: (json['notes'] as String?) ?? '',
      active: (json['active'] as bool?) ?? true,
      createdAt: DateTime.parse(
          json['created_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'user_id': userId,
        'name': name,
        'schedule_time':
            '${_pad(scheduleTime.hour)}:${_pad(scheduleTime.minute)}:00',
        'notes': notes,
        'active': active,
        'created_at': createdAt.toIso8601String(),
      };

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
