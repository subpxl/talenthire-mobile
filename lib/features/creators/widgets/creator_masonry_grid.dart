import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:bombay_casting/core/navigation/app_navigation.dart';
import 'package:bombay_casting/features/creators/models/creator_profile.dart';
import 'package:bombay_casting/features/creators/widgets/creator_card.dart';

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
      itemBuilder: (context, index) => _card(context, creators[index]),
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
    return SliverMasonryGrid.count(
      crossAxisCount: 2,
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      childCount: creators.length,
      itemBuilder: (context, index) => _card(context, creators[index]),
    );
  }
}

Widget _card(BuildContext context, CreatorProfile creator) {
  return CreatorCard(
    creator: creator,
    onTap: () => AppNavigation.openCreatorProfile(context, creator),
  );
}
