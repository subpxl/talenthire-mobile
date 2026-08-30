import 'model_helpers.dart';

enum UserRole { influencer }

class User {
  User({
    required this.id,
    this.mobile = '',
    this.name = '',
    this.email = '',
    this.role = UserRole.influencer,
    this.birthDay,
    this.birthMonth,
    this.birthYear,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  String mobile;
  String name;
  String email;
  UserRole role;
  int? birthDay;
  int? birthMonth;
  int? birthYear;
  bool isActive;
  final DateTime createdAt;
  DateTime updatedAt;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      mobile: (json['mobile'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: enumFromString(
        UserRole.values,
        (json['role'] ?? 'influencer').toString(),
        UserRole.influencer,
      ),
      birthDay: (json['birth_day'] ?? json['birthDay']) as int?,
      birthMonth: (json['birth_month'] ?? json['birthMonth']) as int?,
      birthYear: (json['birth_year'] ?? json['birthYear']) as int?,
      isActive: json['is_active'] ?? true,
      createdAt: parseFlexibleDate(json['created_at']) ?? DateTime.now(),
      updatedAt: parseFlexibleDate(json['updated_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'mobile': mobile,
        'name': name,
        'email': email,
        'role': role.name,
        if (birthDay != null) 'birth_day': birthDay,
        if (birthMonth != null) 'birth_month': birthMonth,
        if (birthYear != null) 'birth_year': birthYear,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  User copyWith({
    String? mobile,
    String? name,
    String? email,
    DateTime? updatedAt,
  }) {
    return User(
      id: id,
      mobile: mobile ?? this.mobile,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role,
      birthDay: birthDay,
      birthMonth: birthMonth,
      birthYear: birthYear,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
