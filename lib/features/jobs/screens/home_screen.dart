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
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_screen_layout.dart';
import 'package:bombay_casting/core/widgets/app_search_filters.dart';
import 'package:bombay_casting/core/widgets/app_tab_bar.dart';
import 'package:bombay_casting/core/widgets/placeholder_avatar.dart';
import 'package:bombay_casting/core/widgets/promo_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedHomeTab = 0;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AppTabItem> _getTabs(BuildContext context) {
    return [
      AppTabItem(label: AppLocalizations.of(context)!.all, indicatorWidth: 24),
      AppTabItem(label: AppLocalizations.of(context)!.saved, indicatorWidth: 40),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return AppScreenLayout(
      tabs: _getTabs(context),
      selectedTabIndex: _selectedHomeTab,
      onTabChanged: (i) => setState(() => _selectedHomeTab = i),
      innerTabKey: _selectedHomeTab,
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
          onPressed: () => AppNavigation.push(context, const PreferenceScreen()),
        ),
      ],
      body: _selectedHomeTab == 0
          ? Column(
              children: [
                AppSearchAndChips(
                  searchController: _searchController,
                  searchHint: AppLocalizations.of(context)!
                      .searchJobsAgencyLocation,
                  chipOptions: [
                    AppLocalizations.of(context)!.all,
                    AppLocalizations.of(context)!.remote,
                    AppLocalizations.of(context)!.online,
                    AppLocalizations.of(context)!.onsite,
                  ],
                  selectedChip: _workModeLabel(context, appState.jobFilter.workMode),
                  onSearchChanged: (query) {
                    context.read<AppState>().setJobFilter(
                          appState.jobFilter.copyWith(searchQuery: query),
                        );
                  },
                  onChipSelected: (label) {
                    context.read<AppState>().setJobFilter(
                          appState.jobFilter.copyWith(
                            workMode: _workModeValue(context, label),
                          ),
                        );
                  },
                ),
                Expanded(child: _buildAllTab(appState)),
              ],
            )
          : const ShortlistTabContent(),
    );
  }

  String _workModeLabel(BuildContext context, String workMode) {
    final l10n = AppLocalizations.of(context)!;
    switch (workMode) {
      case 'Remote':
        return l10n.remote;
      case 'Online':
        return l10n.online;
      case 'Onsite':
        return l10n.onsite;
      default:
        return l10n.all;
    }
  }

  String _workModeValue(BuildContext context, String label) {
    final l10n = AppLocalizations.of(context)!;
    if (label == l10n.remote) return 'Remote';
    if (label == l10n.online) return 'Online';
    if (label == l10n.onsite) return 'Onsite';
    return 'All';
  }

  Widget _buildAllTab(AppState appState) {
    final homeJobs = appState.filteredJobListings;
    final Widget empty;
    final noMatches = appState.jobFilter.isActive ||
        (appState.jobs.isNotEmpty && homeJobs.isEmpty);
    if (noMatches) {
      empty = Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 8),
        child: Text(
          AppLocalizations.of(context)!
              .noJobsMatchYourFiltersPullToRefreshOrChangeFilters,
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

    return AppRefreshScrollBody(
      onRefresh: () => context.read<AppState>().refreshJobs(),
      onLoadMore: () => context.read<AppState>().loadMoreJobs(),
      isLoadingMore: appState.isLoadingMoreJobs,
      hasMore: appState.hasMoreJobs,
      header: [
        if (!appState.isPremiumUser) ...[
          PromoBanner(
            title: AppLocalizations.of(context)!.premiumApplications,
            subtitle: AppLocalizations.of(context)!.subscribeToApply,
            actionLabel: AppLocalizations.of(context)!.seePlans,
            onAction: () => AppNavigation.openPremiumScreen(context),
          ),
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
        final isPremium = data.isPremium;
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
                          : () => context
                              .read<AppState>()
                              .toggleSavedJob(firebaseJob),
                      icon: Icon(
                        saved ? Icons.bookmark : Icons.bookmark_border,
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
                  if (!isPremium)
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Call',
                          icon: const Icon(Icons.phone_outlined),
                          color: AppColors.textSecondary,
                          onPressed: () =>
                              AppNavigation.openPremiumScreen(context),
                        ),
                        IconButton(
                          tooltip: 'Message',
                          icon: const Icon(Icons.chat_bubble_outline),
                          color: AppColors.chatGreen,
                          onPressed: () =>
                              AppNavigation.openPremiumScreen(context),
                        ),
                      ],
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
