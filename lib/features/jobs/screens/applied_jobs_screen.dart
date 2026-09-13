import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/models/models.dart';
import 'package:bombay_casting/core/navigation/app_navigation.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/utils/app_links.dart';
import 'package:bombay_casting/core/widgets/app_screen_layout.dart';
import 'package:bombay_casting/features/jobs/screens/job_detail_screen.dart';
import 'package:bombay_casting/features/jobs/widgets/application_analytics_summary.dart';
import 'package:bombay_casting/features/jobs/widgets/application_progress_tracker.dart';
import 'package:bombay_casting/features/jobs/widgets/manage_application_sheet.dart';
import 'package:bombay_casting/features/jobs/widgets/profile_completion_banner.dart';
import 'package:bombay_casting/core/widgets/app_network_image.dart';
import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AppliedJobsTabContent extends StatelessWidget {
  const AppliedJobsTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final applications = [...appState.applications]
      ..sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
    final completionPercent = appState.profile?.completionPercentage ?? 0;
    final profileBanner = completionPercent < 100
        ? <Widget>[
            ProfileCompletionBanner(percentage: completionPercent),
            const SizedBox(height: AppSpacing.md),
          ]
        : const <Widget>[];

    if (applications.isEmpty) {
      return AppScrollBody(
        onRefresh: () => context.read<AppState>().refreshApplications(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...profileBanner,
            ApplicationAnalyticsSummary(applications: applications),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppLocalizations.of(context)!.noAppliedJobsYet,
              style: context.bodyMedium,
            ),
          ],
        ),
      );
    }

    return AppRefreshScrollBody(
      onRefresh: () => context.read<AppState>().refreshApplications(),
      header: [
        ...profileBanner,
        ApplicationAnalyticsSummary(applications: applications),
        const SizedBox(height: AppSpacing.md),
        const AppSectionTitle('Applied'),
      ],
      itemCount: applications.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < applications.length - 1 ? AppSpacing.md : 0,
          ),
          child: _AppliedJobCard(
            key: ValueKey(applications[index].jobId),
            application: applications[index],
          ),
        );
      },
    );
  }
}

class _AppliedJobCard extends StatelessWidget {
  const _AppliedJobCard({super.key, required this.application});

  final Application application;

  String _subtitle() {
    final date = DateFormat('d MMM yyyy').format(application.appliedAt);
    if (application.company.trim().isEmpty) return 'Applied on $date';
    return '${application.company} · Applied on $date';
  }

  bool get _canManage {
    return application.status != ApplicationStatus.rejected &&
        application.status != ApplicationStatus.selected &&
        application.status != ApplicationStatus.withdrawn;
  }

  void _openJob(BuildContext context) {
    final job = context.read<AppState>().jobById(application.jobId);
    if (job == null) return;
    AppNavigation.openJobDetail(context, JobDetailData.fromJob(job));
  }

  @override
  Widget build(BuildContext context) {
    final job = context.watch<AppState>().jobById(application.jobId);
    final posterUrl = job?.imageUrl.trim() ?? '';
    final shortUrl = application.youtubeShortUrl.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => _openJob(context),
                      child: Text(
                        application.jobTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitle(),
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _JobPoster(
                imageUrl: posterUrl,
                onTap: shortUrl.isNotEmpty
                    ? () => openAppLink(context, shortUrl)
                    : () => _openJob(context),
                showPlay: shortUrl.isNotEmpty,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ApplicationProgressTracker(application: application),
          if (_canManage) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                _TextAction(
                  label: 'Cancel',
                  onTap: () => confirmAndCancelApplication(
                    context,
                    application: application,
                  ),
                ),
                if (job?.requiresVideoSubmission == true) ...[
                  Container(
                    width: 1,
                    height: 12,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    color: AppColors.border,
                  ),
                  _TextAction(
                    label: 'Update',
                    onTap: () => updateApplicationInterviewLink(
                      context,
                      application: application,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TextAction extends StatelessWidget {
  const _TextAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _JobPoster extends StatelessWidget {
  const _JobPoster({
    required this.imageUrl,
    required this.onTap,
    required this.showPlay,
  });

  final String imageUrl;
  final VoidCallback onTap;
  final bool showPlay;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 56,
          height: 72,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl.isNotEmpty)
                AppNetworkImage(
                  imageUrl: imageUrl,
                  variant: AppImageVariant.thumb,
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 200),
                  progressIndicatorBuilder: (context, url, progress) =>
                      const ColoredBox(
                    color: Color(0xFFF3F3F3),
                  ),
                  errorWidget: (context, url, error) => const _PosterFallback(),
                )
              else
                const _PosterFallback(),
              if (showPlay)
                const Center(
                  child: Icon(
                    Icons.play_circle_fill,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PosterFallback extends StatelessWidget {
  const _PosterFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFF3F3F3),
      child: Icon(
        Icons.movie_filter_outlined,
        size: 22,
        color: AppColors.textHint,
      ),
    );
  }
}
