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
    this.accountDeletedAt,
    this.onboardingCompleted = false,
    this.onboardingStep = 'mobile',
    this.referredByCode,
    this.latitude,
    this.longitude,
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
  DateTime? accountDeletedAt;
  bool onboardingCompleted;

  bool get isAccountDeleted => accountDeletedAt != null;
  String onboardingStep;
  final String? referredByCode;
  final double? latitude;
  final double? longitude;
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
      accountDeletedAt: parseFlexibleDate(json['account_deleted_at']),
      onboardingCompleted: onboardingCompleted,
      onboardingStep: onboardingStep,
      referredByCode: (json['referred_by_code'] ?? '').toString().trim().isEmpty
          ? null
          : (json['referred_by_code'] ?? '').toString().trim(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
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
        if (referredByCode != null && referredByCode!.isNotEmpty)
          'referred_by_code': referredByCode,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  User copyWith({
    String? mobile,
    String? name,
    String? email,
    bool? isActive,
    DateTime? accountDeletedAt,
    bool? onboardingCompleted,
    String? onboardingStep,
    double? latitude,
    double? longitude,
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
      accountDeletedAt: accountDeletedAt ?? this.accountDeletedAt,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      onboardingStep: onboardingStep ?? this.onboardingStep,
      referredByCode: referredByCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
