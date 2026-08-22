import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/data/job_assets.dart';
import 'package:bombay_casting/models/models.dart';
import 'package:bombay_casting/navigation/app_navigation.dart';
import 'package:bombay_casting/providers/app_state.dart';
import 'package:bombay_casting/screens/job_detail_screen.dart';
import 'package:bombay_casting/theme/app_theme.dart';
import 'package:bombay_casting/widgets/app_screen_layout.dart';
import 'package:bombay_casting/widgets/placeholder_avatar.dart';
import 'package:bombay_casting/widgets/promo_banner.dart';

class ShortlistTabContent extends StatelessWidget {
  const ShortlistTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final savedJobs = appState.savedJobs;
    if (savedJobs.isEmpty) {
      return AppScrollBody(
        onRefresh: () => context.read<AppState>().refreshSavedJobs(),
        child: Column(
          children: [
            PromoBanner(
              title: 'Your saved jobs',
              subtitle: 'Apply to jobs and land your next collab',
              actionLabel: 'Apply Now',
              onAction: () {
                if (!AppNavigation.requireSubscription(context)) return;
              },
            ),
            const SizedBox(height: AppSpacing.lg - 4),
            Text(
              'Tap bookmark on a job to save it',
              style: context.bodyMedium,
            ),
          ],
        ),
      );
    }
    return AppRefreshScrollBody(
      onRefresh: () => context.read<AppState>().refreshSavedJobs(),
      header: [
        PromoBanner(
          title: 'Your saved jobs',
          subtitle: 'Apply to jobs and land your next collab',
          actionLabel: 'Apply Now',
          onAction: () {
            if (!AppNavigation.requireSubscription(context)) return;
          },
        ),
        const SizedBox(height: AppSpacing.lg),
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
                  icon: const Icon(Icons.bookmark, color: AppColors.primary),
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
