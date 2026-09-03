import 'package:bombay_casting/core/models/model_helpers.dart';

enum ApplicationStatus {
  applied,
  opened,
  shortlisted,
  interview,
  selected,
  rejected,
  withdrawn,
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
      status: enumFromString(
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
