import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/core/models/models.dart';
import 'package:bombay_casting/features/jobs/models/job_listing.dart';
import 'package:bombay_casting/core/navigation/app_navigation.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/features/jobs/screens/preference_filter_screen.dart';
import 'package:bombay_casting/features/jobs/screens/shortlisted_screen.dart';
import 'package:bombay_casting/features/jobs/screens/job_detail_screen.dart';
import 'package:bombay_casting/features/profile/screens/edit_profile_view_screen.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_screen_layout.dart';
import 'package:bombay_casting/core/widgets/app_search_filters.dart';
import 'package:bombay_casting/core/widgets/app_tab_bar.dart';
import 'package:bombay_casting/core/widgets/placeholder_avatar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AppTabItem> _getTabs(BuildContext context) {
    return [
      AppTabItem(label: AppLocalizations.of(context)!.all, indicatorWidth: 24),
      AppTabItem(
        label: AppLocalizations.of(context)!.saved,
        indicatorWidth: 40,
      ),
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
      actions: [
        IconButton(
          tooltip: 'Filters',
          icon: Icon(
            appState.jobFilter.hasAdvancedFilters
                ? Icons.filter_alt
                : Icons.filter_alt_outlined,
          ),
          color: appState.jobFilter.hasAdvancedFilters
              ? AppColors.primary
              : AppColors.textSecondary,
          onPressed: () =>
              AppNavigation.push(context, const PreferenceScreen()),
        ),
      ],
      body: selectedHomeTab == 0
          ? _buildAllTab(appState)
          : const ShortlistTabContent(),
    );
  }

  Widget _buildAllTab(AppState appState) {
    final homeJobs = appState.filteredJobListings;
    final Widget empty;
    final noMatches =
        appState.jobFilter.isActive ||
        (appState.jobs.isNotEmpty && homeJobs.isEmpty);
    if (noMatches) {
      empty = Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 8),
        child: Text(
          AppLocalizations.of(
            context,
          )!.noJobsMatchYourFiltersPullToRefreshOrChangeFilters,
          style: context.bodyMedium,
        ),
      );
    } else {
      empty = Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Text(
          AppLocalizations.of(context)!.noJobsYetPullDownToRefresh,
          style: context.bodyMedium,
        ),
      );
    }

    final profile = appState.profile;
    final completionPercent = profile?.completionPercentage ?? 20;

    return AppRefreshScrollBody(
      onRefresh: () => context.read<AppState>().refreshJobs(),
      onLoadMore: () => context.read<AppState>().loadMoreJobs(),
      isLoadingMore: appState.isLoadingMoreJobs,
      hasMore: appState.hasMoreJobs,
      header: [
        AppSearchField(
          controller: _searchController,
          hintText: AppLocalizations.of(context)!.searchJobsAgencyLocation,
          onChanged: (query) {
            context.read<AppState>().setJobFilter(
              appState.jobFilter.copyWith(searchQuery: query),
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        if (completionPercent < 100) ...[
          _ProfileCompletionBanner(percentage: completionPercent),
          const SizedBox(height: AppSpacing.lg),
        ],
        const AppSectionTitle('Jobs for you'),
      ],
      empty: empty,
      itemCount: homeJobs.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < homeJobs.length - 1 ? AppSpacing.lg : 0,
          ),
          child: _JobCard(job: homeJobs[index]),
        );
      },
    );
  }
}

class _ProfileCompletionBanner extends StatelessWidget {
  const _ProfileCompletionBanner({required this.percentage});

  final int percentage;

  @override
  Widget build(BuildContext context) {
    if (percentage >= 100) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => AppNavigation.push(context, const EditProfileScreen()),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.bannerStart, AppColors.bannerEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Complete your profile',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    percentage < 100 ? 'Add details to get 3x more deals.' : '',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Update profile',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 10,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 58,
                  height: 58,
                  child: CircularProgressIndicator(
                    value: percentage / 100.0,
                    strokeWidth: 5.5,
                    backgroundColor: Colors.black.withValues(alpha: 0.12),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  '$percentage%',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job});

  final JobListing job;

  @override
  Widget build(BuildContext context) {
    return Selector<AppState, ({bool saved, Job? firebaseJob, bool isPremium})>(
      selector: (_, state) => (
        saved: job.jobId.isNotEmpty && state.isJobSaved(job.jobId),
        firebaseJob: state.jobById(job.jobId),
        isPremium: state.isPremiumUser,
      ),
      builder: (context, data, _) {
        final saved = data.saved;
        final firebaseJob = data.firebaseJob;
        return GestureDetector(
          onTap: () => AppNavigation.openJobDetail(
            context,
            firebaseJob != null
                ? JobDetailData.fromJob(firebaseJob)
                : JobDetailData.fromJobListing(job),
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
                      imageIndex: job.imageIndex,
                      imageUrl: job.imageUrl,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      tooltip: saved ? 'Remove saved job' : 'Save job',
                      onPressed: firebaseJob == null
                          ? null
                          : () => context.read<AppState>().toggleSavedJob(
                              firebaseJob,
                            ),
                      icon: Icon(
                        saved ? Icons.favorite : Icons.favorite_border,
                        color: saved ? AppColors.primary : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(job.details, style: context.bodyMedium),
                        Text(job.location, style: context.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
