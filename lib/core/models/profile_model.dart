import 'model_helpers.dart';

enum AccountStatus { active, inactive, suspended }

enum SubscriptionStatus { free, premium, expired }

class SocialPlatformMetric {
  SocialPlatformMetric({
    required this.platform,
    this.handle = '',
    this.followers = 0,
    this.url = '',
  });

  final String platform;
  final String handle;
  final int followers;
  final String url;

  factory SocialPlatformMetric.fromJson(Map<String, dynamic> json) {
    return SocialPlatformMetric(
      platform: (json['platform'] ?? json['name'] ?? '').toString(),
      handle: (json['handle'] ?? '').toString(),
      followers: (json['followers'] as num?)?.toInt() ?? 0,
      url: (json['url'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'platform': platform,
        'handle': handle,
        'followers': followers,
        'url': url,
      };

  SocialPlatformMetric copyWith({
    String? platform,
    String? handle,
    int? followers,
    String? url,
  }) {
    return SocialPlatformMetric(
      platform: platform ?? this.platform,
      handle: handle ?? this.handle,
      followers: followers ?? this.followers,
      url: url ?? this.url,
    );
  }
}

class Profile {
  Profile({
    required this.userId,
    this.profileImage = '',
    List<String>? photos,
    this.isVerified = false,
    this.talent = 'influencer',
    this.bio = '',
    this.contact = '',
    this.city = '',
    this.state = '',
    this.age,
    this.gender = '',
    this.height,
    List<String>? languages,
    List<String>? niches,
    List<SocialPlatformMetric>? platformMetrics,
    Map<String, dynamic>? formData,
    this.profileCompleted = false,
    this.subscriptionStatus = SubscriptionStatus.free,
    this.accountStatus = AccountStatus.active,
    this.freeJobApplicationsUsed = 0,
  })  : photos = photos ?? [],
        languages = languages ?? [],
        niches = niches ?? [],
        platformMetrics = platformMetrics ?? [],
        formData = formData ?? {};

  final String userId;
  String profileImage;
  List<String> photos;
  bool isVerified;
  String talent;
  String bio;
  String contact;
  String city;
  String state;
  int? age;
  String gender;
  String? height;
  List<String> languages;
  List<String> niches;
  List<SocialPlatformMetric> platformMetrics;
  Map<String, dynamic> formData;
  bool profileCompleted;
  SubscriptionStatus subscriptionStatus;
  AccountStatus accountStatus;
  int freeJobApplicationsUsed;

  bool get isPremium => subscriptionStatus == SubscriptionStatus.premium;

  int get completionPercentage {
    var score = 0;
    if (profileImage.trim().isNotEmpty) score += 20;

    final personal = formSection('personal');
    final hasGender = gender.isNotEmpty || (personal['gender']?.toString().isNotEmpty ?? false);
    final hasAge = age != null || (personal['age']?.toString().isNotEmpty ?? false);
    final hasLocation = city.isNotEmpty || state.isNotEmpty || (personal['location']?.toString().isNotEmpty ?? false);
    final hasLang = languages.isNotEmpty || (personal['language'] != null || personal['languages'] != null);
    if (hasGender) score += 5;
    if (hasAge) score += 5;
    if (hasLocation) score += 5;
    if (hasLang) score += 5;

    if (bio.trim().isNotEmpty || (personal['about']?.toString().trim().isNotEmpty ?? false)) {
      score += 10;
    }

    final work = formSection('work');
    if (work.isNotEmpty || talent.isNotEmpty) score += 15;

    final content = formSection('content');
    if (niches.isNotEmpty || content.isNotEmpty) score += 15;

    final social = formSection('social');
    if (platformMetrics.isNotEmpty || contact.isNotEmpty || social.isNotEmpty) score += 10;

    final rates = formSection('rates');
    final prefs = formSection('preferences');
    if (rates.isNotEmpty || prefs.isNotEmpty) score += 10;

    if (score > 100) score = 100;
    return score;
  }

  static const maxPhotos = 4;

  List<String> get galleryPhotos {
    final urls = <String>[];
    if (profileImage.isNotEmpty) urls.add(profileImage);
    for (final photo in photos) {
      if (photo.isNotEmpty && !urls.contains(photo)) urls.add(photo);
    }
    return urls.take(maxPhotos).toList();
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      profileImage: (json['profile_image'] ?? '').toString(),
      photos: stringList(json['photos']),
      isVerified: json['is_verified'] == true,
      talent: (json['talent'] ?? 'influencer').toString(),
      bio: (json['bio'] ?? '').toString(),
      contact: (json['contact'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      state: (json['state'] ?? '').toString(),
      age: (json['age'] as num?)?.toInt(),
      gender: (json['gender'] ?? '').toString(),
      height: json['height']?.toString(),
      languages: stringList(json['languages']),
      niches: stringList(json['niches']),
      platformMetrics: json['platform_metrics'] is List
          ? (json['platform_metrics'] as List)
              .whereType<Map>()
              .map(
                (item) => SocialPlatformMetric.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : const [],
      formData: mapFrom(json['form_data']),
      profileCompleted: json['profile_completed'] == true,
      subscriptionStatus: enumFromString(
        SubscriptionStatus.values,
        (json['subscription_status'] ?? 'free').toString(),
        SubscriptionStatus.free,
      ),
      accountStatus: enumFromString(
        AccountStatus.values,
        (json['account_status'] ?? 'active').toString(),
        AccountStatus.active,
      ),
      freeJobApplicationsUsed:
          (json['free_job_applications_used'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'profile_image': profileImage,
        'photos': photos,
        'is_verified': isVerified,
        'talent': talent,
        'bio': bio,
        'contact': contact,
        'city': city,
        'state': state,
        'age': age,
        'gender': gender,
        'height': height,
        'languages': languages,
        'niches': niches,
        'platform_metrics': platformMetrics.map((item) => item.toJson()).toList(),
        'form_data': formData,
        'profile_completed': profileCompleted,
        'subscription_status': subscriptionStatus.name,
        'account_status': accountStatus.name,
        'free_job_applications_used': freeJobApplicationsUsed,
      };

  Profile copyWith({
    String? profileImage,
    List<String>? photos,
    String? bio,
    String? contact,
    String? city,
    String? state,
    int? age,
    String? gender,
    String? height,
    String? talent,
    List<String>? languages,
    List<String>? niches,
    List<SocialPlatformMetric>? platformMetrics,
    Map<String, dynamic>? formData,
  }) {
    return Profile(
      userId: userId,
      profileImage: profileImage ?? this.profileImage,
      photos: photos ?? this.photos,
      isVerified: isVerified,
      talent: talent ?? this.talent,
      bio: bio ?? this.bio,
      contact: contact ?? this.contact,
      city: city ?? this.city,
      state: state ?? this.state,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      languages: languages ?? this.languages,
      niches: niches ?? this.niches,
      platformMetrics: platformMetrics ?? this.platformMetrics,
      formData: formData ?? this.formData,
      profileCompleted: profileCompleted,
      subscriptionStatus: subscriptionStatus,
      accountStatus: accountStatus,
      freeJobApplicationsUsed: freeJobApplicationsUsed,
    );
  }

  Map<String, dynamic> formSection(String key) => mapFrom(formData[key]);

  String formValue(String section, String key, [String fallback = '-']) {
    final value = formSection(section)[key];
    if (value == null) return fallback;
    if (value is List) {
      final items = value.map((item) => item.toString()).where((item) => item.isNotEmpty);
      return items.isEmpty ? fallback : items.join(', ');
    }
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  Profile mergeFormSection(String section, Map<String, dynamic> data) {
    return copyWith(
      formData: {
        ...formData,
        section: {
          ...formSection(section),
          ...data,
        },
      },
    );
  }
}
