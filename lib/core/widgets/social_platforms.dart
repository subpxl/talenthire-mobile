import 'package:flutter/material.dart';

class SocialPlatformInfo {
  const SocialPlatformInfo({
    required this.name,
    required this.icon,
    required this.color,
    this.handleHint = '@username',
  });

  final String name;
  final IconData icon;
  final Color color;
  final String handleHint;

  static const known = [
    SocialPlatformInfo(
      name: 'Instagram',
      icon: Icons.camera_alt_rounded,
      color: Color(0xFFE4405F),
    ),
    SocialPlatformInfo(
      name: 'YouTube',
      icon: Icons.play_circle_fill_rounded,
      color: Color(0xFFFF0000),
      handleHint: '@channel',
    ),
    SocialPlatformInfo(
      name: 'Facebook',
      icon: Icons.facebook_rounded,
      color: Color(0xFF1877F2),
      handleHint: 'page or profile',
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
    if (lower.contains('youtube')) return known[1];
    if (lower.contains('facebook')) return known[2];
    if (lower.contains('twitter') || lower == 'x') return known[3];
    if (lower.contains('linkedin')) return known[4];
    if (lower.contains('snap')) return known[5];
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
    final iconColor = info.color.computeLuminance() > 0.7
        ? Colors.black87
        : Colors.white;
    final child = AnimatedContainer(
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
    if (onTap == null) return child;
    return GestureDetector(
      onTap: onTap,
      child: child,
    );
  }
}
