import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/features/jobs/models/job_listing.dart';
import 'package:bombay_casting/core/models/models.dart';
import 'package:bombay_casting/core/navigation/app_navigation.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_screen_layout.dart';
import 'package:bombay_casting/core/widgets/placeholder_avatar.dart';

class JobDetailScreen extends StatelessWidget {
  const JobDetailScreen({
    super.key,
    required this.profile,
  });

  final JobDetailData profile;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final hasApplied =
        profile.jobId.isNotEmpty && appState.hasApplied(profile.jobId);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'report') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.jobReported)),
                );
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
                Row(
                  children: [
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
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: AppColors.primary,
                        ),
                      ),
                    IconButton(
                      tooltip: 'Call',
                      icon: const Icon(Icons.phone_outlined),
                      color: AppColors.textSecondary,
                      onPressed: () => AppNavigation.openPremiumScreen(context),
                    ),
                    IconButton(
                      tooltip: 'Message',
                      icon: const Icon(Icons.chat_bubble_outline),
                      color: AppColors.chatGreen,
                      onPressed: () => AppNavigation.openPremiumScreen(context),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _InfoSection(title: 'Role', items: profile.roleInfo),
            const SizedBox(height: AppSpacing.md),
            _InfoSection(title: 'Pay & type', items: profile.payInfo),
            const SizedBox(height: AppSpacing.lg),
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
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: hasApplied ? null : () => _apply(context),
            child: Text(hasApplied ? 'Applied' : AppLocalizations.of(context)!.applyNow),
          ),
        ),
      ),
    );
  }

  Future<void> _apply(BuildContext context) async {
    if (!AppNavigation.requireSubscription(context)) return;
    final appState = context.read<AppState>();
    final job = appState.jobById(profile.jobId);
    if (job == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.thisJobIsNoLongerAvailable)),
      );
      return;
    }
    final sent = await appState.applyToJob(job);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(sent ? 'Application sent' : 'Could not send application'),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
        const SizedBox(height: AppSpacing.xs),
        Text(profile.details, style: context.bodyMedium),
        Text(profile.location, style: context.bodyMedium),
        if (profile.postedLabel != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(profile.postedLabel!, style: context.caption),
          ),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.items});

  final String title;
  final List<MapEntry<String, String>> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionTitle(title),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 4,
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.primary),
          ),
          child: Column(
            children: items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(item.key, style: context.caption),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        item.value,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

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
  final List<MapEntry<String, String>> roleInfo;
  final List<MapEntry<String, String>> payInfo;

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
    this.roleInfo = const [],
    this.payInfo = const [],
  });

  factory JobDetailData.fromJob(Job job, {int index = 0}) {
    return JobDetailData.fromJobListing(JobListing.fromJob(job, index));
  }

  factory JobDetailData.fromJobListing(JobListing job) {
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
      roleInfo: [
        MapEntry('Role', _detailValue(job.role, 'Creator')),
        MapEntry('Platform', _detailValue(job.platforms, 'Open')),
        MapEntry('Type', _detailValue(job.collabType, job.details)),
        MapEntry(
          'Followers',
          _detailValue(job.followersLabel, 'Open to creators'),
        ),
      ],
      payInfo: [
        MapEntry('Category', _detailValue(job.category, job.details)),
        MapEntry('Duration', _detailValue(job.duration, 'Campaign based')),
        MapEntry('Pay', _detailValue(job.pay, job.details)),
      ],
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
      roleInfo: const [
        MapEntry('Role', 'Creator / influencer'),
        MapEntry('Platform', 'Instagram, YouTube'),
        MapEntry('Type', 'Paid collaboration'),
        MapEntry('Followers', '10K+ preferred'),
      ],
      payInfo: const [
        MapEntry('Category', 'Brand collab'),
        MapEntry('Duration', '2 weeks'),
        MapEntry('Pay', '₹ 15,000 - ₹ 40,000'),
      ],
    );
  }

  static String _detailValue(String value, String fallback) {
    final text = value.trim();
    return text.isEmpty ? fallback : text;
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
