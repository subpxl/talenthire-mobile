import 'package:bombay_casting/features/creators/models/creator_profile.dart';
import 'package:bombay_casting/features/creators/widgets/creator_masonry_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final allCreators = [
    CreatorProfile.fromJson({'id': '1', 'name': 'Asha', 'title': 'Actor'}),
    CreatorProfile.fromJson({'id': '2', 'name': 'Ria', 'title': 'Model'}),
    CreatorProfile.fromJson({'id': '3', 'name': 'Dev', 'title': 'Singer'}),
    CreatorProfile.fromJson({'id': '4', 'name': 'Kia', 'title': 'Dancer'}),
  ];

  testWidgets('restores every creator card after a pill is cleared', (
    tester,
  ) async {
    var visible = List<CreatorProfile>.from(allCreators);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          visible = visible.length == allCreators.length
                              ? [allCreators.first]
                              : List<CreatorProfile>.from(allCreators);
                        });
                      },
                      child: const Text('toggle-pill'),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(8),
                    sliver: visible.isEmpty
                        ? const SliverToBoxAdapter(child: Text('empty'))
                        : CreatorMasonrySliver(
                            key: ValueKey<String>(
                              visible.map((creator) => creator.id).join(','),
                            ),
                            creators: visible,
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Asha'), findsOneWidget);
    expect(find.text('Ria'), findsOneWidget);
    expect(find.text('Dev'), findsOneWidget);
    expect(find.text('Kia'), findsOneWidget);

    await tester.tap(find.text('toggle-pill'));
    await tester.pumpAndSettle();

    expect(find.text('Asha'), findsOneWidget);
    expect(find.text('Ria'), findsNothing);

    await tester.tap(find.text('toggle-pill'));
    await tester.pumpAndSettle();

    expect(find.text('Asha'), findsOneWidget);
    expect(find.text('Ria'), findsOneWidget);
    expect(find.text('Dev'), findsOneWidget);
    expect(find.text('Kia'), findsOneWidget);
  });
}
