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
    this.aboutInfo = const [],
    this.workInfo = const [],
    this.platformMetrics = const [],
    this.createdAt,
    this.savedAt,
  });

  final String id;
  final String name;
  final String title;
  final String location;
  final List<CreatorPhoto> photos;
  final bool isVerified;
  final List<MapEntry<String, String>> aboutInfo;
  final List<MapEntry<String, String>> workInfo;
  final List<SocialPlatformMetric> platformMetrics;
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
    final title = profile.formValue('work', 'role', '').trim().isNotEmpty
        ? profile.formValue('work', 'role')
        : (profile.talent.isNotEmpty ? profile.talent : 'Creator');
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
      location: location.isEmpty ? 'India' : location,
      photos: photos,
      isVerified: profile.isVerified,
      aboutInfo: [
        if (profile.gender.isNotEmpty) MapEntry('Gender', profile.gender),
        if (profile.age != null) MapEntry('Age', '${profile.age}'),
        if (profile.languages.isNotEmpty)
          MapEntry('Languages', profile.languages.join(', ')),
        MapEntry(
          'Content language',
          profile.formValue('personal', 'language', 'Hindi'),
        ),
      ],
      workInfo: [
        MapEntry('Role', title),
        if (profile.niches.isNotEmpty)
          MapEntry('Niches', profile.niches.take(3).join(', ')),
        MapEntry(
          'Experience',
          profile.formValue('work', 'experience', 'Growing (1-3 yrs)'),
        ),
        MapEntry(
          'Open to',
          profile.formValue('personal', 'looking_for', 'Brand deals'),
        ),
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
      isVerified: json['is_verified'] == true,
      aboutInfo: _entriesFromJson(json['about_info']),
      workInfo: _entriesFromJson(json['work_info']),
      platformMetrics: metrics,
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
        'about_info': _entriesToJson(aboutInfo),
        'work_info': _entriesToJson(workInfo),
        'platform_metrics':
            platformMetrics.map((metric) => metric.toJson()).toList(),
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (savedAt != null) 'saved_at': savedAt!.toIso8601String(),
      };
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
