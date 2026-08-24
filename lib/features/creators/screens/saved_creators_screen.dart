import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/navigation/app_navigation.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_screen_layout.dart';
import 'package:bombay_casting/core/widgets/promo_banner.dart';
import 'package:bombay_casting/features/creators/widgets/creator_card.dart';

class SavedCreatorsTabContent extends StatelessWidget {
  const SavedCreatorsTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    final savedCreators = context.watch<AppState>().savedCreators;
    if (savedCreators.isEmpty) {
      return AppScrollBody(
        onRefresh: () => context.read<AppState>().refreshSavedCreators(),
        child: Column(
          children: [
            const PromoBanner(
              title: 'Your saved creators',
              subtitle: 'Bookmark profiles you want to revisit',
            ),
            const SizedBox(height: AppSpacing.lg - 4),
            Text(
              AppLocalizations.of(context)!.tapBookmarkOnACreatorToSaveIt,
              style: context.bodyMedium,
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<AppState>().refreshSavedCreators(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              AppSpacing.screenV,
              AppSpacing.screenH,
              AppSpacing.lg,
            ),
            sliver: SliverToBoxAdapter(
              child: PromoBanner(
                title: 'Your saved creators',
                subtitle: 'Bookmark profiles you want to revisit',
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              0,
              AppSpacing.screenH,
              AppSpacing.scrollBottom,
            ),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 210 / 280,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final creator = savedCreators[index];
                  return CreatorCard(
                    creator: creator,
                    onTap: () =>
                        AppNavigation.openCreatorProfile(context, creator),
                  );
                },
                childCount: savedCreators.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
