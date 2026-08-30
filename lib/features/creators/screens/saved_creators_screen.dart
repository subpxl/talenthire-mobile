import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/promo_banner.dart';
import 'package:bombay_casting/features/creators/widgets/creator_masonry_grid.dart';

List<Widget> savedCreatorsSlivers(BuildContext context) {
  final savedCreators = context.watch<AppState>().savedCreators;
  if (savedCreators.isEmpty) {
    return [
      SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
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
        ),
      ),
    ];
  }
  return [
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
      sliver: CreatorMasonrySliver(creators: savedCreators),
    ),
  ];
}
