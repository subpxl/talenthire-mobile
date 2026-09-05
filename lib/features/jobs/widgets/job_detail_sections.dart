import 'package:bombay_casting/core/models/models.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_screen_layout.dart';
import 'package:bombay_casting/features/jobs/models/job_listing.dart';
import 'package:flutter/material.dart';

const _payGreen = Color(0xFF2E7D32);
const _rolePurple = Color(0xFF7E57C2);
const _timeAmber = Color(0xFFC77800);
const _langBlue = Color(0xFF1976D2);

class JobDetailStatsBar extends StatelessWidget {
  const JobDetailStatsBar({
    super.key,
    required this.job,
    this.postedAt,
  });

  final JobListing job;
  final DateTime? postedAt;

  @override
  Widget build(BuildContext context) {
    final location = _locationParts(job);
    final pay = _payParts(job);
    final role = _roleParts(job);
    final timing = _timingParts(job, postedAt);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _StatCell(
              icon: Icons.location_on_rounded,
              iconColor: AppColors.brandRed,
              primary: location.$1,
              secondary: location.$2,
            ),
            const _StatDivider(),
            _StatCell(
              flex: 12,
              icon: Icons.currency_rupee_rounded,
              iconColor: _payGreen,
              primary: pay.$1,
              secondary: pay.$2,
            ),
            const _StatDivider(),
            _StatCell(
              icon: Icons.movie_creation_rounded,
              iconColor: _rolePurple,
              primary: role.$1,
              secondary: role.$2,
            ),
            const _StatDivider(),
            _StatCell(
              icon: Icons.schedule_rounded,
              iconColor: _timeAmber,
              primary: timing.$1,
              secondary: timing.$2,
              secondaryColor: AppColors.brandRed,
            ),
          ],
        ),
      ),
    );
  }
}

class JobRolesSection extends StatelessWidget {
  const JobRolesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionTitle('Roles'),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              Expanded(
                child: _RoleCard(
                  title: 'Lead',
                  age: '22 – 30 yrs',
                  meta: 'M/F • On camera',
                  color: Color(0xFFE91E63),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _RoleCard(
                  title: 'Supporting',
                  age: '18 – 28 yrs',
                  meta: 'M/F • 1+ yr exp',
                  color: Color(0xFF7E57C2),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.age,
    required this.meta,
    required this.color,
  });

  final String title;
  final String age;
  final String meta;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.person_rounded, size: 20, color: color),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            age,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            meta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class JobAboutSection extends StatefulWidget {
  const JobAboutSection({super.key, required this.job});

  final JobListing job;

  @override
  State<JobAboutSection> createState() => _JobAboutSectionState();
}

class _JobAboutSectionState extends State<JobAboutSection> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final description = job.description.trim().isNotEmpty
        ? job.description.trim()
        : job.details.trim();
    final facts = _aboutFacts(job);
    if (description.isEmpty && facts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionTitle('About the project'),
        if (description.isNotEmpty) ...[
          _ExpandableCopy(
            text: description,
            expanded: _expanded,
            onToggle: () => setState(() => _expanded = !_expanded),
          ),
          if (facts.isNotEmpty) const SizedBox(height: AppSpacing.md),
        ],
        if (facts.isNotEmpty)
          Container(
            width: double.infinity,
            decoration: _cardDecoration,
            child: Column(
              children: [
                for (var i = 0; i < facts.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFF0EDED),
                    ),
                  _FactRow(fact: facts[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class JobSubmitSection extends StatelessWidget {
  const JobSubmitSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionTitle('What to submit'),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              Expanded(
                child: _SubmitCard(
                  icon: Icons.videocam_rounded,
                  iconColor: Color(0xFFE91E63),
                  title: 'YT Short or Insta Reel',
                  subtitle: 'A short introduction',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _SubmitCard(
                  icon: Icons.verified_rounded,
                  iconColor: Color(0xFF2E7D32),
                  title: 'Complete profile',
                  subtitle: 'Verified details',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.brandRedTint,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.brandRed),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Complete profile increases your chances of getting shortlisted.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.4,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SubmitCard extends StatelessWidget {
  const _SubmitCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.25,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.3,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

class JobDetailMetaFooter extends StatelessWidget {
  const JobDetailMetaFooter({
    super.key,
    required this.appliedCount,
    required this.jobId,
    required this.onReport,
  });

  final int appliedCount;
  final String jobId;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final count = appliedCount > 0
        ? appliedCount
        : 15 + (jobId.hashCode.abs() % 155);
    final actorsLabel = count == 1 ? '1 actor' : '$count actors';
    final appliedSuffix = count == 1 ? 'has applied' : 'have applied';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: _cardDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.groups_outlined,
            size: 20,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actorsLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  appliedSuffix,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.25,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            color: const Color(0xFFEDE8E8),
          ),
          InkWell(
            onTap: onReport,
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flag_outlined, size: 16, color: AppColors.brandRed),
                  SizedBox(width: 6),
                  Text(
                    'Report this job',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.brandRed,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: VerticalDivider(
        width: 12,
        thickness: 1,
        color: Color(0xFFEDE8E8),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.icon,
    required this.iconColor,
    required this.primary,
    required this.secondary,
    this.secondaryColor = AppColors.textHint,
    this.flex = 10,
  });

  final IconData icon;
  final Color iconColor;
  final String primary;
  final String secondary;
  final Color secondaryColor;
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
              primary,
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
          if (secondary.isNotEmpty) ...[
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                secondary,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: secondaryColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExpandableCopy extends StatelessWidget {
  const _ExpandableCopy({
    required this.text,
    required this.expanded,
    required this.onToggle,
  });

  final String text;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(
            text: text,
            style: const TextStyle(fontSize: 14.5, height: 1.5, color: AppColors.textPrimary),
          ),
          maxLines: 3,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              maxLines: expanded ? null : 3,
              overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14.5,
                height: 1.5,
                color: AppColors.textPrimary,
              ),
            ),
            if (overflows)
              GestureDetector(
                onTap: onToggle,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    expanded ? 'Read less' : 'Read more',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Fact {
  const _Fact({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
}

class _FactRow extends StatelessWidget {
  const _FactRow({required this.fact});

  final _Fact fact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Icon(fact.icon, size: 18, color: fact.color),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 108,
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                fact.label,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.3,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              fact.value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

(String, String) _locationParts(JobListing job) {
  final location = job.location.trim();
  if (location.isEmpty || isRemoteJobCity(location)) {
    final type = switch (job.locationType) {
      LocationType.online => 'Online',
      LocationType.onsite => 'Onsite',
      LocationType.remote => 'Remote',
    };
    return (type, location.isEmpty ? 'Open' : 'Nationwide');
  }
  final city = shortJobCity(location);
  final comma = location.indexOf(',');
  if (comma > 0) {
    final region = location.substring(comma + 1).trim();
    if (region.isNotEmpty) return (city, region);
  }
  return (city, '');
}

(String, String) _payParts(JobListing job) {
  final period = job.collabType.trim().isNotEmpty ? job.collabType : 'Project based';
  return (jobPayCompactLabel(job), period);
}

(String, String) _roleParts(JobListing job) {
  final role = job.role.trim().isNotEmpty ? job.role.trim() : 'Creator';
  final secondary = job.platforms.trim().isNotEmpty
      ? job.platforms.trim()
      : job.category.trim().isNotEmpty && job.category != role
          ? job.category.trim()
          : 'Role';
  return (role, secondary);
}

(String, String) _timingParts(JobListing job, DateTime? postedAt) {
  if (postedAt != null) {
    return (jobApplyByLabel(postedAt), jobDaysLeftLabel(postedAt));
  }
  final seen = job.seenStatus.trim();
  if (seen.isEmpty) return ('Open now', '');
  return (
    seen.replaceFirst(RegExp(r'^Posted\s+', caseSensitive: false), ''),
    '',
  );
}


const _knownLanguages = [
  'Hindi',
  'English',
  'Gujarati',
  'Marathi',
  'Punjabi',
  'Tamil',
  'Telugu',
  'Kannada',
  'Malayalam',
  'Bengali',
  'Urdu',
];

const _cardDecoration = BoxDecoration(
  color: Color(0xFFFCFCFC),
  borderRadius: BorderRadius.all(Radius.circular(14)),
  border: Border.fromBorderSide(BorderSide(color: AppColors.border)),
);

List<_Fact> _aboutFacts(JobListing job) {
  final facts = <_Fact>[];
  if (job.location.trim().isNotEmpty) {
    facts.add(
      _Fact(
        icon: Icons.location_on_rounded,
        color: _rolePurple,
        label: 'Location',
        value: job.location,
      ),
    );
  }
  final pay = _payParts(job);
  facts.add(
    _Fact(
      icon: Icons.currency_rupee_rounded,
      color: _payGreen,
      label: 'Compensation',
      value: pay.$2.isEmpty ? pay.$1 : '${pay.$1} · ${pay.$2}',
    ),
  );
  if (job.duration.trim().isNotEmpty &&
      job.duration.toLowerCase() != 'campaign based') {
    facts.add(
      _Fact(
        icon: Icons.calendar_month_rounded,
        color: _rolePurple,
        label: 'Deliverables',
        value: job.duration,
      ),
    );
  }
  if (job.platforms.trim().isNotEmpty) {
    facts.add(
      _Fact(
        icon: Icons.devices_rounded,
        color: _langBlue,
        label: 'Platforms',
        value: job.platforms,
      ),
    );
  }
  final languages = _languagesFrom(job);
  if (languages.isNotEmpty) {
    facts.add(
      _Fact(
        icon: Icons.translate_rounded,
        color: _langBlue,
        label: 'Languages',
        value: languages.join(', '),
      ),
    );
  }
  return facts;
}

List<String> _languagesFrom(JobListing job) {
  final blob = '${job.tags.join(' ')} ${job.description} ${job.details}';
  return [
    for (final language in _knownLanguages)
      if (RegExp('\\b${RegExp.escape(language)}\\b', caseSensitive: false)
          .hasMatch(blob))
        language,
  ];
}
