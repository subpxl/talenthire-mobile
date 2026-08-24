import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/placeholder_avatar.dart';
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
    return Selector<AppState, bool>(
      selector: (_, state) =>
          creator.id.isNotEmpty && state.isCreatorSaved(creator.id),
      builder: (context, saved, _) {
        return GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Stack(
              fit: StackFit.expand,
              children: [
                PlaceholderProfileImage(
                  fill: true,
                  borderRadius: 0,
                  imageIndex: creator.cover.imageIndex,
                  imageUrl: creator.cover.url,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Color(0x99000000),
                      ],
                      stops: [0, 0.45, 1],
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton(
                    tooltip: saved ? 'Remove saved creator' : 'Save creator',
                    onPressed: creator.id.isEmpty
                        ? null
                        : () => context
                            .read<AppState>()
                            .toggleSavedCreator(creator),
                    icon: Icon(
                      saved ? Icons.bookmark : Icons.bookmark_border,
                      color: saved ? AppColors.primary : Colors.white,
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  bottom: 10,
                  left: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        creator.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        creator.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
