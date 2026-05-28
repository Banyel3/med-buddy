class StreakModel {
  final String id;
  final String userId;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastVerifiedDate;
  final DateTime updatedAt;

  const StreakModel({
    required this.id,
    required this.userId,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastVerifiedDate,
    required this.updatedAt,
  });

  factory StreakModel.empty(String userId) => StreakModel(
    id: '',
    userId: userId,
    currentStreak: 0,
    longestStreak: 0,
    lastVerifiedDate: null,
    updatedAt: DateTime.now(),
  );

  factory StreakModel.fromJson(Map<String, dynamic> json) => StreakModel(
    id: (json['id'] as String?) ?? '',
    userId: json['user_id'] as String,
    currentStreak: (json['current_streak'] as int?) ?? 0,
    longestStreak: (json['longest_streak'] as int?) ?? 0,
    lastVerifiedDate: json['last_verified_date'] == null
        ? null
        : DateTime.parse(json['last_verified_date'] as String),
    updatedAt: DateTime.parse(
      json['updated_at'] as String? ?? DateTime.now().toIso8601String(),
    ),
  );

  Map<String, dynamic> toJson() => {
    if (id.isNotEmpty) 'id': id,
    'user_id': userId,
    'current_streak': currentStreak,
    'longest_streak': longestStreak,
    if (lastVerifiedDate != null)
      'last_verified_date': lastVerifiedDate!.toIso8601String().substring(
        0,
        10,
      ),
    'updated_at': updatedAt.toIso8601String(),
  };

  String get milestoneMessage {
    if (currentStreak >= 60) {
      return 'Two months and counting — this is a lifestyle now.';
    }
    if (currentStreak >= 30) {
      return 'One month! You are literally a different person.';
    }
    if (currentStreak >= 14) {
      return 'Two weeks strong — your body is healing.';
    }
    if (currentStreak >= 7) {
      return 'One full week. Iron levels are climbing.';
    }
    if (currentStreak >= 3) return 'Three days strong — keep it going.';
    if (currentStreak >= 1) return 'Every big thing starts with a single step.';
    return 'Tomorrow is a fresh start.';
  }
}
