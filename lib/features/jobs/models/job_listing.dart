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
      location: job.location.isEmpty ? 'Remote' : job.location,
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

class HomeJobFilter {
  const HomeJobFilter({
    this.followerStart = 0,
    this.followerEnd = 100,
    this.payStart = 0,
    this.payEnd = 500000,
    this.includeOtherCities = false,
    this.location = 'Any',
    this.jobTypes = const {'Any'},
    this.language = 'Any',
    this.category = 'Any',
    this.searchQuery = '',
    this.workMode = 'All',
  });

  static const workModes = ['All', 'Remote', 'Online', 'Onsite'];

  final double followerStart;
  final double followerEnd;
  final double payStart;
  final double payEnd;
  final bool includeOtherCities;
  final String location;
  final Set<String> jobTypes;
  final String language;
  final String category;
  final String searchQuery;
  final String workMode;

  bool get hasAdvancedFilters {
    return location != 'Any' ||
        language != 'Any' ||
        category != 'Any' ||
        jobTypes.any((item) => item != 'Any') ||
        followerStart > 0 ||
        followerEnd < 100 ||
        payStart > 0 ||
        payEnd < 500000;
  }

  bool get isActive {
    return hasAdvancedFilters ||
        searchQuery.trim().isNotEmpty ||
        workMode != 'All';
  }

  HomeJobFilter copyWith({
    double? followerStart,
    double? followerEnd,
    double? payStart,
    double? payEnd,
    bool? includeOtherCities,
    String? location,
    Set<String>? jobTypes,
    String? language,
    String? category,
    String? searchQuery,
    String? workMode,
  }) {
    return HomeJobFilter(
      followerStart: followerStart ?? this.followerStart,
      followerEnd: followerEnd ?? this.followerEnd,
      payStart: payStart ?? this.payStart,
      payEnd: payEnd ?? this.payEnd,
      includeOtherCities: includeOtherCities ?? this.includeOtherCities,
      location: location ?? this.location,
      jobTypes: jobTypes ?? this.jobTypes,
      language: language ?? this.language,
      category: category ?? this.category,
      searchQuery: searchQuery ?? this.searchQuery,
      workMode: workMode ?? this.workMode,
    );
  }

  bool matches(JobListing listing) {
    final haystack =
        '${listing.title} ${listing.details} ${listing.location} ${listing.company} ${listing.role} ${listing.category}'
            .toLowerCase();

    if (!_matchesSearch(haystack)) return false;
    if (!_matchesWorkMode(listing)) return false;

    if (location != 'Any' && !includeOtherCities) {
      final city = location.split(',').first.trim().toLowerCase();
      final loc = listing.location.toLowerCase();
      final isRemote = loc.contains('remote') || loc.contains('nationwide');
      if (!loc.contains(city) && !isRemote) return false;
    }

    final types = jobTypes.where((item) => item != 'Any').toList();
    if (types.isNotEmpty) {
      final matched = types.any((type) => haystack.contains(type.toLowerCase()));
      if (!matched) return false;
    }

    if (category != 'Any' && !haystack.contains(category.toLowerCase())) {
      return false;
    }

    if (language != 'Any') {
      const languages = [
        'Hindi',
        'English',
        'Gujarati',
        'Marathi',
        'Punjabi',
        'Tamil',
        'Telugu',
        'Kannada',
        'Malayalam',
        'Bengali',
        'Urdu',
      ];
      final mentionsLanguage = haystack.contains(language.toLowerCase());
      final mentionsAnyLanguage =
          languages.any((item) => haystack.contains(item.toLowerCase()));
      if (mentionsAnyLanguage && !mentionsLanguage) return false;
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

  bool _matchesWorkMode(JobListing listing) {
    if (workMode == 'All') return true;
    final loc = '${listing.location} ${listing.details}'.toLowerCase();
    final type = _resolvedLocationType(listing.locationType, loc);
    switch (workMode) {
      case 'Remote':
        return type == LocationType.remote;
      case 'Online':
        return type == LocationType.online;
      case 'Onsite':
        return type == LocationType.onsite;
      default:
        return true;
    }
  }

  LocationType _resolvedLocationType(LocationType stored, String loc) {
    if (loc.contains('online') || loc.contains('virtual')) {
      return LocationType.online;
    }
    if (loc.contains('onsite') ||
        loc.contains('on-site') ||
        loc.contains('on site')) {
      return LocationType.onsite;
    }
    if (loc.contains('remote') || loc.contains('nationwide')) {
      return LocationType.remote;
    }
    return stored;
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
}

const jobListings = [
  JobListing(
    title: 'FTII Casting Call',
    details: 'Paid collab · Film & TV',
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
    details: 'Paid collab · Lifestyle',
    location: 'Bengaluru, Karnataka',
    seenStatus: 'Posted 1 hr ago',
    avatarColor: Color(0xFF4DB6AC),
    imageIndex: 4,
  ),
  JobListing(
    title: 'Product Review Campaign',
    details: 'Paid collab · Beauty',
    location: 'Delhi NCR',
    seenStatus: 'Posted 1 hr ago',
    avatarColor: Color(0xFF9575CD),
    imageIndex: 5,
  ),
  JobListing(
    title: 'Fashion Lookbook Shoot',
    details: 'Paid collab · Fashion',
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
    details: 'Paid collab · Gadgets',
    location: 'Pune, Maharashtra',
    seenStatus: 'Posted 8 days ago',
    avatarColor: Color(0xFFFFB74D),
    imageIndex: 8,
  ),
  JobListing(
    title: 'Festival Campaign Shoot',
    details: 'Paid collab · Lifestyle',
    location: 'Ahmedabad, Gujarat',
    seenStatus: 'Posted 8 days ago',
    avatarColor: Color(0xFF4DB6AC),
    imageIndex: 9,
  ),
];
