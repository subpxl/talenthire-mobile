import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/features/jobs/models/job_listing.dart';
import 'package:bombay_casting/core/navigation/app_navigation.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_screen_layout.dart';
import 'package:bombay_casting/core/widgets/promo_banner.dart';
import 'package:bombay_casting/features/jobs/widgets/job_card.dart';
import 'package:bombay_casting/features/jobs/widgets/profile_completion_banner.dart';

class SavedJobsTabContent extends StatelessWidget {
  const SavedJobsTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appState = context.watch<AppState>();
    final savedJobs = appState.savedJobs;
    final isPremium = appState.isPremiumUser;
    final completionPercent = appState.profile?.completionPercentage ?? 0;
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
                title: l10n.yourSavedJobs,
                subtitle: l10n.savedJobsPromoSubtitle,
                actionLabel: l10n.applyNow,
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
            title: l10n.yourSavedJobs,
            subtitle: l10n.savedJobsPromoSubtitle,
            actionLabel: l10n.applyNow,
            onAction: () {
              if (!AppNavigation.requireSubscription(context)) return;
            },
          ),
        if (!isPremium) const SizedBox(height: AppSpacing.lg),
      ],
      itemCount: savedJobs.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < savedJobs.length - 1 ? AppSpacing.lg : 0,
          ),
          child: JobCard(job: JobListing.fromJob(savedJobs[index], index)),
        );
      },
    );
  }
}
