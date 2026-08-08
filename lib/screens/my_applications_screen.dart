import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/youtube_shorts_player.dart';
import 'job_detail_screen.dart';

class MyApplicationsScreen extends StatelessWidget {
  const MyApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final applications = state.applications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Applications'),
      ),
      body: applications.isEmpty
          ? const EmptyState(
              icon: Icons.work_off_outlined,
              title: 'No applications yet',
              subtitle: 'Apply to jobs from the Jobs tab',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: applications.length,
              itemBuilder: (context, index) {
                final app = applications[index];
                final statusColor = _statusColor(app.status);
                final jobMatch = state.jobs.where((j) => j.id == app.jobId);
                final Job? job = jobMatch.isEmpty ? null : jobMatch.first;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: job == null
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => JobDetailScreen(job: job),
                              ),
                            );
                          },
                    onLongPress: () => _showWithdrawDialog(context, app.jobId),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                backgroundColor: statusColor.withAlpha(40),
                                child: Icon(_statusIcon(app.status), color: statusColor),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      app.jobTitle,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      app.company.isNotEmpty
                                          ? app.company
                                          : 'Agency',
                                      style: TextStyle(
                                        color: context.colors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Applied: ${app.appliedDate}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withAlpha(30),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  app.statusDisplay,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (app.videoUrl.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            InkWell(
                              onTap: () => launchExternalUrl(
                                app.videoUrl,
                                context: context,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.play_circle_fill,
                                    size: 18,
                                    color: context.colors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'View audition Short',
                                    style: TextStyle(
                                      color: context.colors.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (app.recruiterNote.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.border.withAlpha(70),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Agency note: ${app.recruiterNote}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Text(
                                'Long-press to withdraw',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const Spacer(),
                              if (app.status != ApplicationStatus.withdrawn && app.status != ApplicationStatus.rejected)
                                TextButton.icon(
                                  onPressed: () => _showEditDialog(context, app),
                                  icon: const Icon(Icons.edit, size: 14),
                                  label: const Text('Edit', style: TextStyle(fontSize: 12)),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Color _statusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.selected:
        return AppColors.success;
      case ApplicationStatus.rejected:
        return AppColors.error;
      case ApplicationStatus.shortlisted:
      case ApplicationStatus.interview:
        return AppColors.info;
      default:
        return AppColors.tertiary;
    }
  }

  IconData _statusIcon(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.selected:
        return Icons.check_circle;
      case ApplicationStatus.rejected:
        return Icons.cancel;
      case ApplicationStatus.shortlisted:
      case ApplicationStatus.interview:
        return Icons.visibility;
      default:
        return Icons.hourglass_empty;
    }
  }

  void _showWithdrawDialog(BuildContext context, String jobId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Withdraw Application'),
        content: const Text('Are you sure you want to withdraw this application?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<AppState>().withdrawApplication(jobId);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Application withdrawn')),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, Application app) {
    final scriptController = TextEditingController(text: app.script);
    final videoController = TextEditingController(text: app.videoUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: videoController,
              decoration: const InputDecoration(
                labelText: 'Audition Video URL',
                hintText: 'https://youtube.com/shorts/...',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: scriptController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Cover Letter / Script',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<AppState>().updateApplication(
                app.id,
                script: scriptController.text.trim(),
                videoUrl: videoController.text.trim(),
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Application updated')),
              );
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}
