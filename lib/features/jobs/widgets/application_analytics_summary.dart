import 'package:bombay_casting/core/models/models.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Basic application stats shown at the top of the Applied jobs tab.
class ApplicationAnalyticsSummary extends StatelessWidget {
  const ApplicationAnalyticsSummary({
    super.key,
    required this.applications,
  });

  final List<Application> applications;

  int _count(bool Function(ApplicationStatus status) match) {
    return applications.where((app) => match(app.status)).length;
  }

  @override
  Widget build(BuildContext context) {
    final total = applications.length;
    final active = _count(
      (s) =>
          s == ApplicationStatus.applied ||
          s == ApplicationStatus.opened ||
          s == ApplicationStatus.inReview ||
          s == ApplicationStatus.shortlisted ||
          s == ApplicationStatus.interview,
    );
    final selected = _count((s) => s == ApplicationStatus.selected);
    final rejected = _count((s) => s == ApplicationStatus.rejected);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your activity',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            total == 0
                ? 'Apply to jobs to see your stats here.'
                : '$total application${total == 1 ? '' : 's'} submitted',
            style: context.bodyMedium,
          ),
          if (total > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'Active',
                    value: '$active',
                    color: AppColors.brandRed,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatTile(
                    label: 'Selected',
                    value: '$selected',
                    color: const Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatTile(
                    label: 'Rejected',
                    value: '$rejected',
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _StatusBar(
              label: 'Active',
              count: active,
              total: total,
              color: AppColors.brandRed,
            ),
            const SizedBox(height: 6),
            _StatusBar(
              label: 'Selected',
              count: selected,
              total: total,
              color: const Color(0xFF16A34A),
            ),
            const SizedBox(height: 6),
            _StatusBar(
              label: 'Rejected',
              count: rejected,
              total: total,
              color: AppColors.textSecondary,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  final String label;
  final int count;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? count / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: AppColors.border,
            color: color,
          ),
        ),
      ],
    );
  }
}
