import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/data/job_assets.dart';
import 'package:bombay_casting/navigation/app_navigation.dart';
import 'package:bombay_casting/providers/app_state.dart';
import 'package:bombay_casting/screens/job_detail_screen.dart';
import 'package:bombay_casting/theme/app_theme.dart';
import 'package:bombay_casting/widgets/app_screen_layout.dart';
import 'package:bombay_casting/widgets/profile_list_tile.dart';
import 'package:bombay_casting/widgets/promo_banner.dart';

class MessagesListScreen extends StatelessWidget {
  const MessagesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final recentJobs = listingsForJobs(appState.jobs);
    return AppScreenLayout(
      title: 'Jobs',
      body: AppRefreshScrollBody(
        padding: EdgeInsets.zero,
        onRefresh: () => context.read<AppState>().refreshJobs(),
        onLoadMore: () => context.read<AppState>().loadMoreJobs(),
        isLoadingMore: appState.isLoadingMoreJobs,
        hasMore: appState.hasMoreJobs,
        header: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenH),
            child: PromoBanner(
              title: 'Premium applications',
              subtitle: 'Subscribe to apply and land your next collab',
              actionLabel: 'Apply now',
              onAction: () {
                if (!AppNavigation.requireSubscription(context)) return;
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
            child: AppSectionTitle('Jobs for you'),
          ),
        ],
        empty: appState.isLoadingJobs && recentJobs.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenH,
                ),
                child: Text(
                  'No jobs yet. Pull down to refresh.',
                  style: context.bodyMedium,
                ),
              ),
        itemCount: recentJobs.length,
        itemBuilder: (context, index) {
          final item = recentJobs[index];
          return Column(
            children: [
              ProfileListTile(
                name: item.title,
                subtitle: item.seenStatus,
                avatarColor: item.avatarColor,
                imageIndex: item.imageIndex,
                imageUrl: item.imageUrl,
                showVerified: item.isVerified,
                trailing: IconButton(
                  tooltip: 'More options',
                  icon: Icon(
                    Icons.more_vert,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () {},
                ),
                onTap: () {
                  AppNavigation.openJobDetail(
                    context,
                    JobDetailData.fromJobListing(item),
                  );
                },
              ),
              if (index < recentJobs.length - 1)
                const Divider(
                  indent: 72,
                  endIndent: AppSpacing.screenH,
                ),
            ],
          );
        },
      ),
    );
  }
}
