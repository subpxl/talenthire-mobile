import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/features/jobs/models/job_listing.dart';
import 'package:flutter/material.dart';

class JobHighlightsRow extends StatelessWidget {
  const JobHighlightsRow({
    super.key,
    required this.job,
    this.postedAt,
  });

  final JobListing job;
  final DateTime? postedAt;

  @override
  Widget build(BuildContext context) {
    final postedAt = this.postedAt ?? job.postedAt;
    final deadline = job.applicationDeadline;
    return IntrinsicHeight(
      child: Row(
        children: [
          _HighlightCell(
            icon: Icons.location_on_rounded,
            iconColor: AppColors.brandRed,
            label: _locationCopy(job),
            caption: _workCaption(job),
          ),
          const _HighlightDivider(),
          _HighlightCell(
            flex: 12,
            icon: Icons.currency_rupee_rounded,
            iconColor: const Color(0xFF2E7D32),
            label: jobPayCompactLabel(job),
          ),
          const _HighlightDivider(),
          _HighlightCell(
            icon: Icons.people_rounded,
            iconColor: const Color(0xFF7E57C2),
            label: _roleCopy(job),
          ),
          const _HighlightDivider(),
          _HighlightCell(
            icon: Icons.schedule_rounded,
            iconColor: const Color(0xFFC77800),
            label: postedAt != null
                ? jobApplyByLabel(postedAt, deadline: deadline)
                : _timingCopy(job),
            caption: postedAt != null
                ? jobDaysLeftLabel(postedAt, deadline: deadline)
                : '',
            captionColor: AppColors.brandRed,
          ),
        ],
      ),
    );
  }
}

class _HighlightDivider extends StatelessWidget {
  const _HighlightDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: VerticalDivider(
        width: 6,
        thickness: 1,
        color: AppColors.border,
      ),
    );
  }
}

class _HighlightCell extends StatelessWidget {
  const _HighlightCell({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.caption = '',
    this.captionColor = AppColors.textHint,
    this.flex = 10,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String caption;
  final Color captionColor;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Column(
        children: [
          Icon(icon, size: 21, color: iconColor),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.15,
                letterSpacing: -0.15,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (caption.isNotEmpty) ...[
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                caption,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: captionColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _workCaption(JobListing job) {
  final location = job.location.trim();
  if (location.isEmpty || isRemoteJobCity(location)) return '';
  return jobWorkTypeLabel(job);
}

String _locationCopy(JobListing job) {
  final location = job.location.trim();
  if (location.isEmpty || isRemoteJobCity(location)) {
    return jobWorkTypeLabel(job);
  }
  return shortJobCity(location);
}

String _roleCopy(JobListing job) {
  final type = jobArtistTypeLabel(job);
  if (type.isNotEmpty) return type;
  for (final tag in job.tags) {
    final value = tag.trim();
    if (value.isNotEmpty) return value;
  }
  return jobWorkTypeLabel(job);
}

String _timingCopy(JobListing job) {
  final seen = job.seenStatus.trim();
  if (seen.isEmpty) return 'Open now';
  return seen.replaceFirst(RegExp(r'^Posted\s+', caseSensitive: false), '');
}

