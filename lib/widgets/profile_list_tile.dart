import 'package:flutter/material.dart';
import 'package:bombay_casting/theme/app_theme.dart';
import 'package:bombay_casting/widgets/placeholder_avatar.dart';

class ProfileListTile extends StatelessWidget {
  const ProfileListTile({
    super.key,
    required this.name,
    required this.subtitle,
    this.secondaryLine,
    this.meta,
    required this.avatarColor,
    this.imageIndex,
    this.imageUrl = '',
    this.trailing,
    this.onTap,
    this.showVerified = false,
  });

  final String name;
  final String subtitle;
  final String? secondaryLine;
  final String? meta;
  final Color avatarColor;
  final int? imageIndex;
  final String imageUrl;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showVerified;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenH,
            vertical: AppSpacing.sm + 2,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              imageIndex != null
                  ? JobAvatar(
                      imageIndex: imageIndex!,
                      radius: 26,
                      imageUrl: imageUrl,
                    )
                  : PlaceholderAvatar(
                      radius: 26,
                      color: avatarColor,
                      iconSize: 28,
                    ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (showVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.verified,
                            color: AppColors.chatGreen,
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(subtitle, style: context.bodyMedium.copyWith(fontSize: 13)),
                    if (secondaryLine != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        secondaryLine!,
                        style: context.bodyMedium.copyWith(fontSize: 13),
                      ),
                    ],
                    if (meta != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(meta!, style: context.caption),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
