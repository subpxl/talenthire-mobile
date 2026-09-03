import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/features/jobs/models/job_listing.dart';
import 'package:bombay_casting/core/models/models.dart';
import 'package:bombay_casting/core/navigation/app_navigation.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/features/jobs/screens/job_detail_screen.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_screen_layout.dart';
import 'package:bombay_casting/core/widgets/placeholder_avatar.dart';
import 'package:bombay_casting/core/widgets/promo_banner.dart';
import 'package:bombay_casting/features/jobs/widgets/profile_completion_banner.dart';

class ShortlistTabContent extends StatelessWidget {
  const ShortlistTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final savedJobs = appState.savedJobs;
    final isPremium = appState.isPremiumUser;
    final completionPercent = appState.profile?.completionPercentage ?? 20;
    final profileBanner = completionPercent < 100
        ? [
            ProfileCompletionBanner(percentage: completionPercent),
            const SizedBox(height: AppSpacing.md),
          ]
        : const <Widget>[];
    if (savedJobs.isEmpty) {
      return AppScrollBody(
        onRefresh: () => context.read<AppState>().refreshSavedJobs(),
        child: Column(
          children: [
            ...profileBanner,
            if (!isPremium)
              PromoBanner(
                title: 'Your saved jobs',
                subtitle: 'Apply to jobs and land your next collab',
                actionLabel: 'Apply Now',
                onAction: () {
                  if (!AppNavigation.requireSubscription(context)) return;
                },
              ),
            if (!isPremium) const SizedBox(height: AppSpacing.lg - 4),
            Text(AppLocalizations.of(context)!.tapBookmarkOnAJobToSaveIt,
              style: context.bodyMedium,
            ),
          ],
        ),
      );
    }
    return AppRefreshScrollBody(
      onRefresh: () => context.read<AppState>().refreshSavedJobs(),
      header: [
        ...profileBanner,
        if (!isPremium)
          PromoBanner(
            title: 'Your saved jobs',
            subtitle: 'Apply to jobs and land your next collab',
            actionLabel: 'Apply Now',
            onAction: () {
              if (!AppNavigation.requireSubscription(context)) return;
            },
          ),
        if (!isPremium) const SizedBox(height: AppSpacing.lg),
      ],
      itemCount: savedJobs.length,
      itemBuilder: (context, index) {
        final listing = JobListing.fromJob(savedJobs[index], index);
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < savedJobs.length - 1 ? AppSpacing.lg : 0,
          ),
          child: _SavedJobCard(listing: listing, job: savedJobs[index]),
        );
      },
    );
  }
}

class _SavedJobCard extends StatelessWidget {
  const _SavedJobCard({required this.listing, required this.job});

  final JobListing listing;
  final Job job;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => AppNavigation.openJobDetail(
        context,
        JobDetailData.fromJob(job),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: PlaceholderProfileImage(
                  aspectRatio: 0.9,
                  imageIndex: listing.imageIndex,
                  imageUrl: listing.imageUrl,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  tooltip: 'Remove saved job',
                  onPressed: () => context.read<AppState>().toggleSavedJob(job),
                  icon: const Icon(Icons.favorite, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            listing.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(listing.details, style: context.bodyMedium),
          Text(listing.location, style: context.bodyMedium),
        ],
      ),
    );
  }
}
