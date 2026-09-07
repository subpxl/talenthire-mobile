import 'package:flutter/material.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/placeholder_avatar.dart';
import 'package:bombay_casting/core/widgets/verified_tick.dart';
import 'package:bombay_casting/features/creators/models/creator_profile.dart';

class CreatorCard extends StatelessWidget {
  const CreatorCard({
    super.key,
    required this.creator,
    required this.onTap,
  });

  final CreatorProfile creator;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PlaceholderProfileImage(
              fill: true,
              fit: BoxFit.cover,
              borderRadius: 0,
              imageIndex: creator.cover.imageIndex,
              imageUrl: creator.cover.url,
              memCacheWidth: 560,
              fadeInDuration: Duration.zero,
              fallbackIcon: Icons.person,
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 72,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Color(0x99000000),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      creator.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ),
                  if (creator.isVerified || creator.isPremium) ...[
                    const SizedBox(width: 4),
                    const VerifiedTick(size: 14),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
