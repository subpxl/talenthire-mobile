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
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth - 16) / 2;
                return Wrap(
                  spacing: 16,
                  runSpacing: 0,
                  children: [
                    SizedBox(width: itemWidth, child: _buildDetailRow('Location', profile.location, Icons.location_on_outlined)),
                    if (profile.category.isNotEmpty)
                      SizedBox(width: itemWidth, child: _buildDetailRow('Looking for', profile.category, Icons.person_search_outlined)),
                    if (profile.offerType.isNotEmpty)
                      SizedBox(width: itemWidth, child: _buildDetailRow('Offer Type', profile.offerType, Icons.handshake_outlined)),
                    SizedBox(width: itemWidth, child: _buildDetailRow('Budget', profile.budget, Icons.payments_outlined)),
                    if (profile.age.isNotEmpty)
                      SizedBox(width: itemWidth, child: _buildDetailRow('Age Range', profile.age, Icons.calendar_today_outlined)),
                    if (profile.gender.isNotEmpty)
                      SizedBox(width: itemWidth, child: _buildDetailRow('Gender', profile.gender, Icons.wc_outlined)),
                  ],
                );
              },
            ),
            
            if (profile.description.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              const AppSectionTitle('Job Description'),
              const SizedBox(height: AppSpacing.sm),
              Text(
                profile.description,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ],

            if (profile.tags.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              const AppSectionTitle('Tags'),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: profile.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
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

  Widget _buildDetailRow(String label, String value, IconData icon) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
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

        if (profile.postedLabel != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(profile.postedLabel!, style: context.caption),
          ),
      ],
    );
  }
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
      description: job.description,
      gender: job.gender,
      age: job.age,
      category: job.category,
      offerType: job.collabType,
      budget: job.pay.toLowerCase().contains('not specified') ? 'Undisclosed' : job.pay,
      tags: job.tags,
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
