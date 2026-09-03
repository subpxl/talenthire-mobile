import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/deep_links/deep_link_target.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_screen_layout.dart';
import 'package:bombay_casting/core/widgets/placeholder_avatar.dart';
import 'package:bombay_casting/core/widgets/report_dialog.dart';
import 'package:bombay_casting/core/widgets/share_link_button.dart';
import 'package:bombay_casting/features/jobs/models/agency_profile.dart';
import 'package:bombay_casting/features/jobs/models/job_listing.dart';
import 'package:bombay_casting/features/jobs/widgets/job_card.dart';
import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AgencyDetailScreen extends StatelessWidget {
  const AgencyDetailScreen({
    super.key,
    required this.agency,
  });

  final AgencyProfile agency;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final agencyJobs = AgencyProfile.jobsForAgency(
      appState.jobs,
      company: agency.name,
      createdBy: agency.createdBy,
    );
    final listings = [
      for (var i = 0; i < agencyJobs.length; i++)
        JobListing.fromJob(agencyJobs[i], i),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Agency',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          ShareLinkButton(
            url: DeepLinkTarget.agencyUrl(agency.id),
            message: 'Check out ${agency.name} on Bombay Casting Company',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'report') {
                final l10n = AppLocalizations.of(context)!;
                final result = await showReportDialog(
                  context,
                  title: l10n.reportAgency,
                );
                if (result != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.agencyReported)),
                  );
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'report',
                child: Text(AppLocalizations.of(context)!.reportAgency),
              ),
            ],
          ),
        ],
      ),
      body: AppScrollBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: PlaceholderProfileImage(
                aspectRatio: 0.85,
                imageIndex: agency.imageIndex,
                imageUrl: agency.imageUrl,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              agency.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (agency.isVerified) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.verified,
                              color: AppColors.chatGreen,
                              size: 18,
                            ),
                          ],
                        ],
                      ),
                      if (agency.jobCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Text(
                            '${agency.jobCount} open ${agency.jobCount == 1 ? 'job' : 'jobs'}',
                            style: context.caption,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth - 16) / 2;
                return Wrap(
                  spacing: 16,
                  runSpacing: 0,
                  children: [
                    if (agency.location.isNotEmpty)
                      SizedBox(
                        width: itemWidth,
                        child: _buildDetailRow(
                          'Location',
                          agency.location,
                          Icons.location_on_outlined,
                        ),
                      ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildDetailRow(
                        'Jobs posted',
                        '${agency.jobCount}',
                        Icons.work_outline,
                      ),
                    ),
                    if (agency.categories.isNotEmpty)
                      SizedBox(
                        width: itemWidth,
                        child: _buildDetailRow(
                          'Categories',
                          agency.categories.join(', '),
                          Icons.category_outlined,
                        ),
                      ),
                  ],
                );
              },
            ),
            if (agency.description.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              const AppSectionTitle('About'),
              const SizedBox(height: AppSpacing.sm),
              Text(
                agency.description,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppSectionTitle(
              'Jobs by ${agency.name}',
            ),
            const SizedBox(height: AppSpacing.sm),
            if (listings.isEmpty)
              Text(
                'No jobs posted yet.',
                style: context.bodyMedium,
              )
            else
              for (var i = 0; i < listings.length; i++) ...[
                JobCard(job: listings[i]),
                if (i < listings.length - 1)
                  const SizedBox(height: AppSpacing.lg),
              ],
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
