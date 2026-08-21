import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import 'optimized_network_image.dart';

String? extractYoutubeId(String url) {
  if (url.isEmpty) return null;

  final uri = Uri.tryParse(url.startsWith('http') ? url : 'https://$url');
  if (uri != null) {
    final v = uri.queryParameters['v'];
    if (v != null && v.length == 11) return v;

    final segments = uri.pathSegments;
    if (segments.isNotEmpty) {
      if (uri.host.contains('youtu.be')) {
        final id = segments.first;
        if (id.length == 11) return id;
      }
      for (final segment in segments.reversed) {
        if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(segment)) {
          return segment;
        }
      }
    }
  }

  final match = RegExp(
    r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?|shorts)\/|.*[?&]v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})',
  ).firstMatch(url);
  return match?.group(1);
}

bool isYoutubeShort(String url) => url.contains('/shorts/');

String? youtubeThumbnailUrl(String url) {
  final id = extractYoutubeId(url);
  if (id == null) return null;
  return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
}

Uri? normalizeUrl(String urlString) {
  if (urlString.isEmpty) return null;
  var normalized = urlString.trim();
  if (!normalized.startsWith('http://') && !normalized.startsWith('https://')) {
    normalized = 'https://$normalized';
  }
  return Uri.tryParse(normalized);
}

Future<bool> launchExternalUrl(String urlString, {BuildContext? context}) async {
  final uri = normalizeUrl(urlString);
  if (uri == null) {
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid link URL')),
      );
    }
    return false;
  }

  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open YouTube')),
      );
    }
    return launched;
  } catch (e) {
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open link: $e')),
      );
    }
    return false;
  }
}

const _kYoutubeCardFooterPadding = 8.0;
const _kYoutubeCardTitleFontSize = 12.0;
const _kYoutubeCardTitleLineHeight = 1.25;
const _kYoutubeCardTitleMaxLines = 2;
const _kYoutubeCardIconSize = 14.0;

double _youtubeCardFooterHeight() {
  final textHeight =
      _kYoutubeCardTitleFontSize * _kYoutubeCardTitleLineHeight * _kYoutubeCardTitleMaxLines;
  final rowHeight = textHeight > _kYoutubeCardIconSize ? textHeight : _kYoutubeCardIconSize;
  return _kYoutubeCardFooterPadding * 2 + rowHeight + 14.0;
}

class _YoutubeLinkCard extends StatelessWidget {
  final String title;
  final String youtubeUrl;
  final bool isShort;
  final bool showLockOverlay;
  final EdgeInsetsGeometry? margin;
  final double width;

  const _YoutubeLinkCard({
    required this.title,
    required this.youtubeUrl,
    required this.width,
    this.isShort = false,
    this.showLockOverlay = false,
    this.margin,
  });

  void _openYoutube(BuildContext context) {
    if (showLockOverlay) return;
    launchExternalUrl(youtubeUrl, context: context);
  }

  @override
  Widget build(BuildContext context) {
    final thumbnail = youtubeThumbnailUrl(youtubeUrl);
    final aspectRatio = isShort ? 9 / 16 : 16 / 9;
    final thumbHeight = width / aspectRatio;

    return Container(
      width: width,
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        color: AppColors.surface,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: showLockOverlay ? null : () => _openYoutube(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: thumbHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (showLockOverlay)
                      Container(
                        color: AppColors.textPrimary.withAlpha(200),
                        child: const Center(
                          child: Icon(Icons.lock, color: AppColors.onPrimary, size: 24),
                        ),
                      )
                    else if (thumbnail != null)
                      OptimizedNetworkImage(
                        imageUrl: thumbnail,
                        width: double.infinity,
                        height: thumbHeight,
                        fit: BoxFit.cover,
                        errorWidget: Container(
                          color: AppColors.divider,
                          child: const Icon(Icons.play_circle_outline, size: 28, color: AppColors.textMuted),
                        ),
                      )
                    else
                      Container(
                        color: AppColors.divider,
                        child: const Icon(Icons.videocam_off, size: 28, color: AppColors.textMuted),
                      ),
                    if (!showLockOverlay)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow, color: AppColors.onPrimary, size: 22),
                        ),
                      ),
                    if (isShort && !showLockOverlay)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Short',
                            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: _kYoutubeCardFooterPadding,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: _kYoutubeCardTitleFontSize,
                          height: _kYoutubeCardTitleLineHeight,
                        ),
                        maxLines: _kYoutubeCardTitleMaxLines,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!showLockOverlay) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.open_in_new, color: AppColors.textMuted, size: _kYoutubeCardIconSize),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact card for profile pages.
class YoutubeShortsCard extends StatelessWidget {
  final String title;
  final String youtubeUrl;
  final bool showLockOverlay;

  static const double cardWidth = 112;

  const YoutubeShortsCard({
    super.key,
    required this.title,
    required this.youtubeUrl,
    this.showLockOverlay = false,
  });

  @override
  Widget build(BuildContext context) {
    return _YoutubeLinkCard(
      title: title,
      youtubeUrl: youtubeUrl,
      width: cardWidth,
      isShort: isYoutubeShort(youtubeUrl),
      showLockOverlay: showLockOverlay,
      margin: EdgeInsets.zero,
    );
  }
}

/// Compact card for artist detail horizontal scroll.
class YoutubeShortPreview extends StatelessWidget {
  final String title;
  final String youtubeUrl;

  static const double cardWidth = 112;

  const YoutubeShortPreview({
    super.key,
    required this.title,
    required this.youtubeUrl,
  });

  @override
  Widget build(BuildContext context) {
    return _YoutubeLinkCard(
      title: title,
      youtubeUrl: youtubeUrl,
      width: cardWidth,
      isShort: true,
      margin: EdgeInsets.zero,
    );
  }
}

/// Compact card for artist detail single video.
class YoutubeVideoRow extends StatelessWidget {
  final String title;
  final String youtubeUrl;

  const YoutubeVideoRow({
    super.key,
    required this.title,
    required this.youtubeUrl,
  });

  @override
  Widget build(BuildContext context) {
    return YoutubeShortsCard(
      title: title,
      youtubeUrl: youtubeUrl,
    );
  }
}

/// Height needed for a horizontal row of compact short cards.
double youtubeShortRowHeight({
  double cardWidth = YoutubeShortPreview.cardWidth,
  bool isShort = true,
}) {
  final aspectRatio = isShort ? 9 / 16 : 16 / 9;
  return cardWidth / aspectRatio + _youtubeCardFooterHeight();
}
