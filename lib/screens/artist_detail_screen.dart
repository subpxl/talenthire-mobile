import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_tag.dart';
import '../widgets/youtube_shorts_player.dart';
import '../widgets/optimized_network_image.dart';
import '../screens/message_detail_screen.dart';
import '../widgets/loading_dialog.dart';
import '../widgets/app_bottom_nav_bar.dart';
import 'main_screen.dart';

class ArtistDetailScreen extends StatefulWidget {
  final Artist artist;

  const ArtistDetailScreen({super.key, required this.artist});

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  bool get _hasVideos =>
      widget.artist.shortIntroVideoLink.isNotEmpty ||
      widget.artist.achievementsVideoLink.isNotEmpty ||
      widget.artist.previousWorksVideoLink.isNotEmpty;

  List<({String title, String url})> get _videos => [
        if (widget.artist.shortIntroVideoLink.isNotEmpty)
          (title: 'Short Intro', url: widget.artist.shortIntroVideoLink),
        if (widget.artist.achievementsVideoLink.isNotEmpty)
          (title: 'Achievements', url: widget.artist.achievementsVideoLink),
        if (widget.artist.previousWorksVideoLink.isNotEmpty)
          (title: 'Previous Works', url: widget.artist.previousWorksVideoLink),
      ];

  bool get _hasPhysicalDetails =>
      widget.artist.age != null ||
      widget.artist.gender.isNotEmpty ||
      (widget.artist.height != null && widget.artist.height!.isNotEmpty) ||
      (widget.artist.bodyType != null && widget.artist.bodyType!.isNotEmpty) ||
      (widget.artist.ethnicity != null && widget.artist.ethnicity!.isNotEmpty);

  List<String> get _allImages {
    final images = <String>[];
    if (widget.artist.profileImage.isNotEmpty) {
      images.add(widget.artist.profileImage);
    }
    for (final photo in widget.artist.photos) {
      if (!images.contains(photo)) {
        images.add(photo);
      }
    }
    return images;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showFullScreenImage(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) {
          final size = MediaQuery.sizeOf(ctx);
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            body: Center(
              child: InteractiveViewer(
                child: OptimizedNetworkImage(
                  imageUrl: imageUrl,
                  width: size.width,
                  height: size.height,
                  fit: BoxFit.contain,
                  placeholder: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artist Profile'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImageCarousel(context),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.artist.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 6),
                  AppTag(label: widget.artist.role),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.artist.location,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  if (widget.artist.experienceLevel.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.work_outline, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          widget.artist.experienceLevel == 'experienced' ? 'Experienced' : 'Fresher',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            if (_hasVideos) ...[
              _sectionHeader(context, 'Videos & Shorts', Icons.play_circle_outline),
              const SizedBox(height: 10),
              if (_videos.length >= 2)
                SizedBox(
                  height: youtubeShortRowHeight(),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _videos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) => YoutubeShortPreview(
                      title: _videos[i].title,
                      youtubeUrl: _videos[i].url,
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: YoutubeVideoRow(
                    title: _videos.first.title,
                    youtubeUrl: _videos.first.url,
                  ),
                ),
              const SizedBox(height: 20),
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.videocam_off, color: AppColors.textMuted),
                      SizedBox(width: 12),
                      Text('No videos uploaded yet', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 4),

            if (widget.artist.socialLinks.isNotEmpty) ...[
              _sectionHeader(context, 'Social Links', Icons.link),
              const SizedBox(height: 4),
              ...widget.artist.socialLinks.map((link) => _socialLinkTile(context, link)),
              const SizedBox(height: 16),
            ],

            if (_hasPhysicalDetails) ...[
              _sectionHeader(context, 'Details', Icons.person_outline),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (widget.artist.age != null)
                      _detailChip(Icons.cake_outlined, 'Age', '${widget.artist.age}'),
                    if (widget.artist.gender.isNotEmpty)
                      _detailChip(Icons.wc_outlined, 'Gender', _formatGender(widget.artist.gender)),
                    if (widget.artist.height != null && widget.artist.height!.isNotEmpty)
                      _detailChip(Icons.height, 'Height', widget.artist.height!),
                    if (widget.artist.bodyType != null && widget.artist.bodyType!.isNotEmpty)
                      _detailChip(Icons.accessibility_new_outlined, 'Body Type', _formatBodyType(widget.artist.bodyType!)),
                    if (widget.artist.ethnicity != null && widget.artist.ethnicity!.isNotEmpty)
                      _detailChip(Icons.public_outlined, 'Region', _formatEthnicity(widget.artist.ethnicity!)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(context, 'About', Icons.person_outline, inset: false),
                  const SizedBox(height: 8),
                  Text(
                    widget.artist.description.isNotEmpty
                        ? widget.artist.description
                        : 'No description provided.',
                    style: const TextStyle(height: 1.6, fontSize: 15, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),

            if (widget.artist.skills.isNotEmpty) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(context, 'Skills', Icons.star_outline, inset: false),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.artist.skills.map((skill) => AppTag(label: skill)).toList(),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _startChat(context),
                  icon: const Icon(Icons.chat),
                  label: const Text('Contact Artist'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
          ),
          AppBottomNavBar(
            selectedIndex: MainScreen.mainKey.currentState?.selectedIndex ?? 0,
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel(BuildContext context) {
    final images = _allImages;

    if (images.isEmpty) {
      return Container(
        height: 280,
        color: context.colors.primaryContainer,
        child: Center(
          child: Text(
            widget.artist.initials,
            style: TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.bold,
              color: context.colors.primary.withAlpha(180),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 350,
          width: double.infinity,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                onPageChanged: (idx) {
                  setState(() {
                    _currentImageIndex = idx;
                  });
                },
                itemCount: images.length,
                itemBuilder: (context, index) {
                  final screenWidth = MediaQuery.sizeOf(context).width;
                  return GestureDetector(
                    onTap: () => _showFullScreenImage(images[index]),
                    child: Container(
                      color: AppColors.divider,
                      child: OptimizedNetworkImage(
                        imageUrl: images[index],
                        width: screenWidth,
                        height: 350,
                        fit: BoxFit.contain,
                        errorWidget: Container(
                          color: AppColors.outline,
                          child: Center(
                            child: Text(
                              widget.artist.initials,
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (images.length > 1)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(images.length, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentImageIndex == index
                              ? context.colors.primary
                              : AppColors.textMuted.withAlpha(100),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
        if (images.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 16, right: 16),
            child: SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  final isSelected = _currentImageIndex == index;
                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      width: 70,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? context.colors.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: OptimizedNetworkImage(
                          imageUrl: images[index],
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          errorWidget: Container(
                            color: AppColors.outline,
                            child: const Icon(Icons.person, color: AppColors.onPrimary),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _sectionHeader(
    BuildContext context,
    String title,
    IconData icon, {
    bool inset = true,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: inset ? 16 : 0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: context.colors.primary),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _detailChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: context.colors.primary),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  String _formatGender(String gender) {
    switch (gender) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      case 'other':
        return 'Other';
      default:
        return gender;
    }
  }

  String _formatBodyType(String bodyType) {
    switch (bodyType) {
      case 'slim':
        return 'Slim';
      case 'athletic':
        return 'Athletic';
      case 'average':
        return 'Average';
      case 'heavy':
        return 'Heavy';
      default:
        return bodyType;
    }
  }

  String _formatEthnicity(String ethnicity) {
    switch (ethnicity) {
      case 'north_indian':
        return 'North Indian';
      case 'south_indian':
        return 'South Indian';
      case 'east_indian':
        return 'East Indian';
      case 'west_indian':
        return 'West Indian';
      case 'other':
        return 'Other';
      default:
        return ethnicity;
    }
  }

  Widget _socialLinkTile(BuildContext context, SocialLink link) {
    final name = link.name.isNotEmpty ? link.name : 'Link';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: context.colors.primary.withAlpha(25),
        child: Icon(_socialIcon(name), color: context.colors.primary, size: 20),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        link.url,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      trailing: const Icon(Icons.open_in_new, size: 18, color: AppColors.textMuted),
      onTap: () => launchExternalUrl(link.url, context: context),
    );
  }

  IconData _socialIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('instagram')) return Icons.camera_alt_outlined;
    if (lower.contains('youtube')) return Icons.play_circle_outline;
    if (lower.contains('facebook')) return Icons.facebook;
    if (lower.contains('twitter') || lower.contains('x')) return Icons.alternate_email;
    if (lower.contains('linkedin')) return Icons.business_center_outlined;
    if (lower.contains('tiktok')) return Icons.music_note_outlined;
    return Icons.link;
  }

  void _startChat(BuildContext context) async {
    final state = context.read<AppState>();
    
    LoadingDialog.show(context, message: 'Starting chat...');
    final conversation = await state.getOrCreateConversation(widget.artist.name, widget.artist.id);
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
