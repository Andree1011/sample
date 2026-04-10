class User {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? phone;
  final bool biometricEnabled;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.phone,
    this.biometricEnabled = false,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatar_url'] as String?,
      phone: json['phone'] as String?,
      biometricEnabled: json['biometric_enabled'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'avatar_url': avatarUrl,
        'phone': phone,
        'biometric_enabled': biometricEnabled,
        'created_at': createdAt.toIso8601String(),
      };

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    String? phone,
    bool? biometricEnabled,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
