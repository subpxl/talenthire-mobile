import 'model_helpers.dart';

enum UserRole { influencer, admin }

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
    this.onboardingCompleted = false,
    this.onboardingStep = 'mobile',
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
  bool onboardingCompleted;
  String onboardingStep;
  final DateTime createdAt;
  DateTime updatedAt;

  factory User.fromJson(Map<String, dynamic> json) {
    final hasOnboardingMeta = json.containsKey('onboarding_completed') ||
        json.containsKey('onboarding_step');
    final onboardingCompleted = hasOnboardingMeta
        ? json['onboarding_completed'] == true
        : true;
    final onboardingStep = !hasOnboardingMeta
        ? 'done'
        : (json['onboarding_step'] ??
                (onboardingCompleted ? 'done' : 'mobile'))
            .toString();
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
      onboardingCompleted: onboardingCompleted,
      onboardingStep: onboardingStep,
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
        'onboarding_completed': onboardingCompleted,
        'onboarding_step': onboardingStep,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  User copyWith({
    String? mobile,
    String? name,
    String? email,
    bool? isActive,
    bool? onboardingCompleted,
    String? onboardingStep,
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
      isActive: isActive ?? this.isActive,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      onboardingStep: onboardingStep ?? this.onboardingStep,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
