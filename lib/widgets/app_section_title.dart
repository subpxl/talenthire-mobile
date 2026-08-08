import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Section heading used on profile and detail screens.
class AppSectionTitle extends StatelessWidget {
  final String title;
  final IconData? icon;

  const AppSectionTitle(this.title, {super.key, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: context.colors.primary),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
