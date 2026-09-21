import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/deep_links/deep_link_target.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_screen_layout.dart';
import 'package:bombay_casting/core/services/analytics_service.dart';
import 'package:bombay_casting/core/services/report_service.dart';
import 'package:bombay_casting/core/widgets/share_link_button.dart';
import 'package:bombay_casting/features/jobs/models/agency_profile.dart';
import 'package:bombay_casting/features/jobs/models/job_listing.dart';
import 'package:bombay_casting/features/jobs/widgets/agency_detail_sections.dart';
import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AgencyDetailScreen extends StatefulWidget {
  const AgencyDetailScreen({
    super.key,
    required this.agency,
  });

  final AgencyProfile agency;

  @override
  State<AgencyDetailScreen> createState() => _AgencyDetailScreenState();
}

class _AgencyDetailScreenState extends State<AgencyDetailScreen> {
  AgencyProfile get agency => widget.agency;

  @override
  void initState() {
    super.initState();
    if (agency.id.isNotEmpty) {
      AnalyticsService.instance.track(
        () => AnalyticsService.instance.logViewAgency(agencyId: agency.id),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final l10n = AppLocalizations.of(context)!;
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
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
                await _reportAgency(context);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'report',
                child: Text(l10n.reportAgency),
              ),
            ],
          ),
        ],
      ),
      body: AppScrollBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AgencyHeroCard(agency: agency),
            const SizedBox(height: AppSpacing.md),
            AgencyQuickInfoCards(agency: agency),
            const SizedBox(height: AppSpacing.lg),
            AgencyAboutSection(agency: agency),
            const SizedBox(height: AppSpacing.lg),
            AgencyDetailsCard(agency: agency),
            const SizedBox(height: AppSpacing.lg),
            AgencyJobsSection(
              agencyName: agency.name,
              listings: listings,
              emptyMessage: l10n.noJobsPostedYet,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reportAgency(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    await ReportService.instance.submitFromDialog(
      context,
      dialogTitle: l10n.reportAgency,
      successMessage: l10n.agencyReported,
      target: ReportTarget(
        type: ReportType.agency,
        targetId: agency.id,
        targetLabel: agency.name,
      ),
    );
  }
}
