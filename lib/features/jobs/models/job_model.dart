import 'package:bombay_casting/core/models/model_helpers.dart';

enum LocationType { remote, online, onsite }

enum JobStatus { draft, published, closed, cancelled }

JobStatus jobStatusFromString(String value) {
  if (value == 'open') return JobStatus.published;
  return enumFromString(JobStatus.values, value, JobStatus.draft);
}

LocationType locationTypeFromString(String value) {
  final normalized =
      value.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
  switch (normalized) {
    case 'online':
    case 'virtual':
      return LocationType.online;
    case 'onsite':
    case 'onlocation':
      return LocationType.onsite;
    default:
      return enumFromString(LocationType.values, normalized, LocationType.remote);
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
    this.gender = '',
    this.age = '',
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
  final String gender;
  final String age;

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
      tags: stringList(json['tags']),
      imageUrl: (json['image_url'] ?? '').toString(),
      imagePath: (json['image_path'] ?? '').toString(),
      category: category,
      platforms: stringList(json['platforms']),
      collaborationType: collaborationType,
      compensation: compensation,
      deliverables: stringList(json['deliverables']),
      isVerified: json['is_verified'] == true,
      sourceImage: (json['source_image'] ?? '').toString(),
      applied: (json['applied'] as num?)?.toInt() ?? 0,
      minFollowers: _jobMinFollowers(json, category),
      payMin: pay.$1,
      payMax: pay.$2,
      gender: (json['gender'] ?? '').toString(),
      age: (json['age'] ?? json['age_group'] ?? '').toString(),
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
        'gender': gender,
        'age': age,
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
