import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/models/models.dart';
import 'package:bombay_casting/core/navigation/app_navigation.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/placeholder_avatar.dart';
import 'package:bombay_casting/features/jobs/models/job_listing.dart';
import 'package:bombay_casting/features/jobs/screens/job_detail_screen.dart';
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
        );
      },
    );
  }
}
