enum UserRole { patient, monitor }

class UserModel {
  final String id;
  final String name;
  final UserRole role;
  final String timezone;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.role,
    required this.timezone,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String,
    name: (json['name'] as String?) ?? '',
    role: _parseRole(json['role'] as String?),
    timezone: (json['timezone'] as String?) ?? 'Asia/Manila',
    createdAt: DateTime.parse(
      json['created_at'] as String? ?? DateTime.now().toIso8601String(),
    ),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role.name,
    'timezone': timezone,
    'created_at': createdAt.toIso8601String(),
  };

  static UserRole _parseRole(String? value) =>
      value == 'monitor' ? UserRole.monitor : UserRole.patient;
}
