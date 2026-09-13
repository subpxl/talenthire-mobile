import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SocialPlatformInfo {
  const SocialPlatformInfo({
    required this.name,
    required this.icon,
    required this.color,
    this.handleHint = '@username',
    this.linkLabel,
    this.asset,
  });

  final String name;
  final IconData icon;
  final Color color;
  final String handleHint;
  final String? linkLabel;
  final String? asset;

  String get profileLinkLabel => linkLabel ?? '$name Profile Link';

  static const known = [
    SocialPlatformInfo(
      name: 'Instagram',
      icon: Icons.camera_alt_rounded,
      color: Color(0xFFE4405F),
      linkLabel: 'Instagram Profile Link',
      asset: 'assets/icons/instagram.svg',
    ),
    SocialPlatformInfo(
      name: 'Website',
      icon: Icons.language_rounded,
      color: Color(0xFF1E88E5),
      linkLabel: 'Website Link',
    ),
    SocialPlatformInfo(
      name: 'IMDb',
      icon: Icons.movie_rounded,
      color: Color(0xFFF5C518),
      linkLabel: 'IMDb Profile Link',
      asset: 'assets/icons/imdb.svg',
    ),
    SocialPlatformInfo(
      name: 'ArtStation',
      icon: Icons.palette_rounded,
      color: Color(0xFF13AFF0),
      linkLabel: 'ArtStation Profile Link',
    ),
    SocialPlatformInfo(
      name: 'YouTube',
      icon: Icons.play_circle_fill_rounded,
      color: Color(0xFFFF0000),
      handleHint: '@channel',
      linkLabel: 'YouTube Channel Link',
      asset: 'assets/icons/youtube.svg',
    ),
    SocialPlatformInfo(
      name: 'Behance',
      icon: Icons.brush_rounded,
      color: Color(0xFF1769FF),
      linkLabel: 'Behance Profile Link',
    ),
    SocialPlatformInfo(
      name: 'Facebook',
      icon: Icons.facebook_rounded,
      color: Color(0xFF1877F2),
      handleHint: 'page or profile',
      linkLabel: 'Facebook Profile Link',
      asset: 'assets/icons/facebook.svg',
    ),
    SocialPlatformInfo(
      name: 'Twitter / X',
      icon: Icons.alternate_email_rounded,
      color: Color(0xFF111111),
    ),
    SocialPlatformInfo(
      name: 'LinkedIn',
      icon: Icons.work_rounded,
      color: Color(0xFF0A66C2),
      handleHint: 'profile url',
    ),
    SocialPlatformInfo(
      name: 'Snapchat',
      icon: Icons.chat_bubble_rounded,
      color: Color(0xFFF7E125),
    ),
  ];

  static List<SocialPlatformInfo> get linkFormPlatforms => known
      .where(
        (platform) => const {
          'Instagram',
          'Website',
          'IMDb',
          'YouTube',
          'Facebook',
        }.contains(platform.name),
      )
      .toList(growable: false);

  /// First-login onboarding: Instagram, Facebook, YouTube only.
  static List<SocialPlatformInfo> get onboardingLinkFormPlatforms => [
        forName('Instagram'),
        forName('Facebook'),
        forName('YouTube'),
      ];

  static const other = SocialPlatformInfo(
    name: 'Other',
    icon: Icons.add_rounded,
    color: Color(0xFF546E7A),
    handleHint: 'platform name',
  );

  static SocialPlatformInfo forName(String name) {
    final lower = name.trim().toLowerCase();
    if (lower.isEmpty) return other;
    for (final platform in known) {
      if (platform.name.toLowerCase() == lower) return platform;
    }
    if (lower.contains('instagram')) return known[0];
    if (lower.contains('website') || lower == 'web') return known[1];
    if (lower.contains('imdb')) return known[2];
    if (lower.contains('artstation')) return known[3];
    if (lower.contains('youtube')) return known[4];
    if (lower.contains('behance')) return known[5];
    if (lower.contains('facebook')) return known[6];
    if (lower.contains('twitter') || lower == 'x') return known[7];
    if (lower.contains('linkedin')) return known[8];
    if (lower.contains('snap')) return known[9];
    return SocialPlatformInfo(
      name: name.trim(),
      icon: Icons.public_rounded,
      color: const Color(0xFF546E7A),
    );
  }

  static bool isKnown(String name) {
    final lower = name.trim().toLowerCase();
    return known.any((platform) => platform.name.toLowerCase() == lower);
  }
}

class SocialPlatformIcon extends StatelessWidget {
  const SocialPlatformIcon({
    super.key,
    required this.info,
    this.size = 44,
    this.selected = false,
    this.onTap,
  });

  final SocialPlatformInfo info;
  final double size;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget child;
    if (info.asset != null) {
      child = SizedBox(
        width: size,
        height: size,
        child: SvgPicture.asset(
          info.asset!,
          fit: BoxFit.contain,
        ),
      );
    } else {
      final iconColor = info.color.computeLuminance() > 0.7
          ? Colors.black87
          : Colors.white;
      child = AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: info.color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.black : Colors.transparent,
            width: selected ? 2 : 0,
          ),
          boxShadow: [
            BoxShadow(
              color: info.color.withValues(alpha: 0.28),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(info.icon, color: iconColor, size: size * 0.46),
      );
    }
    if (onTap == null) return child;
    return GestureDetector(
      onTap: onTap,
      child: child,
    );
  }
}
