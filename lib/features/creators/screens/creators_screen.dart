import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/features/creators/screens/saved_creators_screen.dart';
import 'package:bombay_casting/features/creators/widgets/creator_masonry_grid.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_feed_status.dart';
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

  static const _loadMoreOffset = 420.0;

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

  bool _onScrollNotification(ScrollNotification notification) {
    final appState = context.read<AppState>();
    if (appState.creatorsInnerTabIndex != 0) return false;
    if (!appState.hasMoreCreators || appState.isLoadingMoreCreators) {
      return false;
    }
    if (notification is! ScrollUpdateNotification &&
        notification is! OverscrollNotification) {
      return false;
    }
    if (notification.metrics.pixels >=
        notification.metrics.maxScrollExtent - _loadMoreOffset) {
      appState.loadMoreCreators();
    }
    return false;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    context.read<AppState>().setCreatorsInnerTab(index);
    _resetScroll();
  }

  void _resetScroll() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _setCreatorCategories(Set<String> categories) {
    context.read<AppState>().setCreatorFilter(
          context.read<AppState>().creatorFilter.copyWith(
            categories: categories,
          ),
        );
    _resetScroll();
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
              ? context.read<AppState>().refreshCreators()
              : context.read<AppState>().refreshSavedCreators(),
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScrollNotification,
            child: CustomScrollView(
              controller: _scrollController,
              cacheExtent: 1200,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenH,
                      0,
                      AppSpacing.screenH,
                      0,
                    ),
                    child: AppTabBar(
                      tabs: _tabs,
                      selectedIndex: selectedTab,
                      onChanged: _onTabChanged,
                    ),
                  ),
                ),
                if (selectedTab == 0)
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: StickyBarDelegate(
                      extent: AppSearchAndChips.heightFor(_searchPadding),
                      child: _buildSearchAndChips(context),
                    ),
                  ),
                if (selectedTab == 0)
                  ..._buildAllSlivers(context)
                else
                  ...savedCreatorsSlivers(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const _searchPadding = EdgeInsets.fromLTRB(
    AppSpacing.screenH,
    4,
    AppSpacing.screenH,
    8,
  );

  Widget _buildSearchAndChips(BuildContext context) {
    return AppSearchAndChips(
      padding: _searchPadding,
      searchController: _searchController,
      searchHint: AppLocalizations.of(context)!.searchByNameLocationTalent,
      solidYellowChips: true,
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
          _setCreatorCategories({'Any'});
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
        _setCreatorCategories(current);
      },
      onFilterTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CreatorFilterScreen(),
          ),
        );
      },
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
    final feedFailed =
        appState.isCreatorsFeedEmpty && appState.creatorsLoadError != null;
    final feedLoading =
        appState.isCreatorsFeedEmpty && appState.isLoadingCreators;
    final l10n = AppLocalizations.of(context)!;

    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          creators.isEmpty || feedFailed || feedLoading ? 24 : 4,
          AppSpacing.screenH,
          AppSpacing.scrollBottom,
        ),
        sliver: feedLoading || feedFailed || creators.isEmpty
            ? SliverToBoxAdapter(
                child: AppFeedStatus(
                  isLoading: feedLoading,
                  errorMessage: feedFailed ? l10n.couldNotLoadCreators : null,
                  emptyMessage: filtersActive
                      ? l10n.noCreatorsMatchYourSearch
                      : l10n.noCreatorsToShowYet,
                  onRetry: feedFailed
                      ? () => context.read<AppState>().refreshCreators()
                      : null,
                  retryLabel: l10n.tryAgain,
                  padding: EdgeInsets.zero,
                ),
              )
            : CreatorMasonrySliver(
                creators: creators,
              ),
      ),
      if (appState.isLoadingMoreCreators)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.md,
              bottom: AppSpacing.scrollBottom,
            ),
            child: AppFeedStatus.spinner,
          ),
        ),
    ];
  }
}
