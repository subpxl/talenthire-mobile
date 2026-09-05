import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/promo_banner.dart';
import 'package:bombay_casting/features/creators/widgets/creator_masonry_grid.dart';

List<Widget> savedCreatorsSlivers(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final savedCreators = context.watch<AppState>().savedCreators;
  if (savedCreators.isEmpty) {
    return [
      SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: Column(
            children: [
              PromoBanner(
                title: l10n.yourSavedCreators,
                subtitle: l10n.savedCreatorsPromoSubtitle,
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
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.screenV,
        AppSpacing.screenH,
        AppSpacing.lg,
      ),
      sliver: SliverToBoxAdapter(
        child: PromoBanner(
          title: l10n.yourSavedCreators,
          subtitle: l10n.savedCreatorsPromoSubtitle,
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
