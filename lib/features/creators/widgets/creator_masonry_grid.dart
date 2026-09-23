import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:bombay_casting/core/navigation/app_navigation.dart';
import 'package:bombay_casting/features/creators/models/creator_profile.dart';
import 'package:bombay_casting/features/creators/widgets/creator_card.dart';

/// Deterministic portrait ratios so masonry variety stays without layout shift.
const _cardAspectRatios = [0.68, 0.74, 0.80, 0.88];

double creatorCardAspectRatio(String id) {
  return _cardAspectRatios[id.hashCode.abs() % _cardAspectRatios.length];
}

class CreatorMasonryGrid extends StatelessWidget {
  const CreatorMasonryGrid({
    super.key,
    required this.creators,
    this.padding,
    this.physics,
  });

  final List<CreatorProfile> creators;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    return MasonryGridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      padding: padding,
      physics: physics,
      itemCount: creators.length,
      itemBuilder: (context, index) =>
          _card(context, creators[index], index: index),
    );
  }
}

class CreatorMasonrySliver extends StatelessWidget {
  const CreatorMasonrySliver({
    super.key,
    required this.creators,
  });

  final List<CreatorProfile> creators;

  @override
  Widget build(BuildContext context) {
    return SliverMasonryGrid(
      gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      delegate: SliverChildBuilderDelegate(
        (context, index) => _card(context, creators[index], index: index),
        childCount: creators.length,
      ),
    );
  }
}

Widget _card(BuildContext context, CreatorProfile creator, {int? index}) {
  return _KeepAliveCreatorTile(
    key: index == 0 ? const Key('e2e_creator_card_first') : ValueKey(creator.id),
    creator: creator,
  );
}

class _KeepAliveCreatorTile extends StatefulWidget {
  const _KeepAliveCreatorTile({
    super.key,
    required this.creator,
  });

  final CreatorProfile creator;

  @override
  State<_KeepAliveCreatorTile> createState() => _KeepAliveCreatorTileState();
}

class _KeepAliveCreatorTileState extends State<_KeepAliveCreatorTile>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final creator = widget.creator;
    return AspectRatio(
      aspectRatio: creatorCardAspectRatio(creator.id),
      child: CreatorCard(
        creator: creator,
        onTap: () => AppNavigation.openCreatorProfile(context, creator),
      ),
    );
  }
}
