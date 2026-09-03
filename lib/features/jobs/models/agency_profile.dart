import 'package:bombay_casting/features/jobs/models/job_model.dart';

class AgencyProfile {
  const AgencyProfile({
    required this.id,
    required this.name,
    this.location = '',
    this.imageUrl = '',
    this.imageIndex = 1,
    this.isVerified = false,
    this.createdBy = '',
    this.jobCount = 0,
    this.description = '',
    this.categories = const [],
  });

  final String id;
  final String name;
  final String location;
  final String imageUrl;
  final int imageIndex;
  final bool isVerified;
  final String createdBy;
  final int jobCount;
  final String description;
  final List<String> categories;

  static AgencyProfile fromJob(Job job, {required List<Job> allJobs}) {
    final company = job.company.trim();
    final agencyJobs = jobsForAgency(
      allJobs,
      company: company,
      createdBy: job.createdBy,
    );
    final primary = agencyJobs.isNotEmpty ? agencyJobs.first : job;
    final withImage = agencyJobs.cast<Job?>().firstWhere(
          (item) => item!.imageUrl.isNotEmpty,
          orElse: () => primary,
        )!;

    final categories = <String>{};
    for (final agencyJob in agencyJobs) {
      if (agencyJob.category.trim().isNotEmpty) {
        categories.add(agencyJob.category.trim());
      }
    }

    final locations = agencyJobs
        .map((item) => item.location.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();

    return AgencyProfile(
      id: job.createdBy.isNotEmpty
          ? job.createdBy
          : _slugify(company.isNotEmpty ? company : 'agency'),
      name: company.isNotEmpty ? company : 'Agency',
      location: locations.isNotEmpty ? locations.first : job.location,
      imageUrl: withImage.imageUrl,
      imageIndex: withImage.fallbackImageIndex,
      isVerified: agencyJobs.any((item) => item.isVerified),
      createdBy: job.createdBy,
      jobCount: agencyJobs.length,
      description: primary.summary.trim().isNotEmpty
          ? primary.summary.trim()
          : 'Casting agency posting opportunities for creators.',
      categories: categories.take(4).toList(),
    );
  }

  static AgencyProfile fromCompany({
    required String company,
    required List<Job> allJobs,
    String createdBy = '',
    String location = '',
    String imageUrl = '',
    int imageIndex = 1,
    bool isVerified = false,
  }) {
    final matching = jobsForAgency(
      allJobs,
      company: company,
      createdBy: createdBy,
    );
    if (matching.isNotEmpty) {
      return AgencyProfile.fromJob(matching.first, allJobs: allJobs);
    }
    return AgencyProfile(
      id: createdBy.isNotEmpty ? createdBy : _slugify(company),
      name: company,
      location: location,
      imageUrl: imageUrl,
      imageIndex: imageIndex,
      isVerified: isVerified,
      createdBy: createdBy,
    );
  }

  static List<Job> jobsForAgency(
    List<Job> allJobs, {
    required String company,
    String createdBy = '',
  }) {
    final normalizedCompany = company.trim().toLowerCase();
    return allJobs.where((job) {
      if (createdBy.isNotEmpty && job.createdBy == createdBy) return true;
      if (normalizedCompany.isEmpty) return false;
      return job.company.trim().toLowerCase() == normalizedCompany;
    }).toList();
  }

  static String _slugify(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}
