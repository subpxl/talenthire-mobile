import 'package:flutter/material.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/l10n/app_localizations.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.messageBadgeCount = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final int messageBadgeCount;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Theme(
          data: Theme.of(context).copyWith(
            splashColor: AppColors.primary.withValues(alpha: 0.08),
            highlightColor: AppColors.primary.withValues(alpha: 0.04),
          ),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: onTap,
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home_outlined),
                activeIcon: const Icon(Icons.home),
                label: AppLocalizations.of(context)!.navHome,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.people_outline),
                activeIcon: const Icon(Icons.people),
                label: AppLocalizations.of(context)!.navCreators,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.movie_filter_outlined),
                activeIcon: const Icon(Icons.movie_filter),
                label: AppLocalizations.of(context)!.navJobs,
              ),
              BottomNavigationBarItem(
                icon: _BadgedIcon(
                  icon: Icons.chat_bubble_outline,
                  count: messageBadgeCount,
                ),
                activeIcon: _BadgedIcon(
                  icon: Icons.chat_bubble,
                  count: messageBadgeCount,
                ),
                label: AppLocalizations.of(context)!.navMessages,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_outline),
                activeIcon: const Icon(Icons.person),
                label: AppLocalizations.of(context)!.navProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgedIcon extends StatelessWidget {
  const _BadgedIcon({
    required this.icon,
    required this.count,
  });

  final IconData icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return Icon(icon);
    final label = count > 99 ? '99+' : '$count';
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        Positioned(
          right: -8,
          top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            constraints: const BoxConstraints(minWidth: 16),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
