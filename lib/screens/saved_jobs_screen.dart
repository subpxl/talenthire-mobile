import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_avatar.dart';
import '../widgets/empty_state.dart';
import 'job_detail_screen.dart';

class SavedJobsScreen extends StatelessWidget {
  const SavedJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final savedJobs = state.savedJobs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Jobs'),
      ),
      body: savedJobs.isEmpty
          ? const EmptyState(
              icon: Icons.bookmark_border,
              title: 'No saved jobs',
              subtitle: 'Save jobs from the Jobs tab to view them here',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: savedJobs.length,
              itemBuilder: (context, index) {
                final job = savedJobs[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => JobDetailScreen(job: job),
                        ),
                      );
                    },
                    leading: AppAvatar(
                      initials: job.initials,
                    ),
                    title: Text(
                      job.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(job.company),
                        const SizedBox(height: 4),
                        Text(
                          job.salary,
                          style: TextStyle(
                            color: context.colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.bookmark_remove, color: AppColors.error),
                      onPressed: () {
                        state.toggleSavedJob(job);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Job removed from saved')),
                        );
                      },
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}
