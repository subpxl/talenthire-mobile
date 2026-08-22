enum UserRole { influencer }

enum AccountStatus { active, inactive, suspended }

enum SubscriptionStatus { free, premium, expired }

enum LocationType { remote, online, onsite }

enum JobStatus { draft, published, closed, cancelled }

enum ApplicationStatus {
  applied,
  shortlisted,
  interview,
  selected,
  rejected,
  withdrawn,
}

T _enumFromString<T extends Enum>(List<T> values, String value, T fallback) {
  return values.firstWhere(
    (item) => item.name == value,
    orElse: () => fallback,
  );
}

JobStatus jobStatusFromString(String value) {
  if (value == 'open') return JobStatus.published;
  return _enumFromString(JobStatus.values, value, JobStatus.draft);
}

LocationType locationTypeFromString(String value) {
  return _enumFromString(LocationType.values, value, LocationType.remote);
}

DateTime? parseFlexibleDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  try {
    if (value is Object && value.runtimeType.toString() == 'Timestamp') {
      return (value as dynamic).toDate() as DateTime;
    }
    if (value is Map && value['seconds'] != null) {
      return DateTime.fromMillisecondsSinceEpoch(
        (value['seconds'] as num).toInt() * 1000,
      );
    }
  } catch (_) {}
  return DateTime.tryParse(value.toString());
}

Map<String, dynamic> _mapFrom(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return {};
}

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  return const [];
}

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
}

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
      role: _enumFromString(
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
      photos: _stringList(json['photos']),
      isVerified: json['is_verified'] == true,
      talent: (json['talent'] ?? 'influencer').toString(),
      bio: (json['bio'] ?? '').toString(),
      contact: (json['contact'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      state: (json['state'] ?? '').toString(),
      age: (json['age'] as num?)?.toInt(),
      gender: (json['gender'] ?? '').toString(),
      height: json['height']?.toString(),
      languages: _stringList(json['languages']),
      niches: _stringList(json['niches']),
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
      formData: _mapFrom(json['form_data']),
      profileCompleted: json['profile_completed'] == true,
      subscriptionStatus: _enumFromString(
        SubscriptionStatus.values,
        (json['subscription_status'] ?? 'free').toString(),
        SubscriptionStatus.free,
      ),
      accountStatus: _enumFromString(
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

  Map<String, dynamic> formSection(String key) => _mapFrom(formData[key]);

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

class Job {
  Job({
    required this.id,
    required this.title,
    this.summary = '',
    this.description = '',
    this.company = '',
    this.locationType = LocationType.remote,
    this.location = '',
    this.status = JobStatus.published,
    DateTime? postedAt,
    this.createdBy = '',
    this.salary = '',
    List<String>? tags,
    this.imageUrl = '',
    this.imagePath = '',
    this.category = '',
    List<String>? platforms,
    this.collaborationType = '',
    this.compensation = '',
    List<String>? deliverables,
    this.isVerified = false,
    this.sourceImage = '',
    this.applied = 0,
    this.minFollowers = 0,
    this.payMin = 0,
    this.payMax = 0,
  })  : postedAt = postedAt ?? DateTime.now(),
        tags = tags ?? [],
        platforms = platforms ?? [],
        deliverables = deliverables ?? [];

  final String id;
  final String title;
  final String summary;
  final String description;
  final String company;
  final LocationType locationType;
  final String location;
  final JobStatus status;
  final DateTime postedAt;
  final String createdBy;
  final String salary;
  final List<String> tags;
  final String imageUrl;
  final String imagePath;
  final String category;
  final List<String> platforms;
  final String collaborationType;
  final String compensation;
  final List<String> deliverables;
  final bool isVerified;
  final String sourceImage;
  final int applied;
  final int minFollowers;
  final int payMin;
  final int payMax;

  String get timeAgo {
    final diff = DateTime.now().difference(postedAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${(diff.inDays / 7).floor()} weeks ago';
  }

  String get collabTypeLabel {
    switch (collaborationType.trim().toLowerCase()) {
      case 'paid':
        return 'Paid collab';
      case 'barter':
        return 'Barter';
      case 'audition':
        return 'Audition';
      case 'unpaid':
        return 'Unpaid';
      case 'community':
        return 'Community';
      case 'affiliate':
        return 'Affiliate';
      default:
        if (collaborationType.trim().isNotEmpty) return collaborationType;
        if (compensation.isNotEmpty) return compensation;
        return salary;
    }
  }

  String get roleLabel =>
      category.trim().isNotEmpty ? category.trim() : 'Creator';

  String get payLabel {
    if (compensation.trim().isNotEmpty) return compensation.trim();
    if (salary.trim().isNotEmpty) return salary.trim();
    if (payMin > 0 || payMax > 0) return _formatPayRange(payMin, payMax);
    return 'Not specified';
  }

  String get platformsLabel => platforms
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .join(', ');

  String get nicheLabel {
    final skip = {
      category.toLowerCase(),
      collaborationType.toLowerCase(),
      'paid',
      'audition',
      'barter',
      'unpaid',
      'community',
      'affiliate',
    };
    final niche = tags
        .map((item) => item.trim())
        .where(
          (item) => item.isNotEmpty && !skip.contains(item.toLowerCase()),
        )
        .toList();
    if (niche.isNotEmpty) return niche.join(', ');
    if (platformsLabel.isNotEmpty) return platformsLabel;
    return roleLabel;
  }

  String get durationLabel => deliverables.isNotEmpty
      ? deliverables.join(', ')
      : 'Campaign based';

  String get followersLabel {
    if (minFollowers <= 0) return 'Open to creators';
    return '${_formatFollowerCount(minFollowers)}+ preferred';
  }

  String get detailsLine {
    final collab = collabTypeLabel;
    final niche = category.isNotEmpty
        ? category
        : (platforms.isNotEmpty ? platforms.first : '');
    if (collab.isEmpty) return niche;
    if (niche.isEmpty) return collab;
    return '$collab · $niche';
  }

  int get fallbackImageIndex {
    final match = RegExp(r'\((\d+)\)').firstMatch(sourceImage);
    if (match != null) return int.parse(match.group(1)!);
    return (id.hashCode.abs() % 66) + 1;
  }

  factory Job.fromJson(Map<String, dynamic> json) {
    final category = (json['category'] ?? '').toString();
    final collaborationType = (json['collaboration_type'] ?? '').toString();
    final salary = (json['salary'] ?? '').toString();
    final compensation = (json['compensation'] ?? json['salary'] ?? '').toString();
    final pay = _jobPayRange(
      json,
      collaborationType: collaborationType,
      compensation: compensation,
      salary: salary,
    );
    return Job(
      id: json['id']?.toString() ?? '',
      title: (json['title'] ?? '').toString(),
      summary: (json['summary'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      company: (json['company'] ?? '').toString(),
      locationType: locationTypeFromString(
        (json['location_type'] ?? 'remote').toString(),
      ),
      location: (json['location'] ?? '').toString(),
      status: jobStatusFromString((json['status'] ?? 'published').toString()),
      postedAt: parseFlexibleDate(json['posted_at']) ??
          parseFlexibleDate(json['created_at']) ??
          DateTime.now(),
      createdBy: (json['created_by'] ?? json['agencyId'] ?? '').toString(),
      salary: salary,
      tags: _stringList(json['tags']),
      imageUrl: (json['image_url'] ?? '').toString(),
      imagePath: (json['image_path'] ?? '').toString(),
      category: category,
      platforms: _stringList(json['platforms']),
      collaborationType: collaborationType,
      compensation: compensation,
      deliverables: _stringList(json['deliverables']),
      isVerified: json['is_verified'] == true,
      sourceImage: (json['source_image'] ?? '').toString(),
      applied: (json['applied'] as num?)?.toInt() ?? 0,
      minFollowers: _jobMinFollowers(json, category),
      payMin: pay.$1,
      payMax: pay.$2,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'summary': summary,
        'description': description,
        'company': company,
        'location_type': locationType.name,
        'location': location,
        'status': status.name,
        'posted_at': postedAt.toIso8601String(),
        'created_by': createdBy,
        'salary': salary,
        'tags': tags,
        'image_url': imageUrl,
        'image_path': imagePath,
        'category': category,
        'platforms': platforms,
        'collaboration_type': collaborationType,
        'compensation': compensation,
        'deliverables': deliverables,
        'is_verified': isVerified,
        'source_image': sourceImage,
        'applied': applied,
        'min_followers': minFollowers,
        'pay_min': payMin,
        'pay_max': payMax,
      };
}

int _positiveInt(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) {
    final compact = value.trim().toLowerCase().replaceAll(',', '');
    if (compact.isEmpty) return 0;
    final multiplier = compact.endsWith('m')
        ? 1000000
        : compact.endsWith('k')
            ? 1000
            : 1;
    final number = double.tryParse(
      compact.replaceAll(RegExp(r'[^\d.]'), ''),
    );
    if (number == null) return 0;
    return (number * multiplier).round();
  }
  return 0;
}

int _jobMinFollowers(Map<String, dynamic> json, String category) {
  for (final key in ['min_followers', 'followers_required', 'followers']) {
    final parsed = _positiveInt(json[key]);
    if (parsed > 0) return parsed;
  }
  switch (category.trim().toLowerCase()) {
    case 'influencer':
      return 10000;
    case 'model':
      return 5000;
    default:
      return 0;
  }
}

(int, int) _jobPayRange(
  Map<String, dynamic> json, {
  required String collaborationType,
  required String compensation,
  required String salary,
}) {
  final explicitMin = _positiveInt(
    json['pay_min'] ?? json['salary_min'] ?? json['min_pay'],
  );
  final explicitMax = _positiveInt(
    json['pay_max'] ?? json['salary_max'] ?? json['max_pay'],
  );
  if (explicitMin > 0 || explicitMax > 0) {
    final max = explicitMax > 0 ? explicitMax : explicitMin;
    final min = explicitMin > 0 ? explicitMin : max;
    return (min, max < min ? min : max);
  }

  final parsed = _rupeeAmounts('$compensation $salary');
  if (parsed.length >= 2) return (parsed.first, parsed.last);
  if (parsed.length == 1) return (parsed.first, parsed.first);

  switch (collaborationType.trim().toLowerCase()) {
    case 'paid':
      return (15000, 40000);
    default:
      return (0, 0);
  }
}

List<int> _rupeeAmounts(String text) {
  return RegExp(r'₹\s*([\d,]+)')
      .allMatches(text)
      .map((match) => int.tryParse(match.group(1)!.replaceAll(',', '')) ?? 0)
      .where((value) => value > 0)
      .toList();
}

String _formatFollowerCount(int count) {
  if (count >= 1000000) {
    final millions = count / 1000000;
    return millions == millions.roundToDouble()
        ? '${millions.round()}M'
        : '${millions.toStringAsFixed(1)}M';
  }
  if (count >= 1000) {
    final thousands = count / 1000;
    return thousands == thousands.roundToDouble()
        ? '${thousands.round()}K'
        : '${thousands.toStringAsFixed(1)}K';
  }
  return '$count';
}

String _formatPayRange(int min, int max) {
  if (min <= 0 && max <= 0) return 'Not specified';
  if (min == max || max <= 0) return '₹ ${_formatRupee(min)}';
  return '₹ ${_formatRupee(min)} - ₹ ${_formatRupee(max)}';
}

String _formatRupee(int value) {
  final digits = value.toString();
  if (digits.length <= 3) return digits;
  final lastThree = digits.substring(digits.length - 3);
  final rest = digits.substring(0, digits.length - 3);
  final withCommas = rest.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{2})+(?!\d))'),
    (match) => '${match[1]},',
  );
  return '$withCommas,$lastThree';
}

class Application {
  Application({
    required this.id,
    this.userId = '',
    this.jobId = '',
    required this.jobTitle,
    this.company = '',
    this.status = ApplicationStatus.applied,
    DateTime? appliedAt,
  }) : appliedAt = appliedAt ?? DateTime.now();

  final String id;
  final String userId;
  final String jobId;
  final String jobTitle;
  final String company;
  final ApplicationStatus status;
  final DateTime appliedAt;

  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      id: json['id']?.toString() ?? '',
      userId: (json['user_id'] ?? '').toString(),
      jobId: (json['job_id'] ?? '').toString(),
      jobTitle: (json['job_title'] ?? '').toString(),
      company: (json['company'] ?? '').toString(),
      status: _enumFromString(
        ApplicationStatus.values,
        (json['status'] ?? 'applied').toString(),
        ApplicationStatus.applied,
      ),
      appliedAt: parseFlexibleDate(json['applied_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'job_id': jobId,
        'job_title': jobTitle,
        'company': company,
        'status': status.name,
        'applied_at': appliedAt.toIso8601String(),
      };
}
