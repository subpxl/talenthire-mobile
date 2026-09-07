import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_screen_layout.dart';
import 'package:bombay_casting/core/widgets/placeholder_avatar.dart';
import 'package:bombay_casting/core/widgets/verified_tick.dart';
import 'package:bombay_casting/features/jobs/models/agency_profile.dart';
import 'package:bombay_casting/features/jobs/models/job_listing.dart';
import 'package:bombay_casting/features/jobs/widgets/job_card.dart';
import 'package:flutter/material.dart';

const _statGreen = Color(0xFF2E7D32);
const _statPurple = Color(0xFF7E57C2);
const _statBlue = Color(0xFF1976D2);

const _cardDecoration = BoxDecoration(
  color: Color(0xFFFCFCFC),
  borderRadius: BorderRadius.all(Radius.circular(14)),
  border: Border.fromBorderSide(BorderSide(color: AppColors.border)),
);

class AgencyHeroCard extends StatelessWidget {
  const AgencyHeroCard({super.key, required this.agency});

  final AgencyProfile agency;

  @override
  Widget build(BuildContext context) {
    final location = agency.location.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: PlaceholderProfileImage(
            aspectRatio: 0.85,
            borderRadius: 0,
            imageIndex: agency.imageIndex,
            imageUrl: agency.imageUrl,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AgencyMonogram(name: agency.name),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          agency.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (agency.isVerified) ...[
                        const SizedBox(width: 6),
                        const VerifiedTick(size: 20),
                      ],
                    ],
                  ),
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AgencyMonogram extends StatelessWidget {
  const _AgencyMonogram({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.brandRedTint,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.brandRed.withValues(alpha: 0.12)),
      ),
      child: Text(
        _agencyInitials(name),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          color: AppColors.brandRed,
        ),
      ),
    );
  }
}

class AgencyQuickInfoCards extends StatelessWidget {
  const AgencyQuickInfoCards({super.key, required this.agency});

  final AgencyProfile agency;

  @override
  Widget build(BuildContext context) {
    final location = agency.location.trim();
    final hasLocation = location.isNotEmpty;
    final jobLabel = agency.jobCount == 1 ? '1 job' : '${agency.jobCount} jobs';
    final jobSubtitle = agency.jobCount > 0
        ? 'Open listings'
        : 'No listings yet';

    if (!hasLocation) {
      return _AgencyInfoCard(
        icon: Icons.work_outline_rounded,
        iconColor: _statGreen,
        title: jobLabel,
        subtitle: jobSubtitle,
      );
    }

    final comma = location.indexOf(',');
    final city = comma > 0 ? location.substring(0, comma).trim() : location;
    final region = comma > 0 ? location.substring(comma + 1).trim() : '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _AgencyInfoCard(
            icon: Icons.location_on_rounded,
            iconColor: AppColors.brandRed,
            title: city,
            subtitle: region.isNotEmpty ? region : 'Location',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _AgencyInfoCard(
            icon: Icons.work_outline_rounded,
            iconColor: _statGreen,
            title: jobLabel,
            subtitle: jobSubtitle,
          ),
        ),
      ],
    );
  }
}

class _AgencyInfoCard extends StatelessWidget {
  const _AgencyInfoCard({
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

class AgencyDetailsCard extends StatelessWidget {
  const AgencyDetailsCard({super.key, required this.agency});

  final AgencyProfile agency;

  @override
  Widget build(BuildContext context) {
    final facts = _agencyDetailFacts(agency);
    if (facts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionTitle('Details'),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < facts.length; i++) ...[
                if (i > 0)
                  const Divider(
                    height: 1,
                    indent: AppSpacing.md,
                    endIndent: AppSpacing.md,
                    color: Color(0xFFF0EDED),
                  ),
                _AgencyFactRow(fact: facts[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class AgencyAboutSection extends StatefulWidget {
  const AgencyAboutSection({super.key, required this.agency});

  final AgencyProfile agency;

  @override
  State<AgencyAboutSection> createState() => _AgencyAboutSectionState();
}

class _AgencyAboutSectionState extends State<AgencyAboutSection> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final about = widget.agency.description.trim();
    if (about.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionTitle('About'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            14,
            AppSpacing.md,
            14,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: _ExpandableCopy(
            text: about,
            expanded: _expanded,
            onToggle: () => setState(() => _expanded = !_expanded),
          ),
        ),
      ],
    );
  }
}

class AgencyJobsSection extends StatelessWidget {
  const AgencyJobsSection({
    super.key,
    required this.agencyName,
    required this.listings,
    required this.emptyMessage,
  });

  final String agencyName;
  final List<JobListing> listings;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            'Jobs by $agencyName',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.sectionTitle,
          ),
        ),
        if (listings.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 26),
            decoration: _cardDecoration,
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.brandRedTint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.work_outline_rounded,
                    size: 22,
                    color: AppColors.brandRed,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  emptyMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          for (var i = 0; i < listings.length; i++) ...[
            JobCard(job: listings[i]),
            if (i < listings.length - 1)
              const SizedBox(height: AppSpacing.lg),
          ],
      ],
    );
  }
}

class _AgencyFactRow extends StatelessWidget {
  const _AgencyFactRow({required this.fact});

  final _AgencyFact fact;

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

class _ExpandableCopy extends StatelessWidget {
  const _ExpandableCopy({
    required this.text,
    required this.expanded,
    required this.onToggle,
  });

  final String text;
  final bool expanded;
  final VoidCallback onToggle;

  static const _style = TextStyle(
    fontSize: 14,
    height: 1.45,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: _style),
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
              style: _style,
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

class _AgencyFact {
  const _AgencyFact({
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

List<_AgencyFact> _agencyDetailFacts(AgencyProfile agency) {
  final facts = <_AgencyFact>[];

  final location = agency.location.trim();
  if (location.isNotEmpty) {
    facts.add(
      _AgencyFact(
        icon: Icons.location_on_rounded,
        color: AppColors.brandRed,
        label: 'Location',
        value: location,
      ),
    );
  }

  facts.add(
    _AgencyFact(
      icon: Icons.work_outline_rounded,
      color: _statGreen,
      label: 'Open jobs',
      value: agency.jobCount == 1 ? '1 job' : '${agency.jobCount} jobs',
    ),
  );

  if (agency.categories.isNotEmpty) {
    facts.add(
      _AgencyFact(
        icon: Icons.movie_creation_rounded,
        color: _statPurple,
        label: 'Casting for',
        value: agency.categories.join(', '),
      ),
    );
  }

  if (agency.isVerified) {
    facts.add(
      const _AgencyFact(
        icon: Icons.verified_rounded,
        color: _statBlue,
        label: 'Status',
        value: 'Verified agency',
      ),
    );
  }

  return facts;
}

String _agencyInitials(String name) {
  final words = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) return 'A';
  if (words.length == 1) {
    final word = words.first;
    return (word.length > 1 ? word.substring(0, 2) : word).toUpperCase();
  }
  return '${words[0][0]}${words[1][0]}'.toUpperCase();
}
