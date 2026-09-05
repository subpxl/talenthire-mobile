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
import 'package:bombay_casting/core/widgets/app_success_toast.dart';
import 'package:bombay_casting/core/widgets/report_dialog.dart';
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
                final result = await showReportDialog(
                  context,
                  title: l10n.reportProfile,
                );
                if (result != null && context.mounted) {
                  showAppSuccessToast(context, l10n.creatorReported);
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
            if (creator.platformMetrics.any(
              (m) => m.url.isNotEmpty || m.handle.isNotEmpty,
            )) ...[
              const SizedBox(height: AppSpacing.md),
              _SocialLinksSection(metrics: creator.platformMetrics),
            ],
            if (_creatorStats(creator).isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _CreatorStatsBar(creator: creator),
            ],
            const SizedBox(height: AppSpacing.lg),
            _InfoSection(
              title: 'About',
              body: creator.bio,
              items: creator.aboutInfo,
              hideKeys: const {'gender', 'age'},
            ),
            const SizedBox(height: AppSpacing.md),
            _InfoSection(
              title: 'Work',
              items: creator.workInfo,
              hideKeys: const {'role'},
            ),
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
    this.hideKeys = const {},
  });

  final String title;
  final List<MapEntry<String, String>> items;
  final String body;
  final Set<String> hideKeys;

  static const _alwaysHidden = {
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
    final key = item.key.trim().toLowerCase();
    if (_alwaysHidden.contains(key) || hideKeys.contains(key)) return false;
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
                    color: Color(0xFFF0EDED),
                  ),
                _InfoFactRow(item: visible[i]),
              ],
            ],
          ),
        ),
      ],
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
    required this.secondary,
    this.secondaryColor = AppColors.textHint,
  });

  final IconData icon;
  final Color color;
  final String primary;
  final String secondary;
  final Color secondaryColor;
}

class _InfoFactRow extends StatelessWidget {
  const _InfoFactRow({required this.item});

  final MapEntry<String, String> item;

  static const _icons = <String, (IconData, Color)>{
    'languages': (Icons.translate_rounded, _statBlue),
    'gender': (Icons.person_rounded, _statPurple),
    'age': (Icons.cake_rounded, _statGreen),
    'role': (Icons.movie_creation_rounded, _statPurple),
    'niches': (Icons.auto_awesome_rounded, _statAmber),
    'open to': (Icons.work_outline_rounded, AppColors.brandRed),
  };

  @override
  Widget build(BuildContext context) {
    final key = item.key.trim().toLowerCase();
    final meta = _icons[key] ?? (Icons.info_outline_rounded, _statBlue);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Icon(meta.$1, size: 18, color: meta.$2),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 108,
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                item.key,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.3,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              item.value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<_CreatorStat> _creatorStats(CreatorProfile creator) {
  final stats = <_CreatorStat>[];
  final location = creator.location.trim();
  if (location.isNotEmpty) {
    final comma = location.indexOf(',');
    stats.add(
      _CreatorStat(
        icon: Icons.location_on_rounded,
        color: AppColors.brandRed,
        primary: comma > 0 ? location.substring(0, comma).trim() : location,
        secondary: comma > 0 ? location.substring(comma + 1).trim() : 'Location',
      ),
    );
  }

  final role = creator.title.trim().isNotEmpty
      ? creator.title.trim()
      : _infoValue(creator.workInfo, 'Role');
  if (role.isNotEmpty) {
    final niches = _infoValue(creator.workInfo, 'Niches');
    stats.add(
      _CreatorStat(
        icon: Icons.movie_creation_rounded,
        color: _statPurple,
        primary: role,
        secondary: niches.isNotEmpty ? niches.split(',').first.trim() : 'Role',
      ),
    );
  }

  final age = _infoValue(creator.aboutInfo, 'Age');
  if (age.isNotEmpty) {
    stats.add(
      _CreatorStat(
        icon: Icons.cake_rounded,
        color: _statGreen,
        primary: age,
        secondary: age.toLowerCase().contains('yr') ? 'Age' : 'Years',
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
        secondary: 'Gender',
      ),
    );
  } else {
    final languages = _infoValue(creator.aboutInfo, 'Languages');
    if (languages.isNotEmpty) {
      stats.add(
        _CreatorStat(
          icon: Icons.translate_rounded,
          color: _statBlue,
          primary: languages.split(',').first.trim(),
          secondary: languages.contains(',') ? 'Languages' : 'Language',
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
