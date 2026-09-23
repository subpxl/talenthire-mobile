import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/features/jobs/models/agency_profile.dart';
import 'package:bombay_casting/features/jobs/models/job_listing.dart';
import 'package:bombay_casting/core/models/models.dart';
import 'package:bombay_casting/core/navigation/app_navigation.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/deep_links/deep_link_target.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/services/analytics_service.dart';
import 'package:bombay_casting/core/services/report_service.dart';
import 'package:bombay_casting/core/widgets/app_screen_layout.dart';
import 'package:bombay_casting/core/widgets/app_success_toast.dart';
import 'package:bombay_casting/core/widgets/placeholder_avatar.dart';
import 'package:bombay_casting/core/widgets/share_link_button.dart';
import 'package:bombay_casting/core/widgets/verified_tick.dart';
import 'package:bombay_casting/features/jobs/widgets/apply_job_sheet.dart';
import 'package:bombay_casting/features/jobs/widgets/job_detail_sections.dart';

class JobDetailScreen extends StatefulWidget {
  const JobDetailScreen({super.key, required this.profile});

  final JobDetailData profile;

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  bool _isApplying = false;

  @override
  void initState() {
    super.initState();
    final jobId = widget.profile.jobId;
    if (jobId.isNotEmpty) {
      AnalyticsService.instance.track(
        () => AnalyticsService.instance.logViewJob(
          jobId: jobId,
          jobTitle: widget.profile.name,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final appState = context.watch<AppState>();
    final firebaseJob = appState.jobById(profile.jobId);
    final listing = _listingFor(profile, firebaseJob);
    final hasApplied =
        profile.jobId.isNotEmpty && appState.hasApplied(profile.jobId);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.job,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          ShareLinkButton(
            url: DeepLinkTarget.jobUrl(profile.jobId),
            message: 'Check out this job on Bombay Casting Company',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'report') {
                final l10n = AppLocalizations.of(context)!;
                await ReportService.instance.submitFromDialog(
                  context,
                  dialogTitle: l10n.reportJob,
                  successMessage: l10n.jobReported,
                  target: ReportTarget(
                    type: ReportType.job,
                    targetId: profile.jobId,
                    targetLabel: listing.title,
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'report',
                child: Text(AppLocalizations.of(context)!.reportJob),
              ),
            ],
          ),
        ],
      ),
      body: AppScrollBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: PlaceholderProfileImage(
                aspectRatio: 0.85,
                imageIndex: profile.imageIndex,
                imageUrl: profile.imageUrl,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildHeader(context)),
                if (profile.jobId.isNotEmpty)
                  IconButton(
                    key: const Key('e2e_job_save'),
                    tooltip: appState.isJobSaved(profile.jobId)
                        ? 'Remove saved job'
                        : 'Save job',
                    onPressed: () {
                      final job = appState.jobById(profile.jobId);
                      if (job != null) appState.toggleSavedJob(job);
                    },
                    icon: Icon(
                      appState.isJobSaved(profile.jobId)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: AppColors.brandRed,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            JobDetailStatsBar(job: listing, postedAt: firebaseJob?.postedAt),
            const SizedBox(height: AppSpacing.lg),
            JobAboutSection(job: listing),
            const SizedBox(height: AppSpacing.lg),
            JobSubmitSection(
              requiresVideo:
                  firebaseJob?.requiresVideoSubmission ?? listing.isAudition,
            ),
            const SizedBox(height: AppSpacing.lg),
            JobDetailMetaFooter(
              appliedCount: firebaseJob?.applied ?? 0,
              jobId: profile.jobId,
              onReport: () async {
                final l10n = AppLocalizations.of(context)!;
                await ReportService.instance.submitFromDialog(
                  context,
                  dialogTitle: l10n.reportJob,
                  successMessage: l10n.jobReported,
                  target: ReportTarget(
                    type: ReportType.job,
                    targetId: profile.jobId,
                    targetLabel: listing.title,
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          8,
          AppSpacing.screenH,
          24 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: const Key('e2e_job_detail_apply'),
            onTap: hasApplied || _isApplying ? null : _apply,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Ink(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: hasApplied ? AppColors.successSoft : AppColors.brandRed,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Center(
                child: _isApplying
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : hasApplied
                    ? const Text(
                        'Applied',
                        style: TextStyle(
                          color: AppColors.accentGreen,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.applyNow,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _apply() async {
    if (_isApplying) return;
    if (!AppNavigation.requireApplyAccess(context)) return;
    final appState = context.read<AppState>();
    final job = appState.jobById(widget.profile.jobId);
    if (job == null) {
      showAppToast(
        context,
        AppLocalizations.of(context)!.thisJobIsNoLongerAvailable,
        type: AppToastType.error,
      );
      return;
    }

    if (job.requiresVideoSubmission) {
      final result = await showApplyJobSheet(
        context,
        jobTitle: job.title,
        company: job.company,
        pay: job.payLabel,
        auditionScript: job.auditionScript,
        referenceVideoLink: job.interviewVideoLink,
        onSubmit: (applyResult) {
          return appState.applyToJob(
            job,
            script: applyResult.script,
            youtubeShortUrl: applyResult.youtubeShortUrl,
          );
        },
      );
      if (result == null || !mounted) return;
      showAppToast(context, 'Application sent');
      return;
    }

    setState(() => _isApplying = true);
    try {
      final sent = await appState.applyToJob(job);
      if (!mounted) return;
      showAppToast(
        context,
        sent ? 'Application sent' : 'Could not send application',
        type: sent ? AppToastType.success : AppToastType.error,
      );
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  Widget _buildHeader(BuildContext context) {
    final profile = widget.profile;
    final company = profile.company.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                titleCaseWords(profile.name),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        if (company.isNotEmpty) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () {
              final appState = context.read<AppState>();
              final job = appState.jobById(profile.jobId);
              AppNavigation.openAgencyDetail(
                context,
                job != null
                    ? AgencyProfile.fromJob(job, allJobs: appState.jobs)
                    : AgencyProfile.fromCompany(
                        company: company,
                        allJobs: appState.jobs,
                        createdBy: profile.createdBy,
                        location: profile.location,
                        imageUrl: profile.imageUrl,
                        imageIndex: profile.imageIndex,
                        isVerified: profile.isVerified,
                      ),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    titleCaseWords(company),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.brandRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const VerifiedTick(size: 16),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

JobListing _listingFor(JobDetailData profile, Job? job) {
  if (job != null) return JobListing.fromJob(job, 0);
  return JobListing(
    title: profile.name,
    details: profile.details,
    location: profile.location,
    seenStatus: profile.postedLabel ?? '',
    avatarColor: profile.avatarColor,
    imageIndex: profile.imageIndex,
    role: profile.category,
    collabType: profile.offerType,
    pay: profile.budget,
    tags: profile.tags,
    gender: profile.gender,
    age: profile.age,
    projectTag: profile.projectTag,
    description: profile.description,
    category: profile.category,
    postedAt: profile.postedAt,
    applicationDeadline: profile.applicationDeadline,
    locationType: profile.locationType,
  );
}

// removed _InfoSection

class JobDetailData {
  final String name;
  final String details;
  final String location;
  final String? postedLabel;
  final bool isVerified;
  final Color avatarColor;
  final int imageIndex;
  final String imageUrl;
  final String jobId;
  final String description;
  final String gender;
  final String age;
  final String projectTag;
  final String category;
  final String offerType;
  final String budget;
  final List<String> tags;
  final String company;
  final String createdBy;
  final DateTime? postedAt;
  final DateTime? applicationDeadline;
  final LocationType locationType;

  const JobDetailData({
    required this.name,
    required this.details,
    required this.location,
    required this.avatarColor,
    this.imageIndex = 1,
    this.imageUrl = '',
    this.jobId = '',
    this.postedLabel,
    this.isVerified = false,
    this.description = '',
    this.gender = '',
    this.age = '',
    this.projectTag = '',
    this.category = '',
    this.offerType = '',
    this.budget = '',
    this.tags = const [],
    this.company = '',
    this.createdBy = '',
    this.postedAt,
    this.applicationDeadline,
    this.locationType = LocationType.remote,
  });

  factory JobDetailData.fromJob(Job job, {int index = 0}) {
    final listing = JobListing.fromJob(job, index);
    return JobDetailData.fromJobListing(
      listing,
      company: job.company,
      createdBy: job.createdBy,
    );
  }

  factory JobDetailData.fromJobListing(
    JobListing job, {
    String? company,
    String? createdBy,
  }) {
    return JobDetailData(
      name: job.title,
      details: job.details,
      location: job.location,
      postedLabel: job.seenStatus,
      isVerified: job.isVerified,
      avatarColor: job.avatarColor,
      imageIndex: job.imageIndex,
      imageUrl: job.imageUrl,
      jobId: job.jobId,
      description: job.description,
      gender: job.gender,
      age: job.age,
      projectTag: job.projectTag,
      category: job.role.trim().isNotEmpty ? job.role : job.category,
      offerType: job.collabType,
      budget: job.pay.toLowerCase().contains('not specified')
          ? 'Undisclosed'
          : job.pay,
      tags: job.tags,
      company: company ?? job.company,
      createdBy: createdBy ?? '',
      postedAt: job.postedAt,
      applicationDeadline: job.applicationDeadline,
      locationType: job.locationType,
    );
  }
}

String titleCaseWords(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return trimmed;
  return trimmed
      .split(RegExp(r'\s+'))
      .map((word) {
        if (word.isEmpty) return word;
        return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
      })
      .join(' ');
}
