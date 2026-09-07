import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/models/models.dart';
import 'package:bombay_casting/core/navigation/app_navigation.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/placeholder_avatar.dart';
import 'package:bombay_casting/features/jobs/models/job_listing.dart';
import 'package:bombay_casting/features/jobs/screens/job_detail_screen.dart';
import 'package:bombay_casting/features/jobs/widgets/job_highlights_row.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class JobCard extends StatelessWidget {
  const JobCard({super.key, required this.job});

  final JobListing job;

  @override
  Widget build(BuildContext context) {
    return Selector<AppState, ({bool saved, Job? firebaseJob})>(
      selector: (_, state) => (
        saved: job.jobId.isNotEmpty && state.isJobSaved(job.jobId),
        firebaseJob: state.jobById(job.jobId),
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
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.md),
                  ),
                  child: PlaceholderProfileImage(
                    aspectRatio: 0.9,
                    borderRadius: 0,
                    imageIndex: job.imageIndex,
                    imageUrl: job.imageUrl,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              titleCaseWords(job.title),
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
                          IconButton(
                            tooltip: saved ? 'Remove saved job' : 'Save job',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                            onPressed: firebaseJob == null
                                ? null
                                : () => context.read<AppState>().toggleSavedJob(
                                    firebaseJob,
                                  ),
                            icon: Icon(
                              saved ? Icons.favorite : Icons.favorite_border,
                              color: AppColors.brandRed,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      JobHighlightsRow(
                        job: job,
                        postedAt: firebaseJob?.postedAt,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: AppColors.brandRed,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'View details',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                letterSpacing: 0.1,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
