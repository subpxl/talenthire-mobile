import 'package:bombay_casting/core/models/models.dart';

class CreatorPhoto {
  const CreatorPhoto({
    this.url = '',
    this.imageIndex = 1,
  });

  final String url;
  final int imageIndex;

  factory CreatorPhoto.fromJson(Map<String, dynamic> json) {
    return CreatorPhoto(
      url: (json['url'] ?? '').toString(),
      imageIndex: (json['image_index'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'url': url,
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
    this.bio = '',
    this.createdAt,
    this.savedAt,
  });

  final String id;
  final String name;
  final String title;
  final String location;
  final List<CreatorPhoto> photos;
  final bool isVerified;
  final bool isPremium;
  final List<MapEntry<String, String>> aboutInfo;
  final List<MapEntry<String, String>> workInfo;
  final List<SocialPlatformMetric> platformMetrics;
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
    final bio = _filledValue(profile.bio).isNotEmpty
        ? profile.bio.trim()
        : _filledValue(profile.formValue('personal', 'about', ''));
    final gallery = profile.galleryPhotos;
    final photos = List<CreatorPhoto>.generate(
      gallery.isEmpty ? 1 : gallery.length.clamp(1, Profile.maxPhotos),
      (index) {
        return CreatorPhoto(
          url: index < gallery.length ? gallery[index] : '',
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
      bio: (json['bio'] ?? json['about'] ?? '').toString(),
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
        if (bio.isNotEmpty) 'bio': bio,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (savedAt != null) 'saved_at': savedAt!.toIso8601String(),
      };
}

String _filledValue(String value) {
  final text = value.trim();
  if (text.isEmpty || text == '-') return '';
  return text;
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
