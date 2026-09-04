enum ComplianceStatus { pending, verified, late, missed }

class ComplianceLogModel {
  final String id;
  final String medicationId;
  final String userId;
  final DateTime date;
  final ComplianceStatus status;
  final String? imageUrl;
  final DateTime? verifiedAt;
  final double? faceConfidence;
  final double? pillConfidence;

  /// Set when the patient pressed "I can't take it now" on the dose alarm.
  /// The status is still `missed` — the dose wasn't taken — but this tells the
  /// monitor they responded rather than ignored it.
  final DateTime? skippedAt;

  const ComplianceLogModel({
    required this.id,
    required this.medicationId,
    required this.userId,
    required this.date,
    required this.status,
    this.imageUrl,
    this.verifiedAt,
    this.faceConfidence,
    this.pillConfidence,
    this.skippedAt,
  });

  factory ComplianceLogModel.fromJson(Map<String, dynamic> json) =>
      ComplianceLogModel(
        id: (json['id'] as String?) ?? '',
        // medication_id is nullable in the schema (a log can outlive a
        // hard-deleted med). Empty string is the in-Dart stand-in for NULL.
        medicationId: (json['medication_id'] as String?) ?? '',
        userId: json['user_id'] as String,
        date: DateTime.parse(json['date'] as String),
        status: _parseStatus(json['status'] as String?),
        imageUrl: json['image_url'] as String?,
        verifiedAt: json['verified_at'] == null
            ? null
            : DateTime.parse(json['verified_at'] as String),
        faceConfidence: (json['face_confidence'] as num?)?.toDouble(),
        pillConfidence: (json['pill_confidence'] as num?)?.toDouble(),
        skippedAt: json['skipped_at'] == null
            ? null
            : DateTime.parse(json['skipped_at'] as String),
      );

  Map<String, dynamic> toJson() => {
    if (id.isNotEmpty) 'id': id,
    // Send NULL, not '' — Postgres rejects '' as a uuid.
    'medication_id': medicationId.isEmpty ? null : medicationId,
    'user_id': userId,
    'date': date.toIso8601String().substring(0, 10),
    'status': status.name,
    if (imageUrl != null) 'image_url': imageUrl,
    if (verifiedAt != null) 'verified_at': verifiedAt!.toIso8601String(),
    if (faceConfidence != null) 'face_confidence': faceConfidence,
    if (pillConfidence != null) 'pill_confidence': pillConfidence,
    if (skippedAt != null) 'skipped_at': skippedAt!.toIso8601String(),
  };

  static ComplianceStatus _parseStatus(String? value) {
    switch (value) {
      case 'verified':
        return ComplianceStatus.verified;
      case 'late':
        return ComplianceStatus.late;
      case 'missed':
        return ComplianceStatus.missed;
      default:
        return ComplianceStatus.pending;
    }
  }
}
