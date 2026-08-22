import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/data/job_assets.dart';
import 'package:bombay_casting/navigation/app_navigation.dart';
import 'package:bombay_casting/providers/app_state.dart';
import 'package:bombay_casting/screens/preferencerhomepagefilter.dart';
import 'package:bombay_casting/screens/shortlisted.dart';
import 'package:bombay_casting/screens/job_detail_screen.dart';
import 'package:bombay_casting/theme/app_theme.dart';
import 'package:bombay_casting/widgets/app_screen_layout.dart';
import 'package:bombay_casting/widgets/app_tab_bar.dart';
import 'package:bombay_casting/widgets/placeholder_avatar.dart';
import 'package:bombay_casting/widgets/promo_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedHomeTab = 0;

  static const _tabs = [
    AppTabItem(label: 'All', indicatorWidth: 24),
    AppTabItem(label: 'Saved', indicatorWidth: 40),
  ];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return AppScreenLayout(
      tabs: _tabs,
      selectedTabIndex: _selectedHomeTab,
      onTabChanged: (i) => setState(() => _selectedHomeTab = i),
      innerTabKey: _selectedHomeTab,
      actions: [
        IconButton(
          tooltip: 'Filters',
          icon: Icon(
            appState.jobFilter.isActive
                ? Icons.filter_alt
                : Icons.filter_alt_outlined,
          ),
          color: appState.jobFilter.isActive
              ? AppColors.primary
              : AppColors.textSecondary,
          onPressed: () => AppNavigation.push(context, const PreferenceScreen()),
        ),
      ],
      body: _selectedHomeTab == 0
          ? _buildAllTab(appState.filteredJobListings)
          : const ShortlistTabContent(),
    );
  }

  Widget _buildAllTab(List<JobListing> homeJobs) {
    final appState = context.watch<AppState>();
    final Widget empty;
    if (appState.isLoadingJobs && appState.jobs.isEmpty) {
      empty = const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    } else if (appState.jobFilter.isActive) {
      empty = Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Text(
          'No jobs match your filters. Pull to refresh or change filters.',
          style: context.bodyMedium,
        ),
      );
    } else {
      empty = Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Text(
          'No jobs yet. Pull down to refresh.',
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
        PromoBanner(
          title: 'Premium applications',
          subtitle: 'Subscribe to apply and land your next collab',
          actionLabel: 'See plans',
          onAction: () => AppNavigation.openPremiumScreen(context),
        ),
        const SizedBox(height: AppSpacing.lg),
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
    final appState = context.watch<AppState>();
    final firebaseJob = appState.jobById(job.jobId);
    final saved = job.jobId.isNotEmpty && appState.isJobSaved(job.jobId);
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
                      : () => appState.toggleSavedJob(firebaseJob),
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
              Row(
                children: [
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
        ],
      ),
    );
  }
}
