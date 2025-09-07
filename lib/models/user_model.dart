class UserModel {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? avatar;
  final String role; // 'tenant', 'host', 'admin'
  final bool isEmailVerified;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? language; // 'ar', 'fr'
  final bool isActive;

  UserModel({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
    this.avatar,
    required this.role,
    required this.isEmailVerified,
    required this.createdAt,
    required this.updatedAt,
    this.language,
    required this.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      phone: json['phone'],
      avatar: json['avatar'],
      role: json['role'],
      isEmailVerified: json['is_email_verified'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      language: json['language'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'avatar': avatar,
      'role': role,
      'is_email_verified': isEmailVerified,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'language': language,
      'is_active': isActive,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? avatar,
    String? role,
    bool? isEmailVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? language,
    bool? isActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      language: language ?? this.language,
      isActive: isActive ?? this.isActive,
    );
  }

  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    } else if (lastName != null) {
      return lastName!;
    }
    return email;
  }

  bool get isHost => role == 'host';
  bool get isTenant => role == 'tenant';
  bool get isAdmin => role == 'admin';
}