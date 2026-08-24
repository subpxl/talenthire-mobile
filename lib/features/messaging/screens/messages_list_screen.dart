import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/features/jobs/models/job_listing.dart';
import 'package:bombay_casting/core/navigation/app_navigation.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/features/jobs/screens/job_detail_screen.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_screen_layout.dart';
import 'package:bombay_casting/core/widgets/profile_list_tile.dart';
import 'package:bombay_casting/core/widgets/promo_banner.dart';

class MessagesListScreen extends StatelessWidget {
  const MessagesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final recentJobs = listingsForJobs(appState.jobs);
    return AppScreenLayout(
      title: AppLocalizations.of(context)!.navJobs,
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
              title: AppLocalizations.of(context)!.premiumApplications,
              subtitle: AppLocalizations.of(context)!.subscribeToApply,
              actionLabel: AppLocalizations.of(context)!.applyNow,
              onAction: () {
                if (!AppNavigation.requireSubscription(context)) return;
              },
            ),
          ),
          Padding(padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 8), child: Text(AppLocalizations.of(context)!.noJobsYetPullDownToRefresh,
                  style: context.bodyMedium,
                ),
              ),
        ],
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
                  final firebaseJob = appState.jobById(item.jobId);
                  AppNavigation.openJobDetail(
                    context,
                    firebaseJob != null
                        ? JobDetailData.fromJob(firebaseJob)
                        : JobDetailData.fromJobListing(item),
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
