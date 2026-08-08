import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'optimized_network_image.dart';

/// Consistent circular avatar with optional network image.
class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String initials;
  final double radius;
  final Color? backgroundColor;

  const AppAvatar({
    super.key,
    this.imageUrl,
    required this.initials,
    this.radius = 20,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? context.colors.primary;
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final diameter = radius * 2;

    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      backgroundImage: hasImage
          ? OptimizedNetworkImage.provider(
              imageUrl!,
              context: context,
              width: diameter,
              height: diameter,
            )
          : null,
      child: hasImage
          ? null
          : Text(
              initials,
              style: TextStyle(
                color: AppColors.onPrimary,
                fontSize: radius * 0.65,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}
