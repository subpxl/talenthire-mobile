import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:bombay_casting/core/widgets/app_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/models/models.dart';
import 'package:bombay_casting/core/services/analytics_service.dart';
import 'package:bombay_casting/core/services/report_service.dart';
import 'package:bombay_casting/features/creators/models/creator_profile.dart';
import 'package:bombay_casting/features/creators/widgets/creator_detail_sections.dart';
import 'package:bombay_casting/features/jobs/utils/video_link_utils.dart';
import 'package:bombay_casting/core/deep_links/deep_link_target.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_screen_layout.dart';
import 'package:bombay_casting/core/widgets/placeholder_avatar.dart';
import 'package:bombay_casting/core/widgets/share_link_button.dart';
import 'package:bombay_casting/core/utils/social_link_utils.dart';
import 'package:bombay_casting/core/widgets/social_platforms.dart';
import 'package:bombay_casting/core/widgets/verified_tick.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
  int _slideIndex = 0;

  CreatorProfile get creator => widget.creator;
  List<CreatorPhoto> get photos => creator.photos;
  List<String> get videoLinks => creator.videoLinks;
  int get _slideCount => photos.length + videoLinks.length;

  bool _isVideoSlide(int index) => index >= photos.length;

  String _videoUrlAt(int index) => videoLinks[index - photos.length];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    AnalyticsService.instance.track(
      () => AnalyticsService.instance.logViewCreator(creatorId: creator.id),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showSlide(int index) {
    if (index < 0 || index >= _slideCount) return;
    setState(() => _slideIndex = index);
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: AppDurations.pageRoute,
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _launchVideoUrl(String url) async {
    if (url.isEmpty) return;
    var uri = Uri.tryParse(url);
    if (uri == null) return;
    if (!uri.hasScheme) uri = Uri.parse('https://$url');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
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
                await ReportService.instance.submitFromDialog(
                  context,
                  dialogTitle: l10n.reportProfile,
                  successMessage: l10n.creatorReported,
                  target: ReportTarget(
                    type: ReportType.creator,
                    targetId: creator.id,
                    targetLabel: creator.name,
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
            if (_creatorStats(creator).isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _CreatorStatsBar(creator: creator),
            ],
            if (creator.collabTypes.isNotEmpty ||
                creator.contentTypes.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              _CreatorSpecialtyCards(
                collabTypes: creator.collabTypes,
                contentTypes: creator.contentTypes,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            CreatorAboutSection(creator: creator),
            const SizedBox(height: AppSpacing.lg),
            CreatorDetailsCard(creator: creator),
            if (creator.platformMetrics.any(
              (m) => m.url.isNotEmpty || m.handle.isNotEmpty,
            )) ...[
              const SizedBox(height: AppSpacing.lg),
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
                itemCount: _slideCount,
                onPageChanged: (index) => setState(() => _slideIndex = index),
                itemBuilder: (context, index) {
                  if (_isVideoSlide(index)) {
                    final url = _videoUrlAt(index);
                    return GestureDetector(
                      onTap: () => _launchVideoUrl(url),
                      child: _CreatorVideoSlide(url: url),
                    );
                  }
                  final photo = photos[index];
                  return GestureDetector(
                    onTap: () => _openZoom(index),
                    child: PlaceholderProfileImage(
                      fill: true,
                      fit: BoxFit.contain,
                      borderRadius: 0,
                      imageIndex: photo.imageIndex,
                      imageUrl: photo.url,
                      fallbackIcon: Icons.person,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        if (_slideCount > 1) ...[
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 8.0;
              final count = _slideCount;
              // Keep thumb size identical to a 4-photo row. Only shrink
              // when videos push the strip past 4 slides.
              final slotsForWidth =
                  count > Profile.maxPhotos ? count : Profile.maxPhotos;
              final width =
                  (constraints.maxWidth - gap * (slotsForWidth - 1)) /
                      slotsForWidth;
              return Row(
                children: [
                  for (var i = 0; i < count; i++) ...[
                    if (i > 0) const SizedBox(width: gap),
                    SizedBox(
                      width: width,
                      child: GestureDetector(
                        onTap: () => _showSlide(i),
                        child: AnimatedContainer(
                          duration: AppDurations.innerTab,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(
                              color: i == _slideIndex
                                  ? AppColors.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          padding: const EdgeInsets.all(2),
                          child: _isVideoSlide(i)
                              ? _CreatorVideoThumb(url: _videoUrlAt(i))
                              : PlaceholderProfileImage(
                                  aspectRatio: 3 / 4,
                                  fit: BoxFit.contain,
                                  borderRadius: AppRadius.sm - 2,
                                  imageIndex: photos[i].imageIndex,
                                  imageUrl: photos[i].url,
                                  fallbackIcon: Icons.person,
                                ),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
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
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      creator.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (creator.isVerified || creator.isPremium) ...[
                    const SizedBox(width: 6),
                    const VerifiedTick(size: 20),
                  ],
                ],
              ),
            ),
            if (creator.id.isNotEmpty)
              Selector<AppState, bool>(
                selector: (_, state) => state.isCreatorSaved(creator.id),
                builder: (context, saved, _) {
                  return IconButton(
                    tooltip: saved ? 'Remove saved creator' : 'Save creator',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: () =>
                        context.read<AppState>().toggleSavedCreator(creator),
                    icon: Icon(
                      saved ? Icons.favorite : Icons.favorite_border,
                      color: AppColors.primary,
                    ),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _CreatorVideoSlide extends StatelessWidget {
  const _CreatorVideoSlide({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _CreatorVideoPreview(url: url),
        const _VideoPlayOverlay(size: 56),
      ],
    );
  }
}

class _CreatorVideoThumb extends StatelessWidget {
  const _CreatorVideoThumb({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm - 2),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _CreatorVideoPreview(url: url),
            const _VideoPlayOverlay(size: 22),
          ],
        ),
      ),
    );
  }
}

class _CreatorVideoPreview extends StatelessWidget {
  const _CreatorVideoPreview({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final thumbnail = VideoLinkUtils.youtubeThumbnailUrl(url);
    if (thumbnail != null) {
      return AppNetworkImage(
        imageUrl: thumbnail,
        variant: AppImageVariant.list,
        fit: BoxFit.cover,
        progressIndicatorBuilder: (_, _, progress) => ColoredBox(
          color: const Color(0xFF1A1A1A),
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: progress.progress,
                color: Colors.white70,
              ),
            ),
          ),
        ),
        errorWidget: (_, _, _) => _CreatorVideoFallback(
          isInstagram: VideoLinkUtils.isInstagram(url),
        ),
      );
    }
    return _CreatorVideoFallback(isInstagram: VideoLinkUtils.isInstagram(url));
  }
}

class _CreatorVideoFallback extends StatelessWidget {
  const _CreatorVideoFallback({this.isInstagram = false});

  final bool isInstagram;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF1A1A1A),
      child: Center(
        child: Icon(
          isInstagram ? Icons.movie_outlined : Icons.play_circle_outline,
          size: 48,
          color: Colors.white70,
        ),
      ),
    );
  }
}

class _VideoPlayOverlay extends StatelessWidget {
  const _VideoPlayOverlay({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.play_arrow_rounded,
          color: Colors.white,
          size: size * 0.62,
        ),
      ),
    );
  }
}

class _CreatorSpecialtyCards extends StatelessWidget {
  const _CreatorSpecialtyCards({
    required this.collabTypes,
    required this.contentTypes,
  });

  final List<String> collabTypes;
  final List<String> contentTypes;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      if (collabTypes.isNotEmpty)
        _SpecialtyCard(
          title: 'Collab type',
          subtitle: 'How they like to work',
          icon: Icons.handshake_outlined,
          accent: AppColors.brandRed,
          wash: const Color(0xFFFFF4F5),
          values: collabTypes,
        ),
      if (contentTypes.isNotEmpty)
        _SpecialtyCard(
          title: 'Type of content',
          subtitle: 'What they create',
          icon: Icons.auto_awesome_outlined,
          accent: const Color(0xFF6A1B9A),
          wash: const Color(0xFFF7F1FB),
          values: contentTypes,
        ),
    ];
    if (cards.length == 1) return cards.first;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 12),
        Expanded(child: cards[1]),
      ],
    );
  }
}

class _SpecialtyCard extends StatelessWidget {
  const _SpecialtyCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.wash,
    required this.values,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Color wash;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: wash,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: accent.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              height: 1.3,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final value in values)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accent.withValues(alpha: 0.14)),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

const _statGreen = Color(0xFF2E7D32);
const _statPurple = Color(0xFF7E57C2);
const _statAmber = Color(0xFFC77800);
const _statBlue = Color(0xFF1976D2);

class _SocialLinksSection extends StatelessWidget {
  const _SocialLinksSection({required this.metrics});

  final List<SocialPlatformMetric> metrics;

  void _launchUrl(String url) async {
    if (url.isEmpty) return;
    Uri? uri = Uri.tryParse(url);
    if (uri == null) return;

    if (!uri.hasScheme) {
      uri = Uri.parse('https://$url');
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeMetrics = metrics
        .where((m) => m.url.isNotEmpty || m.handle.isNotEmpty)
        .toList();
    if (activeMetrics.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < activeMetrics.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            _SocialIconButton(
              metric: activeMetrics[i],
              onTap: () => _launchUrl(
                SocialLinkUtils.resolveLaunchUrl(
                  activeMetrics[i].platform,
                  url: activeMetrics[i].url,
                  handle: activeMetrics[i].handle,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SocialIconButton extends StatelessWidget {
  const _SocialIconButton({required this.metric, required this.onTap});

  final SocialPlatformMetric metric;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final info = SocialPlatformInfo.forName(metric.platform);
    final accent = info.color.computeLuminance() > 0.65
        ? const Color(0xFF8A6D00)
        : info.color;

    return Tooltip(
      message: info.name,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Ink(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: info.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: info.asset != null
                  ? SvgPicture.asset(
                      info.asset!,
                      width: 16,
                      height: 16,
                      fit: BoxFit.contain,
                    )
                  : Icon(info.icon, size: 16, color: accent),
            ),
          ),
        ),
      ),
    );
  }
}

class _CreatorStatsBar extends StatelessWidget {
  const _CreatorStatsBar({required this.creator});

  final CreatorProfile creator;

  @override
  Widget build(BuildContext context) {
    final stats = _creatorStats(creator);
    if (stats.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < stats.length; i++) ...[
              if (i > 0)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: VerticalDivider(
                    width: 12,
                    thickness: 1,
                    color: Color(0xFFEDE8E8),
                  ),
                ),
              _CreatorStatCell(stat: stats[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _CreatorStatCell extends StatelessWidget {
  const _CreatorStatCell({required this.stat});

  final _CreatorStat stat;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: stat.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(stat.icon, size: 16, color: stat.color),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              stat.primary,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.15,
                letterSpacing: -0.15,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (stat.secondary.isNotEmpty) ...[
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                stat.secondary,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: stat.secondaryColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CreatorStat {
  const _CreatorStat({
    required this.icon,
    required this.color,
    required this.primary,
    this.secondary = '',
    this.secondaryColor = AppColors.textHint,
  });

  final IconData icon;
  final Color color;
  final String primary;
  final String secondary;
  final Color secondaryColor;
}

List<String> _statListParts(String raw) {
  return raw
      .split(RegExp(r'[,/|&]'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();
}

(String primary, String secondary) _statTopEntries(String raw) {
  final parts = _statListParts(raw);
  if (parts.isEmpty) return ('', '');
  if (parts.length == 1) return (parts.first, '');
  if (parts.length == 2) return (parts[0], parts[1]);
  return (parts[0], '${parts[1]} +${parts.length - 2}');
}

List<_CreatorStat> _creatorStats(CreatorProfile creator) {
  final stats = <_CreatorStat>[];
  final location = creator.location.trim();
  if (location.isNotEmpty) {
    final locationParts = _statTopEntries(location);
    stats.add(
      _CreatorStat(
        icon: Icons.location_on_rounded,
        color: AppColors.brandRed,
        primary: locationParts.$1,
        secondary: locationParts.$2,
      ),
    );
  }

  final role = creator.title.trim().isNotEmpty
      ? creator.title.trim()
      : _infoValue(creator.workInfo, 'Role');
  if (role.isNotEmpty) {
    final roleParts = _statTopEntries(role);
    stats.add(
      _CreatorStat(
        icon: Icons.movie_creation_rounded,
        color: _statPurple,
        primary: roleParts.$1,
        secondary: roleParts.$2,
        secondaryColor: _statPurple.withValues(alpha: 0.85),
      ),
    );
  }

  final age = _infoValue(creator.aboutInfo, 'Age');
  if (age.isNotEmpty) {
    stats.add(
      _CreatorStat(
        icon: Icons.cake_rounded,
        color: _statGreen,
        primary: age.replaceAll(RegExp(r'\s*yrs?\b', caseSensitive: false), '').trim(),
        secondary: age.toLowerCase().contains('yr') ? '' : 'Yrs',
      ),
    );
  }

  final gender = _infoValue(creator.aboutInfo, 'Gender');
  if (gender.isNotEmpty) {
    stats.add(
      _CreatorStat(
        icon: Icons.person_rounded,
        color: _statAmber,
        primary: gender,
      ),
    );
  } else {
    final languages = _infoValue(creator.aboutInfo, 'Languages');
    if (languages.isNotEmpty) {
      final languageParts = _statTopEntries(languages);
      stats.add(
        _CreatorStat(
          icon: Icons.translate_rounded,
          color: _statBlue,
          primary: languageParts.$1,
          secondary: languageParts.$2,
          secondaryColor: _statBlue.withValues(alpha: 0.85),
        ),
      );
    }
  }

  return stats.take(4).toList();
}

String _infoValue(List<MapEntry<String, String>> items, String key) {
  final needle = key.toLowerCase();
  for (final item in items) {
    if (item.key.trim().toLowerCase() == needle) {
      final value = item.value.trim();
      if (value.isNotEmpty && value != '-') return value;
    }
  }
  return '';
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
                      ? AppNetworkImage(
                          imageUrl: photo.url,
                          variant: AppImageVariant.full,
                          fit: BoxFit.contain,
                          progressIndicatorBuilder: (_, _, _) => const Center(
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
                            fallbackIcon: Icons.person,
                          ),
                        )
                      : PlaceholderProfileImage(
                          fill: true,
                          fit: BoxFit.contain,
                          borderRadius: 0,
                          imageIndex: photo.imageIndex,
                          imageUrl: '',
                          fallbackIcon: Icons.person,
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
