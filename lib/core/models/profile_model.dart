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
    List<String>? photoThumbs,
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
        photoThumbs = photoThumbs ?? [],
        languages = languages ?? [],
        niches = niches ?? [],
        platformMetrics = platformMetrics ?? [],
        formData = formData ?? {};

  final String userId;
  String profileImage;
  List<String> photos;
  List<String> photoThumbs;
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

    if (profileImage.trim().isNotEmpty) score += 15;

    final personal = formSection('personal');
    final hasGender = gender.isNotEmpty || _hasText(personal['gender']);
    final hasAge = age != null || _hasText(personal['age']);
    final hasLocation = city.isNotEmpty ||
        state.isNotEmpty ||
        _hasText(personal['location']);
    final hasLang = languages.isNotEmpty ||
        _hasList(personal['language']) ||
        _hasList(personal['languages']);
    final hasAbout = bio.trim().isNotEmpty || _hasText(personal['about']);
    if (hasGender) score += 7;
    if (hasAge) score += 7;
    if (hasLocation) score += 7;
    if (hasLang) score += 7;
    if (hasAbout) score += 7;

    final social = formSection('social');
    if (platformMetrics.isNotEmpty ||
        contact.trim().isNotEmpty ||
        _hasText(social['handle'])) {
      score += 15;
    }

    final creator = formSection('creator');
    if (_hasList(creator['collab_types'])) score += 5;
    if (_hasList(creator['platforms'])) score += 5;
    if (_hasList(creator['niches']) || niches.isNotEmpty) score += 5;

    final verification = formSection('verification');
    if (_hasText(verification['pan_number']) ||
        _hasText(verification['pan_card']) ||
        _hasText(verification['photo']) ||
        _hasText(verification['voter_id']) ||
        _hasList(verification['other_documents'])) {
      score += 10;
    }

    final videos = formSection('videos');
    if (_hasText(videos['introduction_link']) ||
        _hasText(videos['previous_experience']) ||
        _hasText(videos['other_video_link'])) {
      score += 10;
    }

    return score.clamp(0, 100);
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

  /// Thumbnail URLs aligned by index with [galleryPhotos] when available.
  List<String> get galleryThumbPhotos {
    final full = galleryPhotos;
    if (photoThumbs.isEmpty) return full;
    return [
      for (var i = 0; i < full.length; i++)
        i < photoThumbs.length && photoThumbs[i].isNotEmpty
            ? photoThumbs[i]
            : full[i],
    ];
  }

  String thumbUrlForPhoto(String photoUrl) {
    final index = galleryPhotos.indexOf(photoUrl);
    if (index == -1) return photoUrl;
    if (index < photoThumbs.length && photoThumbs[index].isNotEmpty) {
      return photoThumbs[index];
    }
    return photoUrl;
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    var formData = mapFrom(json['form_data']);
    final videos = Map<String, dynamic>.from(mapFrom(formData['videos']));

    void putIfEmpty(String key, dynamic value) {
      if (_hasText(videos[key])) return;
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) videos[key] = text;
    }

    putIfEmpty(
      'introduction_link',
      json['short_intro_video_link'] ?? json['shortIntroVideoLink'],
    );
    putIfEmpty(
      'previous_experience',
      json['previous_works_video_link'] ?? json['previousWorksVideoLink'],
    );
    putIfEmpty(
      'other_video_link',
      json['achievements_video_link'] ?? json['achievementsVideoLink'],
    );

    if (videos.isNotEmpty) {
      formData = {...formData, 'videos': videos};
    }

    return Profile(
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      profileImage: (json['profile_image'] ?? '').toString(),
      photos: stringList(json['photos']),
      photoThumbs: stringList(json['photo_thumbs']),
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
      formData: formData,
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

  Map<String, dynamic> toJson() {
    final videos = formSection('videos');
    return {
        'user_id': userId,
        'profile_image': profileImage,
        'photos': photos,
        if (photoThumbs.isNotEmpty) 'photo_thumbs': photoThumbs,
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
        'short_intro_video_link':
            (videos['introduction_link'] ?? '').toString(),
        'previous_works_video_link':
            (videos['previous_experience'] ?? '').toString(),
        'achievements_video_link':
            (videos['other_video_link'] ?? '').toString(),
        'profile_completed': profileCompleted,
        'subscription_status': subscriptionStatus.name,
        'account_status': accountStatus.name,
        'free_job_applications_used': freeJobApplicationsUsed,
      };
  }

  Profile copyWith({
    String? profileImage,
    List<String>? photos,
    List<String>? photoThumbs,
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
    bool? profileCompleted,
  }) {
    return Profile(
      userId: userId,
      profileImage: profileImage ?? this.profileImage,
      photos: photos ?? this.photos,
      photoThumbs: photoThumbs ?? this.photoThumbs,
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
      profileCompleted: profileCompleted ?? this.profileCompleted,
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

bool _hasText(dynamic value) => value?.toString().trim().isNotEmpty ?? false;

bool _hasList(dynamic value) {
  if (value is List) {
    return value.any((item) => item.toString().trim().isNotEmpty);
  }
  if (value is String) return value.trim().isNotEmpty;
  return false;
}
