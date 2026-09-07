import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_screen_layout.dart';
import 'package:bombay_casting/features/creators/models/creator_profile.dart';
import 'package:flutter/material.dart';

const _statGreen = Color(0xFF2E7D32);
const _statPurple = Color(0xFF7E57C2);
const _statAmber = Color(0xFFC77800);
const _statBlue = Color(0xFF1976D2);

class CreatorAboutSection extends StatefulWidget {
  const CreatorAboutSection({super.key, required this.creator});

  final CreatorProfile creator;

  @override
  State<CreatorAboutSection> createState() => _CreatorAboutSectionState();
}

class _CreatorAboutSectionState extends State<CreatorAboutSection> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final about = widget.creator.bio.trim();
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

class CreatorDetailsCard extends StatelessWidget {
  const CreatorDetailsCard({super.key, required this.creator});

  final CreatorProfile creator;

  @override
  Widget build(BuildContext context) {
    final facts = _creatorDetailFacts(creator);
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
                _CreatorFactRow(fact: facts[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CreatorFactRow extends StatelessWidget {
  const _CreatorFactRow({required this.fact});

  final _CreatorFact fact;

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

class _CreatorFact {
  const _CreatorFact({
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

List<_CreatorFact> _creatorDetailFacts(CreatorProfile creator) {
  final facts = <_CreatorFact>[];

  final location = creator.location.trim();
  if (location.isNotEmpty) {
    facts.add(
      _CreatorFact(
        icon: Icons.location_on_rounded,
        color: AppColors.brandRed,
        label: 'Location',
        value: location,
      ),
    );
  }

  final role = creator.title.trim().isNotEmpty
      ? creator.title.trim()
      : _infoValue(creator.workInfo, 'Role');
  if (role.isNotEmpty) {
    facts.add(
      _CreatorFact(
        icon: Icons.movie_creation_rounded,
        color: _statPurple,
        label: 'Role',
        value: role,
      ),
    );
  }

  final gender = _infoValue(creator.aboutInfo, 'Gender');
  if (gender.isNotEmpty) {
    facts.add(
      _CreatorFact(
        icon: Icons.person_rounded,
        color: _statAmber,
        label: 'Gender',
        value: gender,
      ),
    );
  }

  final age = _infoValue(creator.aboutInfo, 'Age');
  if (age.isNotEmpty) {
    facts.add(
      _CreatorFact(
        icon: Icons.cake_rounded,
        color: _statGreen,
        label: 'Age',
        value: age,
      ),
    );
  }

  final languages = _infoValue(creator.aboutInfo, 'Languages');
  if (languages.isNotEmpty) {
    facts.add(
      _CreatorFact(
        icon: Icons.translate_rounded,
        color: _statBlue,
        label: 'Languages',
        value: languages,
      ),
    );
  }

  final niches = _infoValue(creator.workInfo, 'Niches');
  if (niches.isNotEmpty) {
    facts.add(
      _CreatorFact(
        icon: Icons.auto_awesome_rounded,
        color: _statAmber,
        label: 'Niches',
        value: niches,
      ),
    );
  }

  final openTo = _infoValue(creator.workInfo, 'Open to');
  if (openTo.isNotEmpty) {
    facts.add(
      _CreatorFact(
        icon: Icons.work_outline_rounded,
        color: AppColors.brandRed,
        label: 'Open to',
        value: openTo,
      ),
    );
  }

  if (creator.collabTypes.isNotEmpty) {
    facts.add(
      _CreatorFact(
        icon: Icons.handshake_outlined,
        color: AppColors.brandRed,
        label: 'Collab type',
        value: creator.collabTypes.join(', '),
      ),
    );
  }

  if (creator.contentTypes.isNotEmpty) {
    facts.add(
      _CreatorFact(
        icon: Icons.auto_awesome_outlined,
        color: _statPurple,
        label: 'Content type',
        value: creator.contentTypes.join(', '),
      ),
    );
  }

  if (creator.isVerified || creator.isPremium) {
    facts.add(
      _CreatorFact(
        icon: Icons.verified_rounded,
        color: _statBlue,
        label: 'Status',
        value: creator.isPremium ? 'Premium creator' : 'Verified creator',
      ),
    );
  }

  return facts;
}

String _infoValue(List<MapEntry<String, String>> items, String key) {
  final needle = key.toLowerCase();
  for (final item in items) {
    if (item.key.trim().toLowerCase() == needle) {
      final value = item.value.trim();
      if (value.isNotEmpty && value != '-') return value;
    }
  }
  return '';
}
