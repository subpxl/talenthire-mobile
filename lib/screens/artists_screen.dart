import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/app_avatar.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_dialog.dart';
import 'artist_detail_screen.dart';
import 'message_detail_screen.dart';

class ArtistsScreen extends StatefulWidget {
  const ArtistsScreen({super.key});

  @override
  State<ArtistsScreen> createState() => _ArtistsScreenState();
}

class _ArtistsScreenState extends State<ArtistsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedTag = 'All';

  // Advanced filters
  String _genderFilter = 'Any';
  String _experienceFilter = 'Any';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Artist> _filterArtists(List<Artist> artists) {
    return artists.where((artist) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch = query.isEmpty ||
          artist.name.toLowerCase().contains(query) ||
          artist.location.toLowerCase().contains(query) ||
          artist.description.toLowerCase().contains(query) ||
          artist.role.toLowerCase().contains(query);

      final matchesTag = _selectedTag == 'All' ||
          artist.role.toUpperCase() == _selectedTag.toUpperCase();

      final matchesGender = _genderFilter == 'Any' ||
          artist.gender.isEmpty ||
          artist.gender.toLowerCase() == _genderFilter.toLowerCase();

      final matchesExperience = _experienceFilter == 'Any' ||
          artist.experienceLevel.isEmpty ||
          artist.experienceLevel.toLowerCase() == _experienceFilter.toLowerCase();

      return matchesSearch && matchesTag && matchesGender && matchesExperience;
    }).toList();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Text(
                            'Filter Artists',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              setSheetState(() {
                                _genderFilter = 'Any';
                                _experienceFilter = 'Any';
                                _selectedTag = 'All';
                              });
                              setState(() {});
                            },
                            child: const Text('Reset'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16.0),
                        shrinkWrap: true,
                        children: [
                          const Text('Gender', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: ['Any', 'Male', 'Female', 'Other'].map((g) {
                              return ChoiceChip(
                                label: Text(g),
                                selected: _genderFilter == g,
                                onSelected: (val) {
                                  if (val) setSheetState(() => _genderFilter = g);
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                          const Text('Experience Level', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: ['Any', 'Fresher', 'Intermediate', 'Experienced'].map((e) {
                              return ChoiceChip(
                                label: Text(e),
                                selected: _experienceFilter == e,
                                onSelected: (val) {
                                  if (val) setSheetState(() => _experienceFilter = e);
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          setState(() {});
                          Navigator.pop(context);
                        },
                        child: const Text('Apply Filters'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final filteredArtists = _filterArtists(state.artists);
    final tags = ['All', ...state.categories];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Artists Directory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search by name, location, talent...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: tags.length,
              itemBuilder: (context, index) {
                final tag = tags[index];
                final isSelected = tag == _selectedTag;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedTag = tag),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.onPrimary : AppColors.textPrimary,
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: filteredArtists.isEmpty
                ? EmptyState(
                    icon: Icons.people_outline,
                    title: state.artists.isEmpty
                        ? 'No artists available'
                        : 'No artists match your search',
                    subtitle: state.artists.isEmpty ? null : 'Try a different search or filter',
                  )
                : RefreshIndicator(
                    onRefresh: () => context.read<AppState>().refreshData(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: filteredArtists.length,
                      itemBuilder: (context, index) {
                        final artist = filteredArtists[index];
                        return AppCard(
                          margin: const EdgeInsets.only(bottom: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ArtistDetailScreen(artist: artist),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  AppAvatar(
                                    imageUrl: artist.profileImage.isNotEmpty
                                        ? artist.profileImage
                                        : null,
                                    initials: artist.initials,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          artist.name,
                                          style: context.text.titleLarge,
                                        ),
                                        Text(
                                          artist.role,
                                          style: context.text.bodyMedium?.copyWith(
                                            color: context.colors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                artist.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, color: AppColors.textSecondary, size: 18),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      artist.location,
                                      style: const TextStyle(color: AppColors.textSecondary),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: () => _contactArtist(context, artist),
                                  icon: const Icon(Icons.chat, size: 18),
                                  label: const Text('Contact Artist'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _contactArtist(BuildContext context, artist) async {
    final state = context.read<AppState>();

    LoadingDialog.show(context, message: 'Starting chat...');
    final conversation = await state.getOrCreateConversation(artist.name, artist.id);
    if (!context.mounted) return;
    LoadingDialog.hide(context);

    if (conversation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot message yourself.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessageDetailScreen(conversation: conversation),
      ),
    );
  }
}
