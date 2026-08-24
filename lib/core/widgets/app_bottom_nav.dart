import 'package:flutter/material.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/l10n/app_localizations.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

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
                icon: const Icon(Icons.chat_bubble_outline),
                activeIcon: const Icon(Icons.chat_bubble),
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
