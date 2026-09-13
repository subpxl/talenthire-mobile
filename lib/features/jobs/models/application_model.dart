import 'package:bombay_casting/core/models/model_helpers.dart';

enum ApplicationStatus {
  applied,
  opened,
  inReview,
  shortlisted,
  interview,
  selected,
  rejected,
  withdrawn,
}

ApplicationStatus applicationStatusFromString(String value) {
  final normalized = value.trim().toLowerCase().replaceAll('-', '_');
  if (normalized.isEmpty || normalized == 'pending') {
    return ApplicationStatus.applied;
  }
  if (normalized == 'in_review' || normalized == 'inreview') {
    return ApplicationStatus.inReview;
  }
  return enumFromString(
    ApplicationStatus.values,
    value,
    ApplicationStatus.applied,
  );
}

String applicationStatusToString(ApplicationStatus status) {
  if (status == ApplicationStatus.inReview) return 'in_review';
  return status.name;
}

class Application {
  Application({
    required this.id,
    this.userId = '',
    this.jobId = '',
    required this.jobTitle,
    this.company = '',
    this.status = ApplicationStatus.applied,
    this.script = '',
    this.youtubeShortUrl = '',
    DateTime? appliedAt,
  }) : appliedAt = appliedAt ?? DateTime.now();

  final String id;
  final String userId;
  final String jobId;
  final String jobTitle;
  final String company;
  final ApplicationStatus status;
  final String script;
  final String youtubeShortUrl;
  final DateTime appliedAt;

  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      id: json['id']?.toString() ?? '',
      userId: (json['user_id'] ?? '').toString(),
      jobId: (json['job_id'] ?? '').toString(),
      jobTitle: (json['job_title'] ?? '').toString(),
      company: (json['company'] ?? '').toString(),
      status: applicationStatusFromString(
        (json['status'] ?? 'applied').toString(),
      ),
      script: (json['script'] ?? '').toString(),
      youtubeShortUrl: (json['youtube_short_url'] ?? '').toString(),
      appliedAt: parseFlexibleDate(json['applied_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'job_id': jobId,
        'job_title': jobTitle,
        'company': company,
        'status': applicationStatusToString(status),
        'script': script,
        'youtube_short_url': youtubeShortUrl,
        'applied_at': appliedAt.toIso8601String(),
      };

  Application copyWith({
    ApplicationStatus? status,
    String? script,
    String? youtubeShortUrl,
    DateTime? appliedAt,
  }) {
    return Application(
      id: id,
      userId: userId,
      jobId: jobId,
      jobTitle: jobTitle,
      company: company,
      status: status ?? this.status,
      script: script ?? this.script,
      youtubeShortUrl: youtubeShortUrl ?? this.youtubeShortUrl,
      appliedAt: appliedAt ?? this.appliedAt,
    );
  }
}
