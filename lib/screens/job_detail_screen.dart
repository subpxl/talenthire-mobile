import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_avatar.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_tag.dart';
import '../widgets/payment_dialog.dart';
import '../widgets/youtube_shorts_player.dart';
import '../widgets/app_bottom_nav_bar.dart';
import 'agency_detail_screen.dart';
import 'main_screen.dart';

class JobDetailScreen extends StatefulWidget {
  final Job job;

  const JobDetailScreen({super.key, required this.job});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  bool _isApplying = false;

  void _openAgency() {
    final job = widget.job;
    if (job.createdBy.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agency profile unavailable for this job')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AgencyDetailScreen(
          agencyId: job.createdBy,
          fallbackName: job.company,
        ),
      ),
    );
  }

  Future<void> _startApply(AppState state) async {
    if (!state.canApplyToJob()) {
      final blockedReason = state.getApplyBlockedReason();
      if (blockedReason != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(blockedReason),
            action: SnackBarAction(
              label: 'Upgrade',
              onPressed: () {
                PaymentDialog.show(
                  context,
                  title: 'Upgrade to Premium',
                  description: 'Apply to unlimited jobs and get verified.',
                  amount: AppPricing.premiumUpgrade,
                  icon: Icons.star,
                  accentColor: AppColors.tertiary,
                  onPay: () async {
                    final success = await state.upgradeToPremium();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success ? 'Upgraded to Premium!' : 'Payment failed',
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        );
      }
      return;
    }

    final result = await showModalBottomSheet<_ApplyResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ApplySheet(job: widget.job),
    );

    if (result == null || !mounted) return;
    await _submitApplication(
      state,
      result.script,
      videoUrl: result.videoUrl,
    );
  }

  Future<void> _submitApplication(
    AppState state,
    String script, {
    String videoUrl = '',
  }) async {
    setState(() => _isApplying = true);
    final success = await state.applyToJob(
      widget.job,
      script: script,
      videoUrl: videoUrl,
    );
    if (!mounted) return;
    setState(() => _isApplying = false);

    if (success) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: Icon(Icons.check_circle, color: AppColors.success, size: 40),
          title: const Text('Application sent'),
          content: Text(
            widget.job.isAudition
                ? 'Your audition Short was submitted. The agency can review it and update your status.'
                : 'Your application was submitted. You can track status under My Applications.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not submit application. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final job = widget.job;
    final hasApplied = state.hasApplied(job.id);
    final application = state.getApplicationForJob(job.id);
    final isSaved = state.isJobSaved(job.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
        actions: [
          IconButton(
            icon: Icon(
              isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: isSaved ? context.colors.primary : null,
            ),
            onPressed: () {
              state.toggleSavedJob(job);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isSaved ? 'Removed from saved jobs' : 'Job saved!',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: _openAgency,
                  child: AppAvatar(
                    radius: 32,
                    initials: job.initials.isNotEmpty ? job.initials : 'AG',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        style: context.text.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: _openAgency,
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                job.company.isNotEmpty
                                    ? job.company
                                    : 'View Agency',
                                style: context.text.titleMedium?.copyWith(
                                  color: context.colors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 12,
                              color: context.colors.primary,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        job.timeAgo,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _InfoTile(
                  icon: Icons.attach_money,
                  value: job.salary.isNotEmpty ? job.salary : 'Not listed',
                  label: 'Salary',
                ),
                _InfoTile(
                  icon: Icons.location_on_outlined,
                  value: job.location.isNotEmpty ? job.location : 'Remote',
                  label: 'Location',
                ),
                _InfoTile(
                  icon: Icons.public,
                  value: locationTypeToString(job.locationType).toUpperCase(),
                  label: 'Type',
                ),
              ],
            ),
            if (job.isAudition) ...[
              const SizedBox(height: 16),
              AppCard(
                color: context.colors.secondaryContainer.withAlpha(140),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.videocam, color: context.colors.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'Video audition required',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Record a YouTube Short reading the script below, then paste the Short link when you apply.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    if (job.auditionScript.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(160),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Script to read',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                                const Spacer(),
                                TextButton.icon(
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: job.auditionScript),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Script copied'),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.copy, size: 14),
                                  label: const Text('Copy'),
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              job.auditionScript,
                              style: const TextStyle(height: 1.45, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Job Description',
              style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(job.description, style: const TextStyle(height: 1.5)),
            if (job.requirements.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Requirements',
                style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(job.requirements, style: const TextStyle(height: 1.5)),
            ],
            if (job.ageMin != null ||
                job.ageMax != null ||
                job.genderRequired.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Role criteria',
                style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (job.ageMin != null || job.ageMax != null)
                    AppTag(
                      label: job.ageMin != null && job.ageMax != null
                          ? 'Age ${job.ageMin}-${job.ageMax}'
                          : job.ageMin != null
                              ? 'Age ${job.ageMin}+'
                              : 'Up to age ${job.ageMax}',
                    ),
                  if (job.genderRequired.isNotEmpty)
                    AppTag(label: job.genderRequired),
                ],
              ),
            ],
            if (job.interviewVideoLink.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Interview reference',
                style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => launchExternalUrl(job.interviewVideoLink, context: context),
                child: Row(
                  children: [
                    Icon(Icons.play_circle_outline, color: context.colors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Watch briefing / sample Short',
                        style: TextStyle(color: context.colors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (job.tags.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Tags',
                style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: job.tags.map((tag) => AppTag(label: tag)).toList(),
              ),
            ],
            if (hasApplied && application != null) ...[
              const SizedBox(height: 24),
              AppCard(
                color: context.colors.primaryContainer.withAlpha(90),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: context.colors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Status: ${application.statusDisplay}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Applied on ${application.appliedDate}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    if (application.videoUrl.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () => launchExternalUrl(
                          application.videoUrl,
                          context: context,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.play_circle_outline,
                                color: context.colors.primary, size: 20),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Your audition Short',
                                style: TextStyle(
                                  color: context.colors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (application.script.isNotEmpty &&
                        extractYoutubeId(application.script) == null) ...[
                      const SizedBox(height: 10),
                      Text(
                        application.script,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (application.recruiterNote.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(140),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Agency note: ${application.recruiterNote}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: AppButton(
                label: hasApplied
                    ? 'Applied · ${application?.statusDisplay ?? 'Pending'}'
                    : (job.isAudition ? 'Submit Audition Short' : 'Apply Now'),
                isLoading: _isApplying,
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                onPressed: hasApplied ? null : () => _startApply(state),
              ),
            ),
          ),
          AppBottomNavBar(
            selectedIndex: MainScreen.mainKey.currentState?.selectedIndex ?? 0,
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _InfoTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.border.withAlpha(80),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplyResult {
  final String script;
  final String videoUrl;
  const _ApplyResult({required this.script, required this.videoUrl});
}

class _ApplySheet extends StatefulWidget {
  final Job job;
  const _ApplySheet({required this.job});

  @override
  State<_ApplySheet> createState() => _ApplySheetState();
}

class _ApplySheetState extends State<_ApplySheet> {
  final _scriptController = TextEditingController();
  final _videoController = TextEditingController();
  String? _videoError;

  @override
  void dispose() {
    _scriptController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  void _submit() {
    final isAudition = widget.job.isAudition;
    final videoUrl = _videoController.text.trim();

    if (isAudition) {
      if (videoUrl.isEmpty) {
        setState(() => _videoError = 'Paste your YouTube Short link');
        return;
      }
      if (extractYoutubeId(videoUrl) == null) {
        setState(
          () => _videoError = 'Enter a valid YouTube / Shorts link',
        );
        return;
      }
    }

    Navigator.pop(
      context,
      _ApplyResult(
        script: _scriptController.text.trim(),
        videoUrl: videoUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              job.isAudition ? 'Submit audition' : 'Apply to job',
              style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              job.title,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            if (job.isAudition) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.colors.primaryContainer.withAlpha(80),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How to submit',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '1. Record a YouTube Short reading the script\n'
                      '2. Upload it publicly (or unlisted) on YouTube\n'
                      '3. Paste the Short link below',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                    if (job.auditionScript.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'Script',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(job.auditionScript, style: const TextStyle(height: 1.4)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _videoController,
                onChanged: (_) => setState(() => _videoError = null),
                decoration: InputDecoration(
                  labelText: 'YouTube Short link *',
                  hintText: 'https://youtube.com/shorts/...',
                  errorText: _videoError,
                  prefixIcon: const Icon(Icons.link),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (_videoController.text.trim().isNotEmpty &&
                  extractYoutubeId(_videoController.text.trim()) != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: AppColors.success),
                    const SizedBox(width: 6),
                    const Text(
                      'Valid YouTube link detected',
                      style: TextStyle(color: AppColors.success, fontSize: 12),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              const Text('Cover letter (optional)'),
            ] else
              const Text('Cover letter / note (optional)'),
            const SizedBox(height: 8),
            TextField(
              controller: _scriptController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Why are you a good fit?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    job.isAudition ? 'Submit audition' : 'Submit application',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
