import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/features/jobs/screens/applied_jobs_screen.dart';
import 'package:bombay_casting/features/jobs/screens/saved_jobs_screen.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_feed_status.dart';
import 'package:bombay_casting/core/widgets/app_screen_layout.dart';
import 'package:bombay_casting/core/widgets/app_tab_bar.dart';
import 'package:bombay_casting/core/navigation/app_navigation.dart';
import 'package:bombay_casting/features/creators/widgets/creator_card.dart';
import 'package:bombay_casting/features/jobs/models/job_listing.dart';
import 'package:bombay_casting/features/jobs/widgets/job_card.dart';
import 'package:bombay_casting/features/jobs/widgets/profile_completion_banner.dart';
import 'package:bombay_casting/features/jobs/widgets/recent_jobs_carousel.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  List<AppTabItem> _getTabs(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      AppTabItem(label: l10n.all, indicatorWidth: 24),
      AppTabItem(label: l10n.saved, indicatorWidth: 40),
      AppTabItem(label: l10n.appliedJobs, indicatorWidth: 48),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final selectedHomeTab = appState.homeInnerTabIndex;

    return AppScreenLayout(
      tabs: _getTabs(context),
      selectedTabIndex: selectedHomeTab,
      onTabChanged: (i) => context.read<AppState>().setHomeInnerTab(i),
      innerTabKey: selectedHomeTab,
      actions: const [_HomeNotificationBell()],
      body: switch (selectedHomeTab) {
        0 => const _HomeAllTab(),
        1 => const SavedJobsTabContent(),
        _ => const AppliedJobsTabContent(),
      },
    );
  }
}

class _HomeAllTab extends StatefulWidget {
  const _HomeAllTab();

  @override
  State<_HomeAllTab> createState() => _HomeAllTabState();
}

class _HomeAllTabState extends State<_HomeAllTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().loadCreators();
    });
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<AppState>().refreshJobs(),
      context.read<AppState>().refreshCreators(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final recommendedJobs = listingsForJobs(appState.jobs).take(5).toList();
    final topCreators = appState.creators.take(6).toList();
    final completionPercent = appState.profile?.completionPercentage ?? 0;

    return AppScrollBody(
      onRefresh: _refresh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (completionPercent < 100) ...[
            ProfileCompletionBanner(percentage: completionPercent),
            const SizedBox(height: AppSpacing.md),
          ],
          const RecentJobsCarousel(),
          const SizedBox(height: AppSpacing.lg),
          const AppSectionTitle('Recommended jobs'),
          const SizedBox(height: AppSpacing.sm),
          if (appState.jobs.isEmpty &&
              (appState.isLoadingJobs || appState.jobsLoadError != null))
            AppFeedStatus(
              isLoading: appState.isLoadingJobs,
              errorMessage: appState.jobsLoadError != null
                  ? AppLocalizations.of(context)!.couldNotLoadJobs
                  : null,
              onRetry: appState.jobsLoadError != null
                  ? () => context.read<AppState>().refreshJobs()
                  : null,
              retryLabel: AppLocalizations.of(context)!.tryAgain,
            )
          else if (recommendedJobs.isEmpty)
            Text(
              AppLocalizations.of(context)!.noJobsYetPullDownToRefresh,
              style: context.bodyMedium,
            )
          else
            for (var i = 0; i < recommendedJobs.length; i++) ...[
              JobCard(job: recommendedJobs[i]),
              if (i < recommendedJobs.length - 1)
                const SizedBox(height: AppSpacing.lg),
            ],
          const SizedBox(height: AppSpacing.lg),
          const AppSectionTitle('Top artists'),
          const SizedBox(height: AppSpacing.sm),
          if (appState.isCreatorsFeedEmpty &&
              (appState.isLoadingCreators ||
                  appState.creatorsLoadError != null))
            AppFeedStatus(
              isLoading: appState.isLoadingCreators,
              errorMessage: appState.creatorsLoadError != null
                  ? AppLocalizations.of(context)!.couldNotLoadCreators
                  : null,
              onRetry: appState.creatorsLoadError != null
                  ? () => context.read<AppState>().refreshCreators()
                  : null,
              retryLabel: AppLocalizations.of(context)!.tryAgain,
            )
          else if (topCreators.isEmpty)
            Text(
              AppLocalizations.of(context)!.noCreatorsToShowYet,
              style: context.bodyMedium,
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                childAspectRatio: 0.72,
              ),
              itemCount: topCreators.length,
              itemBuilder: (context, index) {
                final creator = topCreators[index];
                return CreatorCard(
                  creator: creator,
                  onTap: () =>
                      AppNavigation.openCreatorProfile(context, creator),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _HomeNotificationBell extends StatelessWidget {
  const _HomeNotificationBell();

  @override
  Widget build(BuildContext context) {
    final unreadCount = context.watch<AppState>().unreadNotificationCount;
    return IconButton(
      tooltip: 'Notifications',
      onPressed: () => AppNavigation.openNotifications(context),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(
            Icons.notifications_outlined,
            color: AppColors.textPrimary,
          ),
          if (unreadCount > 0)
            Positioned(
              right: 1,
              top: 1,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.brandRed,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
