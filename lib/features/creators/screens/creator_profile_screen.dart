import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/models/models.dart';
import 'package:bombay_casting/features/creators/models/creator_profile.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_screen_layout.dart';
import 'package:bombay_casting/core/widgets/placeholder_avatar.dart';

class CreatorProfileScreen extends StatefulWidget {
  const CreatorProfileScreen({
    super.key,
    required this.creator,
  });

  final CreatorProfile creator;

  @override
  State<CreatorProfileScreen> createState() => _CreatorProfileScreenState();
}

class _CreatorProfileScreenState extends State<CreatorProfileScreen> {
  late final PageController _pageController;
  int _photoIndex = 0;

  CreatorProfile get creator => widget.creator;
  List<CreatorPhoto> get photos => creator.photos;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showPhoto(int index) {
    if (index < 0 || index >= photos.length) return;
    setState(() => _photoIndex = index);
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: AppDurations.pageRoute,
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(AppLocalizations.of(context)!.creator,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'report') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.creatorReported,
                    ),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'report',
                child: Text(AppLocalizations.of(context)!.reportProfile),
              ),
            ],
          ),
        ],
      ),
      body: AppScrollBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPhotoSwitcher(),
            const SizedBox(height: AppSpacing.md),
            _buildHeader(context),
            const SizedBox(height: AppSpacing.lg),
            _InfoSection(title: 'About', items: creator.aboutInfo),
            const SizedBox(height: AppSpacing.md),
            _InfoSection(title: 'Work', items: creator.workInfo),
            if (creator.platformMetrics.where((m) => m.url.isNotEmpty || m.handle.isNotEmpty).isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _SocialLinksSection(metrics: creator.platformMetrics),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSwitcher() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: AspectRatio(
            aspectRatio: 0.85,
            child: Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: photos.length,
                  onPageChanged: (index) => setState(() => _photoIndex = index),
                  itemBuilder: (context, index) {
                    final photo = photos[index];
                    return PlaceholderProfileImage(
                      fill: true,
                      borderRadius: 0,
                      imageIndex: photo.imageIndex,
                      imageUrl: photo.url,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        if (photos.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < photos.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showPhoto(i),
                    child: AnimatedContainer(
                      duration: AppDurations.innerTab,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(
                          color: i == _photoIndex
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: PlaceholderProfileImage(
                        aspectRatio: 210 / 280,
                        borderRadius: AppRadius.sm - 2,
                        imageIndex: photos[i].imageIndex,
                        imageUrl: photos[i].url,
                      ),
                    ),
                  ),
                ),
              ],
              for (var i = photos.length; i < 4; i++) ...[
                const SizedBox(width: 8),
                const Expanded(child: SizedBox()),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                creator.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (creator.id.isNotEmpty)
              Selector<AppState, bool>(
                selector: (_, state) => state.isCreatorSaved(creator.id),
                builder: (context, saved, _) {
                  return IconButton(
                    tooltip: saved ? 'Remove saved creator' : 'Save creator',
                    onPressed: () =>
                        context.read<AppState>().toggleSavedCreator(creator),
                    icon: Icon(
                      saved ? Icons.bookmark : Icons.bookmark_border,
                      color: AppColors.primary,
                    ),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        const SizedBox(height: 2),
        Text(creator.title, style: context.bodyMedium),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(creator.location, style: context.bodyMedium),
          ],
        ),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.items});

  final String title;
  final List<MapEntry<String, String>> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionTitle(title),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, indent: AppSpacing.md, endIndent: AppSpacing.md),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          items[i].key,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textHint,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          items[i].value,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SocialLinksSection extends StatelessWidget {
  const _SocialLinksSection({required this.metrics});

  final List<SocialPlatformMetric> metrics;

  IconData _getPlatformIcon(String platform) {
    final p = platform.toLowerCase();
    if (p.contains('instagram')) return Icons.camera_alt;
    if (p.contains('facebook')) return Icons.facebook;
    if (p.contains('youtube')) return Icons.ondemand_video;
    if (p.contains('twitter') || p.contains('x')) return Icons.alternate_email;
    return Icons.link;
  }

  void _launchUrl(String url) async {
    if (url.isEmpty) return;
    Uri? uri = Uri.tryParse(url);
    if (uri == null) return;
    
    // Auto prefix http if scheme is missing
    if (!uri.hasScheme) {
      uri = Uri.parse('https://$url');
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeMetrics = metrics.where((m) => m.url.isNotEmpty || m.handle.isNotEmpty).toList();
    if (activeMetrics.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionTitle('Social Profiles'),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: activeMetrics.map((m) {
            return ActionChip(
              avatar: Icon(_getPlatformIcon(m.platform), size: 16, color: AppColors.primary),
              label: Text(m.handle.isNotEmpty ? m.handle : m.platform),
              side: const BorderSide(color: AppColors.border),
              backgroundColor: AppColors.surface,
              onPressed: () => _launchUrl(m.url),
            );
          }).toList(),
        ),
      ],
    );
  }
}
