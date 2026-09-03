import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/navigation/app_navigation.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_screen_layout.dart';
import 'package:bombay_casting/core/widgets/app_search_filters.dart';
import 'package:bombay_casting/features/jobs/screens/preference_filter_screen.dart';
import 'package:bombay_casting/features/jobs/widgets/job_card.dart';
import 'package:bombay_casting/features/jobs/widgets/profile_completion_banner.dart';
import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  final _searchController = TextEditingController();
  String _lastSyncedSearchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _syncSearchField(String query) {
    if (_lastSyncedSearchQuery == query) return;
    _lastSyncedSearchQuery = query;
    if (_searchController.text == query) return;
    _searchController.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final jobs = appState.filteredJobListings;
    final l10n = AppLocalizations.of(context)!;
    final completionPercent = appState.profile?.completionPercentage ?? 20;

    _syncSearchField(appState.jobFilter.searchQuery);

    final Widget empty;
    final noMatches =
        appState.jobFilter.isActive ||
        (appState.jobs.isNotEmpty && jobs.isEmpty);
    if (noMatches) {
      empty = Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 8),
        child: Text(
          l10n.noJobsMatchYourFiltersPullToRefreshOrChangeFilters,
          style: context.bodyMedium,
        ),
      );
    } else {
      empty = Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Text(
          l10n.noJobsYetPullDownToRefresh,
          style: context.bodyMedium,
        ),
      );
    }

    return AppScreenLayout(
      title: l10n.navJobs,
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
      body: AppRefreshScrollBody(
        onRefresh: () => context.read<AppState>().refreshJobs(),
        onLoadMore: () => context.read<AppState>().loadMoreJobs(),
        isLoadingMore: appState.isLoadingMoreJobs,
        hasMore: appState.hasMoreJobs,
        header: [
          if (completionPercent < 100) ...[
            ProfileCompletionBanner(percentage: completionPercent),
            const SizedBox(height: AppSpacing.md),
          ],
          AppSearchField(
            controller: _searchController,
            hintText: l10n.searchJobsAgencyLocation,
            onChanged: (query) {
              _lastSyncedSearchQuery = query;
              context.read<AppState>().setJobFilter(
                appState.jobFilter.copyWith(searchQuery: query),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          const AppSectionTitle('Jobs for you'),
        ],
        empty: empty,
        itemCount: jobs.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < jobs.length - 1 ? AppSpacing.lg : 0,
            ),
            child: JobCard(job: jobs[index]),
          );
        },
      ),
    );
  }
}
