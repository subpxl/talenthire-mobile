import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/features/creators/screens/saved_creators_screen.dart';
import 'package:bombay_casting/features/creators/widgets/creator_masonry_grid.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_screen_layout.dart';
import 'package:bombay_casting/core/widgets/app_search_filters.dart';
import 'package:bombay_casting/core/widgets/app_tab_bar.dart';
import 'package:bombay_casting/core/widgets/option_picker.dart';
import 'package:bombay_casting/features/creators/screens/creator_filter_screen.dart';

class CreatorsScreen extends StatefulWidget {
  const CreatorsScreen({super.key});

  @override
  State<CreatorsScreen> createState() => _CreatorsScreenState();
}

class _CreatorsScreenState extends State<CreatorsScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  static const _tabs = [
    AppTabItem(label: 'All', indicatorWidth: 24),
    AppTabItem(label: 'Saved', indicatorWidth: 40),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().loadCreators();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    context.read<AppState>().setCreatorsInnerTab(index);
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedTab = context.watch<AppState>().creatorsInnerTabIndex;
    return AppScreenLayout(
      showAppBar: false,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => selectedTab == 0
              ? context.read<AppState>().loadCreators(forceRefresh: true)
              : context.read<AppState>().refreshSavedCreators(),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context, selectedTab)),
              if (selectedTab == 0)
                ..._buildAllSlivers(context)
              else
                ...savedCreatorsSlivers(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int selectedTab) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH,
            4,
            AppSpacing.screenH,
            4,
          ),
          child: AppTabBar(
            tabs: _tabs,
            selectedIndex: selectedTab,
            onChanged: _onTabChanged,
          ),
        ),
        if (selectedTab == 0)
          AppSearchAndChips(
            searchController: _searchController,
            searchHint: AppLocalizations.of(context)!.searchByNameLocationTalent,
            chipOptions: [
              AppLocalizations.of(context)!.all,
              ...ProfileOptions.talentCategories,
            ],
            selectedChips: context.watch<AppState>().creatorFilter.categories,
            onSearchChanged: (_) => setState(() {}),
            onChipToggled: (label) {
              final l10n = AppLocalizations.of(context)!;
              final current = Set<String>.from(
                context.read<AppState>().creatorFilter.categories,
              );
              if (label == l10n.all ||
                  label.toLowerCase() == 'all' ||
                  label.toLowerCase() == 'any') {
                context.read<AppState>().setCreatorFilter(
                      context.read<AppState>().creatorFilter.copyWith(
                        categories: {'Any'},
                      ),
                    );
                return;
              }
              current.remove('Any');
              current.remove('All');
              current.remove(l10n.all);
              if (current.contains(label)) {
                current.remove(label);
              } else {
                current.add(label);
              }
              if (current.isEmpty) {
                current.add('Any');
              }
              context.read<AppState>().setCreatorFilter(
                    context.read<AppState>().creatorFilter.copyWith(
                      categories: current,
                    ),
                  );
            },
            onFilterTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreatorFilterScreen(),
                ),
              );
            },
          ),
      ],
    );
  }

  List<Widget> _buildAllSlivers(BuildContext context) {
    final appState = context.watch<AppState>();
    final query = _searchController.text;
    final creators = appState.creators
        .where(
          (creator) =>
              creator.matchesSearch(query) &&
              appState.creatorFilter.matches(creator),
        )
        .toList();
    final filtersActive =
        query.trim().isNotEmpty || appState.creatorFilter.isActive;

    if (creators.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenH),
            child: appState.isLoadingCreators
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Text(
                    filtersActive
                        ? AppLocalizations.of(context)!.noCreatorsMatchYourSearch
                        : AppLocalizations.of(context)!.noCreatorsToShowYet,
                    style: context.bodyMedium,
                  ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          4,
          AppSpacing.screenH,
          AppSpacing.scrollBottom,
        ),
        sliver: CreatorMasonrySliver(creators: creators),
      ),
    ];
  }
}
