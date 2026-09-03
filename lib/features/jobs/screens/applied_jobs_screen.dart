import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/models/models.dart';
import 'package:bombay_casting/core/navigation/app_navigation.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_screen_layout.dart';
import 'package:bombay_casting/features/jobs/screens/job_detail_screen.dart';
import 'package:bombay_casting/features/jobs/widgets/application_progress_tracker.dart';
import 'package:bombay_casting/features/jobs/widgets/profile_completion_banner.dart';
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
    final completionPercent = appState.profile?.completionPercentage ?? 20;
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
        const AppSectionTitle('Your applications'),
      ],
      itemCount: applications.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < applications.length - 1 ? AppSpacing.md : 0,
          ),
          child: _AppliedJobCard(application: applications[index]),
        );
      },
    );
  }
}

class _AppliedJobCard extends StatelessWidget {
  const _AppliedJobCard({required this.application});

  final Application application;

  String _subtitle() {
    final date = DateFormat('d MMM yyyy').format(application.appliedAt);
    if (application.company.trim().isEmpty) return 'Applied on $date';
    return '${application.company} · Applied on $date';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final job = context.read<AppState>().jobById(application.jobId);
        if (job == null) return;
        AppNavigation.openJobDetail(context, JobDetailData.fromJob(job));
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              application.jobTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _subtitle(),
              style: context.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            ApplicationProgressTracker(application: application),
          ],
        ),
      ),
    );
  }
}
