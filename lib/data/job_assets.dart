import 'package:flutter/material.dart';
import 'package:bombay_casting/models/models.dart';

/// Job poster files live in `assets/jobs/job (1).jpeg` … `job (66).jpeg`.
class JobAssets {
  JobAssets._();

  static const count = 66;

  static String pathFor(int index) {
    final n = ((index - 1) % count) + 1;
    return 'assets/jobs/job ($n).jpeg';
  }
}

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
  });

  final double followerStart;
  final double followerEnd;
  final double payStart;
  final double payEnd;
  final bool includeOtherCities;
  final String location;
  final Set<String> jobTypes;
  final String language;
  final String category;

  bool get isActive {
    return location != 'Any' ||
        language != 'Any' ||
        category != 'Any' ||
        jobTypes.any((item) => item != 'Any') ||
        followerStart > 0 ||
        followerEnd < 100 ||
        payStart > 0 ||
        payEnd < 500000;
  }

  bool matches(JobListing listing) {
    final haystack =
        '${listing.title} ${listing.details} ${listing.location}'.toLowerCase();

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
