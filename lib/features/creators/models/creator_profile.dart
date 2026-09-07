import 'package:bombay_casting/core/models/models.dart';

class CreatorPhoto {
  const CreatorPhoto({
    this.url = '',
    this.thumbUrl = '',
    this.imageIndex = 1,
  });

  final String url;
  final String thumbUrl;
  final int imageIndex;

  factory CreatorPhoto.fromJson(Map<String, dynamic> json) {
    return CreatorPhoto(
      url: (json['url'] ?? '').toString(),
      thumbUrl: (json['thumb_url'] ?? json['thumbUrl'] ?? '').toString(),
      imageIndex: (json['image_index'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        if (thumbUrl.isNotEmpty) 'thumb_url': thumbUrl,
        'image_index': imageIndex,
      };
}

class CreatorProfile {
  const CreatorProfile({
    required this.id,
    required this.name,
    required this.title,
    required this.location,
    required this.photos,
    this.isVerified = false,
    this.isPremium = false,
    this.aboutInfo = const [],
    this.workInfo = const [],
    this.platformMetrics = const [],
    this.collabTypes = const [],
    this.contentTypes = const [],
    this.bio = '',
    this.videoLinks = const [],
    this.createdAt,
    this.savedAt,
  });

  final String id;
  final String name;
  final String title;
  final String location;
  final List<CreatorPhoto> photos;
  final List<String> videoLinks;
  final bool isVerified;
  final bool isPremium;
  final List<MapEntry<String, String>> aboutInfo;
  final List<MapEntry<String, String>> workInfo;
  final List<SocialPlatformMetric> platformMetrics;
  final List<String> collabTypes;
  final List<String> contentTypes;
  final String bio;
  final DateTime? createdAt;
  final DateTime? savedAt;

  CreatorPhoto get cover =>
      photos.isNotEmpty ? photos.first : const CreatorPhoto();

  bool matchesSearch(String query) {
    final terms = query
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty);
    if (terms.isEmpty) return true;
    final haystack = [
      name,
      title,
      location,
      bio,
      for (final entry in aboutInfo) '${entry.key} ${entry.value}',
      for (final entry in workInfo) '${entry.key} ${entry.value}',
      ...collabTypes,
      ...contentTypes,
    ].join(' ').toLowerCase();
    return terms.every(haystack.contains);
  }

  bool matchesTalent(String talent) {
    if (talent == 'All' || talent.trim().isEmpty) return true;
    final needle = talent.toLowerCase();
    if (title.toLowerCase().contains(needle)) return true;
    return workInfo.any(
      (entry) => entry.value.toLowerCase().contains(needle),
    );
  }

  factory CreatorProfile.fromRecords({
    required User user,
    required Profile profile,
    required int fallbackIndex,
  }) {
    final location = [
      profile.city,
      profile.state,
    ].where((item) => item.isNotEmpty).join(', ');
    final role = _filledValue(profile.formValue('work', 'role', ''));
    final talent = profile.talent.trim();
    final title = role.isNotEmpty
        ? role
        : (talent.isNotEmpty && talent.toLowerCase() != 'influencer'
            ? talent
            : '');
    final gender = _filledValue(
      profile.gender.isNotEmpty
          ? profile.gender
          : profile.formValue('personal', 'gender', ''),
    );
    final ageText = profile.age != null
        ? '${profile.age}'
        : _filledValue(profile.formValue('personal', 'age', ''));
    final languages = profile.languages.isNotEmpty
        ? profile.languages.join(', ')
        : _filledValue(profile.formValue('personal', 'language', ''));
    final niches = profile.niches.isNotEmpty
        ? profile.niches.take(3).join(', ')
        : _filledValue(profile.formValue('content', 'niches', ''));
    final lookingFor = _filledValue(
      profile.formValue('personal', 'looking_for', ''),
    );
    final collabTypes = _formList(profile, 'collab_types');
    final contentTypes = _formList(profile, 'content_types');
    final bio = _filledValue(profile.bio).isNotEmpty
        ? profile.bio.trim()
        : _filledValue(profile.formValue('personal', 'about', ''));
    final gallery = profile.galleryPhotos;
    final thumbGallery = profile.galleryThumbPhotos;
    final photos = List<CreatorPhoto>.generate(
      gallery.isEmpty ? 1 : gallery.length.clamp(1, Profile.maxPhotos),
      (index) {
        return CreatorPhoto(
          url: index < gallery.length ? gallery[index] : '',
          thumbUrl: index < thumbGallery.length ? thumbGallery[index] : '',
          imageIndex: fallbackIndex + index,
        );
      },
    );
    return CreatorProfile(
      id: user.id.isNotEmpty ? user.id : profile.userId,
      name: user.name.trim().isEmpty ? 'Creator' : user.name.trim(),
      title: title,
      location: location,
      photos: photos,
      videoLinks: _videoLinksFromProfile(profile),
      isVerified: profile.isVerified || profile.isPremium,
      isPremium: profile.isPremium,
      bio: bio,
      aboutInfo: [
        if (gender.isNotEmpty) MapEntry('Gender', gender),
        if (ageText.isNotEmpty) MapEntry('Age', ageText),
        if (languages.isNotEmpty) MapEntry('Languages', languages),
      ],
      workInfo: [
        if (title.isNotEmpty) MapEntry('Role', title),
        if (niches.isNotEmpty) MapEntry('Niches', niches),
        if (lookingFor.isNotEmpty) MapEntry('Open to', lookingFor),
      ],
      platformMetrics: profile.platformMetrics,
      collabTypes: collabTypes,
      contentTypes: contentTypes,
      createdAt: user.createdAt,
    );
  }

  /// Builds a feed card from denormalized [feedCard] on the user document.
  /// Returns null when the user should be hidden from the feed.
  static CreatorProfile? fromFeedCard({
    required Map<String, dynamic> userData,
    required String userId,
    required Map<String, dynamic> feedCard,
    required int fallbackIndex,
    String? currentUserId,
  }) {
    final data = Map<String, dynamic>.from(userData);
    data['id'] = data['id']?.toString().isNotEmpty == true ? data['id'] : userId;
    final user = User.fromJson(data);
    final isCurrentUser = userId == currentUserId;
    if (!isCurrentUser && !user.isActive) return null;

    final city = (feedCard['city'] ?? '').toString();
    final gallery = _galleryFromFeedCard(feedCard);
    if (!isCurrentUser &&
        user.name.trim().isEmpty &&
        gallery.isEmpty &&
        city.isEmpty) {
      return null;
    }

    final state = (feedCard['state'] ?? '').toString();
    final location = [city, state].where((item) => item.isNotEmpty).join(', ');
    final role = _filledValue((feedCard['role'] ?? '').toString());
    final talent = (feedCard['talent'] ?? '').toString().trim();
    final title = role.isNotEmpty
        ? role
        : (talent.isNotEmpty && talent.toLowerCase() != 'influencer'
            ? talent
            : '');
    final gender = _filledValue((feedCard['gender'] ?? '').toString());
    final ageRaw = feedCard['age'];
    final ageText = ageRaw is num
        ? '${ageRaw.toInt()}'
        : _filledValue((feedCard['age'] ?? '').toString());
    final languages = stringList(feedCard['languages']).join(', ');
    final niches = stringList(feedCard['niches']).take(3).join(', ');
    final lookingFor = _filledValue((feedCard['looking_for'] ?? '').toString());
    final collabTypes = stringList(feedCard['collab_types']);
    final contentTypes = stringList(feedCard['content_types']);
    final bio = _filledValue((feedCard['bio'] ?? '').toString());
    final subscriptionStatus =
        (feedCard['subscription_status'] ?? 'free').toString();
    final isPremium = subscriptionStatus == 'premium';
    final isVerified = feedCard['is_verified'] == true || isPremium;

    final metricsRaw = feedCard['platform_metrics'];
    final metrics = <SocialPlatformMetric>[];
    if (metricsRaw is List) {
      for (final item in metricsRaw) {
        if (item is Map) {
          metrics.add(
            SocialPlatformMetric.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    final photos = List<CreatorPhoto>.generate(
      gallery.isEmpty ? 1 : gallery.length.clamp(1, Profile.maxPhotos),
      (index) {
        final thumbs = stringList(feedCard['photo_thumbs']);
        return CreatorPhoto(
          url: index < gallery.length ? gallery[index] : '',
          thumbUrl: index < thumbs.length ? thumbs[index] : '',
          imageIndex: fallbackIndex + index,
        );
      },
    );

    return CreatorProfile(
      id: user.id.isNotEmpty ? user.id : userId,
      name: user.name.trim().isEmpty ? 'Creator' : user.name.trim(),
      title: title,
      location: location,
      photos: photos,
      videoLinks: stringList(feedCard['video_links']),
      isVerified: isVerified,
      isPremium: isPremium,
      bio: bio,
      aboutInfo: [
        if (gender.isNotEmpty) MapEntry('Gender', gender),
        if (ageText.isNotEmpty) MapEntry('Age', ageText),
        if (languages.isNotEmpty) MapEntry('Languages', languages),
      ],
      workInfo: [
        if (title.isNotEmpty) MapEntry('Role', title),
        if (niches.isNotEmpty) MapEntry('Niches', niches),
        if (lookingFor.isNotEmpty) MapEntry('Open to', lookingFor),
      ],
      platformMetrics: metrics,
      collabTypes: collabTypes,
      contentTypes: contentTypes,
      createdAt: user.createdAt,
    );
  }

  factory CreatorProfile.fromJson(Map<String, dynamic> json) {
    final photosRaw = json['photos'];
    final photos = <CreatorPhoto>[];
    if (photosRaw is List) {
      for (final item in photosRaw) {
        if (item is Map) {
          photos.add(CreatorPhoto.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    final metricsRaw = json['platform_metrics'];
    final metrics = <SocialPlatformMetric>[];
    if (metricsRaw is List) {
      for (final item in metricsRaw) {
        if (item is Map) {
          metrics.add(
            SocialPlatformMetric.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return CreatorProfile(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Creator').toString(),
      title: (json['title'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      photos: photos.isEmpty ? const [CreatorPhoto()] : photos,
      isVerified: json['is_verified'] == true || json['is_premium'] == true,
      isPremium: json['is_premium'] == true,
      aboutInfo: _entriesFromJson(json['about_info']),
      workInfo: _entriesFromJson(json['work_info']),
      platformMetrics: metrics,
      collabTypes: stringList(json['collab_types'] ?? json['collabTypes']),
      contentTypes: stringList(json['content_types'] ?? json['contentTypes']),
      bio: (json['bio'] ?? json['about'] ?? '').toString(),
      videoLinks: stringList(json['video_links'] ?? json['videoLinks']),
      createdAt: parseFlexibleDate(json['created_at']),
      savedAt: parseFlexibleDate(json['saved_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'title': title,
        'location': location,
        'photos': photos.map((photo) => photo.toJson()).toList(),
        'is_verified': isVerified,
        'is_premium': isPremium,
        'about_info': _entriesToJson(aboutInfo),
        'work_info': _entriesToJson(workInfo),
        'platform_metrics':
            platformMetrics.map((metric) => metric.toJson()).toList(),
        if (collabTypes.isNotEmpty) 'collab_types': collabTypes,
        if (contentTypes.isNotEmpty) 'content_types': contentTypes,
        if (bio.isNotEmpty) 'bio': bio,
        if (videoLinks.isNotEmpty) 'video_links': videoLinks,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (savedAt != null) 'saved_at': savedAt!.toIso8601String(),
      };
}

List<String> _galleryFromFeedCard(Map<String, dynamic> feedCard) {
  final urls = <String>[];
  final main = (feedCard['profile_image'] ?? '').toString();
  if (main.isNotEmpty) urls.add(main);
  for (final photo in stringList(feedCard['photos'])) {
    if (photo.isNotEmpty && !urls.contains(photo)) urls.add(photo);
  }
  return urls.take(Profile.maxPhotos).toList();
}

List<String> _videoLinksFromProfile(Profile profile) {
  final videos = profile.formSection('videos');
  return [
    videos['introduction_link'],
    videos['previous_experience'],
    videos['other_video_link'],
  ]
      .map((value) => (value ?? '').toString().trim())
      .where((value) => value.isNotEmpty)
      .toList();
}

String _filledValue(String value) {
  final text = value.trim();
  if (text.isEmpty || text == '-') return '';
  return text;
}

List<String> _formList(Profile profile, String key) {
  final fromCreator = _valuesList(profile.formSection('creator')[key]);
  if (fromCreator.isNotEmpty) return fromCreator;
  return _valuesList(profile.formSection('content')[key]);
}

List<String> _valuesList(dynamic stored) {
  return stringList(stored)
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty && item != 'Any' && item != '-')
      .toList();
}

List<Map<String, String>> _entriesToJson(List<MapEntry<String, String>> entries) {
  return [
    for (final entry in entries) {'key': entry.key, 'value': entry.value},
  ];
}

List<MapEntry<String, String>> _entriesFromJson(dynamic value) {
  if (value is! List) return const [];
  return [
    for (final item in value)
      if (item is Map)
        MapEntry(
          (item['key'] ?? '').toString(),
          (item['value'] ?? '').toString(),
        ),
  ];
}

class CreatorFilter {
  const CreatorFilter({
    this.genders = const {'Any'},
    this.ageStart = 0,
    this.ageEnd = 100,
    this.categories = const {'Any'},
    this.location = 'Any',
  });

  final Set<String> genders;
  final double ageStart;
  final double ageEnd;
  final Set<String> categories;
  final String location;

  bool get isActive =>
      genders.any((g) => g != 'Any') ||
      ageStart > 0 ||
      ageEnd < 100 ||
      categories.any((c) => c != 'Any') ||
      location != 'Any';

  CreatorFilter copyWith({
    Set<String>? genders,
    double? ageStart,
    double? ageEnd,
    Set<String>? categories,
    String? location,
  }) {
    return CreatorFilter(
      genders: genders ?? this.genders,
      ageStart: ageStart ?? this.ageStart,
      ageEnd: ageEnd ?? this.ageEnd,
      categories: categories ?? this.categories,
      location: location ?? this.location,
    );
  }

  bool matches(CreatorProfile creator) {
    if (location != 'Any') {
      final loc = creator.location.toLowerCase();
      final city = location.split(',').first.trim().toLowerCase();
      if (!loc.contains(city)) return false;
    }

    final cats = categories.where((c) => c != 'Any').toList();
    if (cats.isNotEmpty) {
      final matched = cats.any((c) => creator.matchesTalent(c));
      if (!matched) return false;
    }

    final gens = genders.where((g) => g != 'Any').toList();
    if (gens.isNotEmpty) {
      final genderEntry = creator.aboutInfo.where((e) => e.key == 'Gender').toList();
      if (genderEntry.isEmpty) return false;
      final matched = gens.any((g) => genderEntry.first.value.toLowerCase() == g.toLowerCase());
      if (!matched) return false;
    }

    if (ageStart > 0 || ageEnd < 100) {
      final ageEntry = creator.aboutInfo.where((e) => e.key == 'Age').toList();
      if (ageEntry.isEmpty) return false;
      final age = int.tryParse(ageEntry.first.value) ?? 0;
      if (age < ageStart || age > ageEnd) return false;
    }

    return true;
  }
}
