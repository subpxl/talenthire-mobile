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
import 'package:bombay_casting/core/widgets/app_screen_layout.dart';
import 'package:bombay_casting/core/widgets/placeholder_avatar.dart';
import 'package:bombay_casting/core/widgets/app_success_toast.dart';
import 'package:bombay_casting/core/widgets/report_dialog.dart';
import 'package:bombay_casting/core/widgets/share_link_button.dart';
import 'package:bombay_casting/features/jobs/widgets/apply_job_sheet.dart';
import 'package:bombay_casting/features/jobs/widgets/job_detail_sections.dart';

class JobDetailScreen extends StatelessWidget {
  const JobDetailScreen({
    super.key,
    required this.profile,
  });

  final JobDetailData profile;

  @override
  Widget build(BuildContext context) {
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
        title: Text(AppLocalizations.of(context)!.job,
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
                final result = await showReportDialog(
                  context,
                  title: l10n.reportJob,
                );
                if (result != null && context.mounted) {
                  showAppSuccessToast(context, l10n.jobReported);
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'report',
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
            JobDetailStatsBar(
              job: listing,
              postedAt: firebaseJob?.postedAt,
            ),
            const SizedBox(height: AppSpacing.lg),
            const JobRolesSection(),
            const SizedBox(height: AppSpacing.lg),
            JobAboutSection(job: listing),
            const SizedBox(height: AppSpacing.lg),
            const JobSubmitSection(),
            const SizedBox(height: AppSpacing.lg),
            JobDetailMetaFooter(
              appliedCount: firebaseJob?.applied ?? 0,
              jobId: profile.jobId,
              onReport: () async {
                final l10n = AppLocalizations.of(context)!;
                final result = await showReportDialog(
                  context,
                  title: l10n.reportJob,
                );
                if (result != null && context.mounted) {
                  showAppSuccessToast(context, l10n.jobReported);
                }
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          8,
          AppSpacing.screenH,
          16,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: hasApplied ? null : () => _apply(context),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Ink(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: hasApplied ? AppColors.successSoft : AppColors.brandRed,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Center(
                child: hasApplied
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

  Future<void> _apply(BuildContext context) async {
    if (!AppNavigation.requireApplyAccess(context)) return;
    final appState = context.read<AppState>();
    final job = appState.jobById(profile.jobId);
    if (job == null) {
      showAppToast(
        context,
        AppLocalizations.of(context)!.thisJobIsNoLongerAvailable,
        type: AppToastType.error,
      );
      return;
    }
    final result = await showApplyJobSheet(
      context,
      jobTitle: job.title,
      company: job.company,
      pay: job.payLabel,
    );
    if (result == null || !context.mounted) return;
    final sent = await appState.applyToJob(
      job,
      script: result.script,
      youtubeShortUrl: result.youtubeShortUrl,
    );
    if (!context.mounted) return;
    showAppToast(
      context,
      sent ? 'Application sent' : 'Could not send application',
      type: sent ? AppToastType.success : AppToastType.error,
    );
  }

  Widget _buildHeader(BuildContext context) {
    final company = profile.company.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                profile.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (profile.isVerified) ...[
              const SizedBox(width: 6),
              const Icon(Icons.verified, color: AppColors.chatGreen, size: 18),
            ],
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
            child: Text.rich(
              TextSpan(
                text: 'by ',
                style: context.bodyMedium,
                children: [
                  TextSpan(
                    text: company,
                    style: const TextStyle(
                      color: AppColors.brandRed,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.brandRed,
                    ),
                  ),
                ],
              ),
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
    description: profile.description,
    category: profile.category,
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
  final String category;
  final String offerType;
  final String budget;
  final List<String> tags;
  final String company;
  final String createdBy;

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
    this.category = '',
    this.offerType = '',
    this.budget = '',
    this.tags = const [],
    this.company = '',
    this.createdBy = '',
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
      category: job.category,
      offerType: job.collabType,
      budget: job.pay.toLowerCase().contains('not specified') ? 'Undisclosed' : job.pay,
      tags: job.tags,
      company: company ?? job.company,
      createdBy: createdBy ?? '',
    );
  }

  factory JobDetailData.fromMessageContact(MessageContactModel contact) {
    return JobDetailData(
      name: contact.name,
      details: contact.details,
      location: contact.location,
      postedLabel: contact.seenStatus,
      isVerified: contact.isVerified,
      avatarColor: contact.avatarColor,
      imageIndex: contact.imageIndex,
      description: 'Looking for creators for upcoming campaign.',
      gender: 'Any',
      age: 'Any',
      category: 'Influencer',
      offerType: 'Paid collaboration',
      budget: '₹ 15,000 - ₹ 40,000',
      tags: const ['instagram', 'youtube'],
    );
  }
}

class MessageContactModel {
  final String name;
  final String seenStatus;
  final String details;
  final String location;
  final bool isVerified;
  final Color avatarColor;
  final int imageIndex;

  const MessageContactModel({
    required this.name,
    required this.seenStatus,
    required this.details,
    required this.location,
    required this.avatarColor,
    this.isVerified = false,
    this.imageIndex = 1,
  });
}
