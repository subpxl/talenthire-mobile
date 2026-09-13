import 'package:flutter/material.dart';
import 'package:bombay_casting/features/jobs/models/job_model.dart';

class JobListing {
  const JobListing({
    required this.title,
    required this.details,
    required this.location,
    required this.seenStatus,
    required this.avatarColor,
    required this.imageIndex,
    this.isVerified = false,
    this.imageUrl = '',
    this.jobId = '',
    this.role = '',
    this.collabType = '',
    this.pay = '',
    this.platforms = '',
    this.followersLabel = '',
    this.category = '',
    this.duration = '',
    this.minFollowers = 0,
    this.payMin = 0,
    this.payMax = 0,
    this.company = '',
    this.locationType = LocationType.remote,
    this.gender = '',
    this.age = '',
    this.projectTag = '',
    this.isAudition = false,
    this.description = '',
    this.tags = const [],
    this.postedAt,
    this.applicationDeadline,
  });

  final String title;
  final String details;
  final String location;
  final String seenStatus;
  final Color avatarColor;
  final int imageIndex;
  final bool isVerified;
  final String imageUrl;
  final String jobId;
  final String role;
  final String collabType;
  final String pay;
  final String platforms;
  final String followersLabel;
  final String category;
  final String duration;
  final int minFollowers;
  final int payMin;
  final int payMax;
  final String company;
  final LocationType locationType;
  final String gender;
  final String age;
  final String projectTag;
  final bool isAudition;
  final String description;
  final List<String> tags;
  final DateTime? postedAt;
  final DateTime? applicationDeadline;

  static const _avatarColors = [
    Color(0xFF7986CB),
    Color(0xFF81C784),
    Color(0xFFFFB74D),
    Color(0xFF4DB6AC),
    Color(0xFF9575CD),
  ];

  factory JobListing.fromJob(Job job, int index) {
    return JobListing(
      title: job.title,
      details: job.detailsLine,
      location: job.location.trim().isEmpty
          ? jobWorkTypeLabelFor(job.locationType)
          : job.location,
      seenStatus: 'Posted ${job.timeAgo}',
      avatarColor: _avatarColors[index % _avatarColors.length],
      imageIndex: job.fallbackImageIndex,
      isVerified: job.isVerified,
      imageUrl: job.imageUrl,
      jobId: job.id,
      role: job.roleLabel,
      collabType: job.collabTypeLabel,
      pay: job.payLabel,
      platforms: job.platformsLabel,
      followersLabel: job.followersLabel,
      category: job.nicheLabel,
      duration: job.durationLabel,
      minFollowers: job.minFollowers,
      payMin: job.payMin,
      payMax: job.payMax,
      company: job.company,
      locationType: job.locationType,
      gender: job.gender,
      age: job.age,
      projectTag: job.projectTag,
      isAudition: job.isAudition,
      description: job.description,
      tags: job.tags,
      postedAt: job.postedAt,
      applicationDeadline: job.applicationDeadline,
    );
  }
}

List<JobListing> listingsForJobs(List<Job> jobs, [HomeJobFilter? filter]) {
  final filtered = (filter == null || !filter.isActive)
      ? jobs
      : jobs.where(filter.matchesJob).toList();
  return [
    for (var i = 0; i < filtered.length; i++) JobListing.fromJob(filtered[i], i),
  ];
}

String shortJobCity(String location) {
  final trimmed = location.trim();
  if (trimmed.isEmpty || trimmed.toLowerCase() == 'any') return trimmed;
  final city = trimmed.split(',').first.trim();
  final lower = city.toLowerCase();
  if (lower.contains('delhi')) return 'Delhi';
  if (lower.contains('mumbai') || lower.contains('bombay')) return 'Mumbai';
  if (lower.contains('bengaluru') || lower.contains('bangalore')) {
    return 'Bengaluru';
  }
  if (lower.contains('remote') ||
      lower.contains('nationwide') ||
      lower.contains('virtual') ||
      lower == 'online' ||
      lower == 'open nationwide') {
    return 'Remote';
  }
  return city;
}

bool isRemoteJobCity(String location) {
  final city = shortJobCity(location).toLowerCase();
  return city.isEmpty || city == 'remote' || city == 'any';
}

const _applyWindowDays = 30;
const _shortMonthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

DateTime jobApplyBy(DateTime postedAt, {DateTime? deadline}) {
  return deadline ?? postedAt.add(const Duration(days: _applyWindowDays));
}

String jobApplyByLabel(DateTime postedAt, {DateTime? deadline}) {
  final date = jobApplyBy(postedAt, deadline: deadline).toLocal();
  return '${date.day} ${_shortMonthNames[date.month - 1]}';
}

String jobPayCompactLabel(JobListing job) {
  if (job.payMin > 0 || job.payMax > 0) {
    return _formatCompactPayRange(
      job.payMin > 0 ? job.payMin : job.payMax,
      job.payMax > 0 ? job.payMax : job.payMin,
    );
  }

  final raw = job.pay.trim();
  if (raw.isNotEmpty) {
    final shortLabel = _shortPayFromText(raw);
    if (shortLabel != null) return shortLabel;
  }

  return 'Undisclosed';
}

String? _shortPayFromText(String raw) {
  final lower = raw.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  if (lower == 'barter' || lower.contains('barter')) return 'Barter';
  if (lower == 'unpaid' || lower.contains('unpaid')) return 'Unpaid';
  if (_isUndisclosedPayText(lower)) return 'Undisclosed';

  final amounts = _parsePayAmounts(raw);
  if (amounts.isNotEmpty) {
    if (amounts.length == 1) return _compactRupee(amounts.first);
    return _formatCompactPayRange(amounts.first, amounts.last);
  }

  if (lower.length > 14 || !_looksLikeAmountText(lower)) return 'Undisclosed';
  return raw.length <= 14 ? raw : 'Undisclosed';
}

bool _isUndisclosedPayText(String lower) {
  const patterns = [
    'undisclosed',
    'not specified',
    'negotiable',
    'experience',
    'project-based',
    'project based',
    'campaign-based',
    'campaign based',
    'paid collaboration',
    'paid collab',
    'to be disclosed',
    'based on',
    'tbd',
    'on request',
  ];
  return patterns.any(lower.contains);
}

bool _looksLikeAmountText(String lower) => RegExp(r'\d').hasMatch(lower);

List<int> _parsePayAmounts(String text) {
  final cleaned = text
      .replaceAll('₹', '')
      .replaceAll('\$', '')
      .replaceAll(RegExp(r'\bUSD\b', caseSensitive: false), '')
      .replaceAll(RegExp(r'\bINR\b', caseSensitive: false), '');

  final suffixMatches = RegExp(
    r'(\d+(?:,\d{3})*(?:\.\d+)?)\s*(k|l|cr)\b',
    caseSensitive: false,
  ).allMatches(cleaned);
  if (suffixMatches.isNotEmpty) {
    return suffixMatches
        .map((match) {
          final base = int.tryParse(match.group(1)!.replaceAll(',', '')) ?? 0;
          if (base <= 0) return 0;
          switch (match.group(2)!.toLowerCase()) {
            case 'k':
              return base * 1000;
            case 'l':
              return base * 100000;
            case 'cr':
              return base * 10000000;
            default:
              return base;
          }
        })
        .where((value) => value > 0)
        .toList();
  }

  return RegExp(r'\d[\d,]*')
      .allMatches(cleaned)
      .map((match) => int.tryParse(match.group(0)!.replaceAll(',', '')) ?? 0)
      .where((value) => value > 0)
      .toList();
}

String _formatCompactPayRange(int min, int max) {
  final lo = min <= max ? min : max;
  final hi = max >= min ? max : min;
  if (lo <= 0 && hi <= 0) return 'Undisclosed';
  if (lo == hi || hi <= 0 || lo <= 0) {
    return _compactRupee(lo > 0 ? lo : hi);
  }
  return '${_compactRupee(lo)}–${_compactRupee(hi)}';
}

String _compactRupee(int value) {
  if (value >= 10000000) {
    final crores = value / 10000000;
    return crores == crores.roundToDouble()
        ? '${crores.round()}Cr'
        : '${crores.toStringAsFixed(1)}Cr';
  }
  if (value >= 100000) {
    final lakhs = value / 100000;
    return lakhs == lakhs.roundToDouble()
        ? '${lakhs.round()}L'
        : '${lakhs.toStringAsFixed(1)}L';
  }
  if (value >= 1000) {
    final thousands = value / 1000;
    return thousands == thousands.roundToDouble()
        ? '${thousands.round()}K'
        : '${thousands.toStringAsFixed(1)}K';
  }
  return '$value';
}

String jobGenderLabel(String gender) {
  final value = gender.trim();
  if (value.isEmpty ||
      value.toLowerCase() == 'null' ||
      value.toLowerCase() == 'any') {
    return 'Any';
  }
  if (value.contains('/')) {
    return value
        .split('/')
        .map((part) => _titleCase(part.trim()))
        .where((part) => part.isNotEmpty)
        .join('/');
  }
  return _titleCase(value);
}

String jobArtistTypeLabel(JobListing job) {
  for (final value in [job.role, job.category]) {
    final text = value.trim();
    if (text.isNotEmpty && text.toLowerCase() != 'creator') return text;
  }
  final fromProject = _compactProjectType(job.projectTag);
  if (fromProject != null) return fromProject;
  return 'Talent';
}

String jobWorkTypeLabelFor(LocationType type) {
  return switch (type) {
    LocationType.online => 'Online',
    LocationType.onsite => 'Onsite',
    LocationType.remote => 'Remote',
  };
}

String jobWorkTypeLabel(JobListing job) => jobWorkTypeLabelFor(job.locationType);

String jobAgeLabel(String age) {
  final value = age.trim();
  if (value.isEmpty ||
      value.toLowerCase() == 'null' ||
      value.toLowerCase() == 'any') {
    return 'Any';
  }
  return value.replaceAll(' - ', '–').replaceAll('-', '–');
}

String jobProjectTypeLabel(JobListing job) {
  final fromTag = _compactProjectType(job.projectTag);
  if (fromTag != null) return fromTag;

  final fromPlatforms = _compactProjectType(job.platforms);
  if (fromPlatforms != null) return fromPlatforms;

  final blob = [
    job.title,
    job.category,
    ...job.tags,
  ].join(' ').toLowerCase();

  if (RegExp(r'web\s*-?\s*seri').hasMatch(blob) || blob.contains('webserie')) {
    return 'Webseries';
  }
  if (RegExp(r'\bshort\s*film\b').hasMatch(blob)) return 'Short';
  if (RegExp(r'\b(ad|advert|advertisement|commercial)\b').hasMatch(blob) ||
      blob.contains('ad campaign')) {
    return 'Ad';
  }
  if (RegExp(r'\b(movie|film)\b').hasMatch(blob)) return 'Movie';
  return 'Project';
}

String? _compactProjectType(String raw) {
  final normalized = raw.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '');
  if (normalized.isEmpty) return null;
  if (normalized.contains('webserie') ||
      normalized.contains('webseries') ||
      normalized == 'series') {
    return 'Webseries';
  }
  if (normalized.contains('shortfilm') || normalized == 'short') return 'Short';
  if (normalized.contains('adcampaign') ||
      normalized.contains('advert') ||
      normalized.contains('commercial') ||
      normalized == 'ad') {
    return 'Ad';
  }
  if (normalized.contains('movie') || normalized.contains('film')) {
    return 'Movie';
  }
  return null;
}

String _titleCase(String value) {
  if (value.isEmpty) return value;
  return '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
}

String jobDaysLeftLabel(DateTime postedAt, {DateTime? deadline}) {
  final end = jobApplyBy(postedAt, deadline: deadline).toLocal();
  final now = DateTime.now();
  final remaining = DateTime(end.year, end.month, end.day)
      .difference(DateTime(now.year, now.month, now.day))
      .inDays;
  if (remaining < 0) return 'Closed';
  if (remaining == 0) return 'Last day';
  if (remaining == 1) return '1 day left';
  return '$remaining days left';
}

List<String> postedJobCities(List<Job> jobs) {
  final seen = <String>{};
  final cities = <String>[];
  for (final job in jobs) {
    if (isRemoteJobCity(job.location)) continue;
    final city = shortJobCity(job.location);
    if (seen.add(city.toLowerCase())) cities.add(city);
  }
  return cities;
}

List<String> postedJobCategories(List<Job> jobs, {List<String> fallback = const []}) {
  final seen = <String>{};
  final categories = <String>[];
  for (final job in jobs) {
    final category = job.category.trim();
    if (category.isEmpty) continue;
    if (seen.add(category.toLowerCase())) categories.add(category);
  }
  if (categories.isNotEmpty) return categories;
  return fallback;
}

class HomeJobFilter {
  const HomeJobFilter({
    this.followerStart = 0,
    this.followerEnd = 100,
    this.payStart = 0,
    this.payEnd = 500000,
    this.includeOtherCities = false,
    this.location = 'Any',
    this.jobTypes = const {'Any'},
    this.languages = const {'Any'},
    this.categories = const {'Any'},
    this.gender = 'Any',
    this.ageStart = 0,
    this.ageEnd = 100,
    this.searchQuery = '',
  });

  final double followerStart;
  final double followerEnd;
  final double payStart;
  final double payEnd;
  final bool includeOtherCities;
  final String location;
  final Set<String> jobTypes;
  final Set<String> languages;
  final Set<String> categories;
  final String gender;
  final double ageStart;
  final double ageEnd;
  final String searchQuery;

  bool get hasAdvancedFilters {
    return location != 'Any' ||
        languages.any((item) => item != 'Any') ||
        categories.any((item) => item != 'Any') ||
        gender != 'Any' ||
        ageStart > 0 ||
        ageEnd < 100 ||
        jobTypes.any((item) => item != 'Any') ||
        followerStart > 0 ||
        followerEnd < 100 ||
        payStart > 0 ||
        payEnd < 500000;
  }

  bool get isActive {
    return hasAdvancedFilters ||
        searchQuery.trim().isNotEmpty;
  }

  HomeJobFilter copyWith({
    double? followerStart,
    double? followerEnd,
    double? payStart,
    double? payEnd,
    bool? includeOtherCities,
    String? location,
    Set<String>? jobTypes,
    Set<String>? languages,
    Set<String>? categories,
    String? gender,
    double? ageStart,
    double? ageEnd,
    String? searchQuery,
  }) {
    return HomeJobFilter(
      followerStart: followerStart ?? this.followerStart,
      followerEnd: followerEnd ?? this.followerEnd,
      payStart: payStart ?? this.payStart,
      payEnd: payEnd ?? this.payEnd,
      includeOtherCities: includeOtherCities ?? this.includeOtherCities,
      location: location ?? this.location,
      jobTypes: jobTypes ?? this.jobTypes,
      languages: languages ?? this.languages,
      categories: categories ?? this.categories,
      gender: gender ?? this.gender,
      ageStart: ageStart ?? this.ageStart,
      ageEnd: ageEnd ?? this.ageEnd,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  bool matches(JobListing listing) {
    final haystack =
        '${listing.title} ${listing.details} ${listing.location} ${listing.company} ${listing.role} ${listing.category}'
            .toLowerCase();

    if (!_matchesSearch(haystack)) return false;

    if (location != 'Any' && !includeOtherCities) {
      final wanted = shortJobCity(location).toLowerCase();
      final jobCity = shortJobCity(listing.location).toLowerCase();
      final loc = listing.location.toLowerCase();
      if (wanted.isNotEmpty &&
          jobCity != wanted &&
          !loc.contains(wanted)) {
        return false;
      }
    }

    final types = jobTypes.where((item) => item != 'Any').toList();
    if (types.isNotEmpty) {
      final matched = types.any((type) => haystack.contains(type.toLowerCase()));
      if (!matched) return false;
    }

    final cats = categories.where((item) => item != 'Any').toList();
    if (cats.isNotEmpty) {
      final blob =
          '${listing.role} ${listing.category} ${listing.title} ${listing.details} ${listing.tags.join(' ')}'
              .toLowerCase();
      final matched = cats.any((cat) => blob.contains(cat.toLowerCase()));
      if (!matched) return false;
    }

    if (gender != 'Any') {
      final jobGender = listing.gender.trim().toLowerCase();
      if (jobGender.isNotEmpty &&
          jobGender != 'any' &&
          jobGender != 'all' &&
          !jobGender.contains(gender.toLowerCase())) {
        return false;
      }
    }

    if (!_matchesAgeRange(listing.age)) return false;

    final langs = languages.where((item) => item != 'Any').toList();
    if (langs.isNotEmpty) {
      const allLanguages = [
        'Hindi', 'English', 'Gujarati', 'Marathi', 'Punjabi', 
        'Tamil', 'Telugu', 'Kannada', 'Malayalam', 'Bengali', 'Urdu',
      ];
      final mentionsAnyLanguage = allLanguages.any((item) => haystack.contains(item.toLowerCase()));
      final matched = langs.any((lang) => haystack.contains(lang.toLowerCase()));
      if (mentionsAnyLanguage && !matched) return false;
    }

    if (!_matchesFollowerRange(listing.minFollowers)) return false;
    if (!_matchesPayRange(listing.payMin, listing.payMax)) return false;

    return true;
  }

  bool matchesJob(Job job) {
    return matches(JobListing.fromJob(job, 0));
  }

  bool _matchesSearch(String haystack) {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return true;
    final terms = query
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty);
    return terms.every(haystack.contains);
  }



  bool _matchesFollowerRange(int minFollowers) {
    if (followerStart <= 0 && followerEnd >= 100) return true;
    if (minFollowers <= 0) return followerStart <= 0;
    final requiredK = minFollowers / 1000;
    if (requiredK < followerStart) return false;
    if (followerEnd < 100 && requiredK > followerEnd) return false;
    return true;
  }

  bool _matchesPayRange(int jobPayMin, int jobPayMax) {
    if (payStart <= 0 && payEnd >= 500000) return true;
    final filterMax = payEnd >= 500000 ? 1 << 31 : payEnd;
    return jobPayMax >= payStart && jobPayMin <= filterMax;
  }

  bool _matchesAgeRange(String ageStr) {
    if (ageStart <= 0 && ageEnd >= 100) return true;
    final trimmed = ageStr.trim().toLowerCase();
    if (trimmed.isEmpty || trimmed == 'any' || trimmed == 'all') return true;

    // Parse age like '18-25', '45+', '18'
    int jobAgeMin = 0;
    int jobAgeMax = 100;

    if (trimmed.contains('-')) {
      final parts = trimmed.split('-');
      if (parts.length == 2) {
        jobAgeMin = int.tryParse(parts[0].trim()) ?? 0;
        jobAgeMax = int.tryParse(parts[1].trim()) ?? 100;
      }
    } else if (trimmed.contains('+')) {
      jobAgeMin = int.tryParse(trimmed.replaceAll('+', '').trim()) ?? 0;
      jobAgeMax = 100;
    } else {
      final single = int.tryParse(trimmed);
      if (single != null) {
        jobAgeMin = single;
        jobAgeMax = single;
      }
    }

    // Check for overlap
    return jobAgeMax >= ageStart && jobAgeMin <= ageEnd;
  }
}

const jobListings = [
  JobListing(
    title: 'FTII Casting Call',
    details: 'Paid · Film & TV',
    location: 'Pune, Maharashtra',
    seenStatus: 'Posted 14 min ago',
    avatarColor: Color(0xFF7986CB),
    imageIndex: 1,
    isVerified: true,
  ),
  JobListing(
    title: 'Voice Over · TTS Casting',
    details: 'Remote · Audio & Voice',
    location: 'Open nationwide',
    seenStatus: 'Posted 15 min ago',
    avatarColor: Color(0xFF81C784),
    imageIndex: 2,
    isVerified: true,
  ),
  JobListing(
    title: 'Brand Reel Collab',
    details: 'Barter + product · Instagram',
    location: 'Mumbai, Maharashtra',
    seenStatus: 'Posted 1 hr ago',
    avatarColor: Color(0xFFFFB74D),
    imageIndex: 3,
  ),
  JobListing(
    title: 'YouTube Host Audition',
    details: 'Paid · Lifestyle',
    location: 'Bengaluru, Karnataka',
    seenStatus: 'Posted 1 hr ago',
    avatarColor: Color(0xFF4DB6AC),
    imageIndex: 4,
  ),
  JobListing(
    title: 'Product Review Campaign',
    details: 'Paid · Beauty',
    location: 'Delhi NCR',
    seenStatus: 'Posted 1 hr ago',
    avatarColor: Color(0xFF9575CD),
    imageIndex: 5,
  ),
  JobListing(
    title: 'Fashion Lookbook Shoot',
    details: 'Paid · Fashion',
    location: 'Jaipur, Rajasthan',
    seenStatus: 'Posted 8 days ago',
    avatarColor: Color(0xFF7986CB),
    imageIndex: 6,
  ),
  JobListing(
    title: 'Food Creator Tasting',
    details: 'Barter · Food & Travel',
    location: 'Hyderabad, Telangana',
    seenStatus: 'Posted 8 days ago',
    avatarColor: Color(0xFF81C784),
    imageIndex: 7,
  ),
  JobListing(
    title: 'Tech Unboxing Series',
    details: 'Paid · Gadgets',
    location: 'Pune, Maharashtra',
    seenStatus: 'Posted 8 days ago',
    avatarColor: Color(0xFFFFB74D),
    imageIndex: 8,
  ),
  JobListing(
    title: 'Festival Campaign Shoot',
    details: 'Paid · Lifestyle',
    location: 'Ahmedabad, Gujarat',
    seenStatus: 'Posted 8 days ago',
    avatarColor: Color(0xFF4DB6AC),
    imageIndex: 9,
  ),
];
