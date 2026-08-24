import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/features/creators/screens/saved_creators_screen.dart';
import 'package:bombay_casting/features/creators/widgets/creator_card.dart';
import 'package:bombay_casting/core/navigation/app_navigation.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_screen_layout.dart';
import 'package:bombay_casting/core/widgets/app_search_filters.dart';
import 'package:bombay_casting/core/widgets/app_tab_bar.dart';
import 'package:bombay_casting/core/widgets/option_picker.dart';

class CreatorsScreen extends StatefulWidget {
  const CreatorsScreen({super.key});

  @override
  State<CreatorsScreen> createState() => _CreatorsScreenState();
}

class _CreatorsScreenState extends State<CreatorsScreen> {
  int _selectedTab = 0;
  String _selectedTalent = 'All';
  final _searchController = TextEditingController();

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScreenLayout(
      tabs: _tabs,
      selectedTabIndex: _selectedTab,
      onTabChanged: (i) => setState(() => _selectedTab = i),
      innerTabKey: _selectedTab,
      body: _selectedTab == 0
          ? Column(
              children: [
                AppSearchAndChips(
                  searchController: _searchController,
                  searchHint: AppLocalizations.of(context)!
                      .searchByNameLocationTalent,
                  chipOptions: [
                    AppLocalizations.of(context)!.all,
                    ...ProfileOptions.talentCategories,
                  ],
                  selectedChip: _selectedTalent == 'All'
                      ? AppLocalizations.of(context)!.all
                      : _selectedTalent,
                  onSearchChanged: (_) => setState(() {}),
                  onChipSelected: (label) {
                    final l10n = AppLocalizations.of(context)!;
                    setState(() {
                      _selectedTalent = label == l10n.all ? 'All' : label;
                    });
                  },
                ),
                Expanded(child: _buildAllTab(context)),
              ],
            )
          : const SavedCreatorsTabContent(),
    );
  }

  Widget _buildAllTab(BuildContext context) {
    final appState = context.watch<AppState>();
    final query = _searchController.text;
    final creators = appState.creators
        .where(
          (creator) =>
              creator.matchesSearch(query) &&
              creator.matchesTalent(_selectedTalent),
        )
        .toList();
    final filtersActive =
        query.trim().isNotEmpty || _selectedTalent != 'All';
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () =>
          context.read<AppState>().loadCreators(forceRefresh: true),
      child: creators.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.all(AppSpacing.screenH),
              children: [
                if (appState.isLoadingCreators)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else
                  Text(
                    filtersActive
                        ? AppLocalizations.of(context)!
                            .noCreatorsMatchYourSearch
                        : AppLocalizations.of(context)!.noCreatorsToShowYet,
                    style: context.bodyMedium,
                  ),
              ],
            )
          : GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.screenV,
                AppSpacing.screenH,
                AppSpacing.scrollBottom,
              ),
              itemCount: creators.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 210 / 280,
              ),
              itemBuilder: (context, index) {
                final creator = creators[index];
                return CreatorCard(
                  creator: creator,
                  onTap: () =>
                      AppNavigation.openCreatorProfile(context, creator),
                );
              },
            ),
    );
  }
}
