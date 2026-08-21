import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_tag.dart';
import 'main_screen.dart';
import 'edit_profile_screen.dart';
import 'my_applications_screen.dart';
import '../models/models.dart';
import 'agency_detail_screen.dart';
import 'job_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<AppState>().refreshData();
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Text(
              'Welcome, ${state.user?.name ?? "User"}!',
              style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Here is what is happening today.',
              style: context.text.bodyLarge?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),

            if (state.profile != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: state.profile!.isPremium
                      ? AppColors.tertiary.withAlpha(30)
                      : AppColors.divider,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      state.profile!.isPremium ? Icons.star : Icons.star_border,
                      size: 16,
                      color: state.profile!.isPremium ? AppColors.tertiary : AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      state.profile!.isPremium ? 'Premium Member' : 'Free Account',
                      style: TextStyle(
                        color: state.profile!.isPremium
                            ? const Color(0xFF92400E)
                            : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            if (state.profile != null && !state.profile!.profileCompleted) ...[
              AppCard(
                color: context.colors.primaryContainer.withAlpha(80),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                  );
                },
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: state.getProfileCompletionPercent() / 100,
                            strokeWidth: 4,
                            backgroundColor: AppColors.divider,
                            valueColor: AlwaysStoppedAnimation(context.colors.primary),
                          ),
                          Center(
                            child: Text(
                              '${state.getProfileCompletionPercent()}%',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Complete your profile',
                            style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add photos & YouTube Shorts to stand out',
                            style: context.text.bodySmall?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: context.colors.primary),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],


            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recommended Jobs',
                  style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => MainScreen.switchTab(2),
                  child: const Text('See All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (state.jobs.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'No jobs available',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ...state.jobs.take(3).map((job) => _buildJobCard(context, job)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    Color? backgroundColor,
    required VoidCallback onTap,
  }) {
    return AppCard(
      onTap: onTap,
      color: backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface.withAlpha(180),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
          const Spacer(),
          Text(
            count,
            style: context.text.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: context.text.titleSmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, Job job) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => JobDetailScreen(job: job)),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  job.title,
                  style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (job.urgent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'URGENT',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              if (job.createdBy.isEmpty) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AgencyDetailScreen(
                    agencyId: job.createdBy,
                    fallbackName: job.company,
                  ),
                ),
              );
            },
            child: Text(
              job.company.isNotEmpty ? job.company : 'Agency',
              style: context.text.titleMedium?.copyWith(
                color: context.colors.primary,
                decoration:
                    job.createdBy.isNotEmpty ? TextDecoration.underline : TextDecoration.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(job.location, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(width: 12),
              Icon(Icons.public, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                locationTypeToString(job.locationType).toUpperCase(),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          if (job.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: job.tags.map((tag) => AppTag(label: tag)).toList(),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                job.salary.isNotEmpty ? job.salary : 'Salary not listed',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Text(
                '${job.applied} applicants',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
