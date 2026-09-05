import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/navigation/app_navigation.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_screen_layout.dart';
import 'package:bombay_casting/core/widgets/app_search_filters.dart';
import 'package:bombay_casting/core/widgets/app_tab_bar.dart';
import 'package:bombay_casting/core/widgets/option_picker.dart';
import 'package:bombay_casting/features/jobs/screens/applied_jobs_screen.dart';
import 'package:bombay_casting/features/jobs/screens/preference_filter_screen.dart';
import 'package:bombay_casting/features/jobs/screens/saved_jobs_screen.dart';
import 'package:bombay_casting/features/jobs/widgets/job_card.dart';
import 'package:bombay_casting/features/jobs/widgets/profile_completion_banner.dart';
import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class JobsScreen extends StatelessWidget {
  const JobsScreen({super.key});

  List<AppTabItem> _tabs(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      AppTabItem(label: l10n.all, indicatorWidth: 24),
      AppTabItem(label: l10n.saved, indicatorWidth: 40),
      AppTabItem(label: l10n.appliedJobs, indicatorWidth: 48),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final selectedTab = context.watch<AppState>().jobsInnerTabIndex;
    final isAll = selectedTab == 0;
    return AppScreenLayout(
      showAppBar: !isAll,
      tabs: isAll ? null : _tabs(context),
      selectedTabIndex: selectedTab,
      onTabChanged: (i) => context.read<AppState>().setJobsInnerTab(i),
      innerTabKey: selectedTab,
      body: switch (selectedTab) {
        0 => SafeArea(
            bottom: false,
            child: _JobsAllTab(tabs: _tabs(context)),
          ),
        1 => const SavedJobsTabContent(),
        _ => const AppliedJobsTabContent(),
      },
    );
  }
}

class _JobsAllTab extends StatefulWidget {
  const _JobsAllTab({required this.tabs});

  final List<AppTabItem> tabs;

  @override
  State<_JobsAllTab> createState() => _JobsAllTabState();
}

class _JobsAllTabState extends State<_JobsAllTab> {
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

  void _toggleCategoryChip(BuildContext context, String label) {
    final l10n = AppLocalizations.of(context)!;
    final appState = context.read<AppState>();
    final current = Set<String>.from(appState.jobFilter.categories);

    if (label == l10n.all ||
        label.toLowerCase() == 'all' ||
        label.toLowerCase() == 'any') {
      appState.setJobFilter(
        appState.jobFilter.copyWith(categories: {'Any'}),
      );
      return;
    }

    current.remove('Any');
    current.remove('All');
    current.remove(l10n.all);
    if (current.contains(label)) {
      current.remove(label);
    } else {
      current.add(label);
    }
    if (current.isEmpty) {
      current.add('Any');
    }
    appState.setJobFilter(
      appState.jobFilter.copyWith(categories: current),
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

    const searchPadding = EdgeInsets.fromLTRB(
      AppSpacing.screenH,
      4,
      AppSpacing.screenH,
      8,
    );
    return AppRefreshScrollBody(
      onRefresh: () => context.read<AppState>().refreshJobs(),
      onLoadMore: () => context.read<AppState>().loadMoreJobs(),
      isLoadingMore: appState.isLoadingMoreJobs,
      hasMore: appState.hasMoreJobs,
      leading: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH,
            0,
            AppSpacing.screenH,
            0,
          ),
          child: AppTabBar(
            tabs: widget.tabs,
            selectedIndex: 0,
            onChanged: (i) => context.read<AppState>().setJobsInnerTab(i),
          ),
        ),
      ],
      pinnedHeaderExtent: AppSearchAndChips.heightFor(searchPadding),
      pinnedHeader: AppSearchAndChips(
        padding: searchPadding,
        searchController: _searchController,
        searchHint: l10n.searchJobsAgencyLocation,
        chipOptions: [
          l10n.all,
          ...ProfileOptions.talentCategories,
        ],
        selectedChips: appState.jobFilter.categories,
        onSearchChanged: (query) {
          _lastSyncedSearchQuery = query;
          context.read<AppState>().setJobFilter(
            appState.jobFilter.copyWith(searchQuery: query),
          );
        },
        onChipToggled: (label) => _toggleCategoryChip(context, label),
        onFilterTap: () =>
            AppNavigation.push(context, const PreferenceScreen()),
      ),
      header: [
        if (completionPercent < 100) ...[
          ProfileCompletionBanner(percentage: completionPercent),
          const SizedBox(height: AppSpacing.md),
        ],
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
    );
  }
}
