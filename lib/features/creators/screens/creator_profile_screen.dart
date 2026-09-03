import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/models/models.dart';
import 'package:bombay_casting/features/creators/models/creator_profile.dart';
import 'package:bombay_casting/core/deep_links/deep_link_target.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_screen_layout.dart';
import 'package:bombay_casting/core/widgets/placeholder_avatar.dart';
import 'package:bombay_casting/core/widgets/report_dialog.dart';
import 'package:bombay_casting/core/widgets/share_link_button.dart';
import 'package:bombay_casting/core/widgets/social_platforms.dart';

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
          ShareLinkButton(
            url: DeepLinkTarget.creatorUrl(creator.id),
            message: 'Check out ${creator.name} on Bombay Casting Company',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'report') {
                final l10n = AppLocalizations.of(context)!;
                final result = await showReportDialog(
                  context,
                  title: l10n.reportProfile,
                );
                if (result != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.creatorReported)),
                  );
                }
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
            _InfoSection(
              title: 'About',
              body: creator.bio,
              items: creator.aboutInfo,
            ),
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

  void _openZoom(int index) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, _, _) => _PhotoZoomScreen(
          photos: photos,
          initialIndex: index,
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
            aspectRatio: 3 / 4,
            child: ColoredBox(
              color: const Color(0xFFF0F0F0),
              child: PageView.builder(
                controller: _pageController,
                itemCount: photos.length,
                onPageChanged: (index) => setState(() => _photoIndex = index),
                itemBuilder: (context, index) {
                  final photo = photos[index];
                  return GestureDetector(
                    onTap: () => _openZoom(index),
                    child: PlaceholderProfileImage(
                      fill: true,
                      fit: BoxFit.contain,
                      borderRadius: 0,
                      imageIndex: photo.imageIndex,
                      imageUrl: photo.url,
                    ),
                  );
                },
              ),
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
                        aspectRatio: 3 / 4,
                        fit: BoxFit.contain,
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
        if (creator.title.trim().isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(creator.title, style: context.bodyMedium),
        ],
        if (creator.location.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(creator.location, style: context.bodyMedium),
            ],
          ),
        ],
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    this.items = const [],
    this.body = '',
  });

  final String title;
  final List<MapEntry<String, String>> items;
  final String body;

  static const _hiddenKeys = {
    'experience',
    'content language',
  };

  List<MapEntry<String, String>> get _visibleItems {
    return [
      for (final item in items)
        if (_isVisible(item)) item,
    ];
  }

  bool _isVisible(MapEntry<String, String> item) {
    if (_hiddenKeys.contains(item.key.trim().toLowerCase())) return false;
    final value = item.value.trim();
    return value.isNotEmpty && value != '-';
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleItems;
    final about = body.trim();
    if (visible.isEmpty && about.isEmpty) return const SizedBox.shrink();
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (about.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    14,
                    AppSpacing.md,
                    14,
                  ),
                  child: Text(
                    about,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              for (var i = 0; i < visible.length; i++) ...[
                if (i > 0 || about.isNotEmpty)
                  const Divider(
                    height: 1,
                    indent: AppSpacing.md,
                    endIndent: AppSpacing.md,
                  ),
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
                          visible[i].key,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textHint,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          visible[i].value,
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
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: activeMetrics.map((metric) {
            final info = SocialPlatformInfo.forName(metric.platform);
            final target =
                metric.url.isNotEmpty ? metric.url : metric.handle;
            return Tooltip(
              message: metric.platform,
              child: SocialPlatformIcon(
                info: info,
                size: 44,
                onTap: () => _launchUrl(target),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _PhotoZoomScreen extends StatefulWidget {
  const _PhotoZoomScreen({
    required this.photos,
    required this.initialIndex,
  });

  final List<CreatorPhoto> photos;
  final int initialIndex;

  @override
  State<_PhotoZoomScreen> createState() => _PhotoZoomScreenState();
}

class _PhotoZoomScreenState extends State<_PhotoZoomScreen> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      initialPage: widget.initialIndex.clamp(0, widget.photos.length - 1),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.photos.length,
            itemBuilder: (context, index) {
              final photo = widget.photos[index];
              return InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: photo.url.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: photo.url,
                          fit: BoxFit.contain,
                          placeholder: (_, _) => const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          errorWidget: (_, _, _) => PlaceholderProfileImage(
                            fill: true,
                            fit: BoxFit.contain,
                            borderRadius: 0,
                            imageIndex: photo.imageIndex,
                            imageUrl: '',
                          ),
                        )
                      : PlaceholderProfileImage(
                          fill: true,
                          fit: BoxFit.contain,
                          borderRadius: 0,
                          imageIndex: photo.imageIndex,
                          imageUrl: '',
                        ),
                ),
              );
            },
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            right: 8,
            child: IconButton(
              tooltip: 'Close',
              onPressed: () => Navigator.maybePop(context),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.55),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.close, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
