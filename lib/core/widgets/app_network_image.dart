import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:bombay_casting/core/services/app_image_cache.dart';
import 'package:bombay_casting/core/services/storage_urls.dart';

/// Pre-set decode sizes for common image placements.
enum AppImageVariant {
  /// Full-width profile or detail screens (~900px).
  full,

  /// Grid cards and job posters in lists (~560px).
  list,

  /// Circular avatars (~200px).
  avatar,

  /// Small thumbnails (~200px).
  thumb,
}

/// Cached network image with app-wide disk cache and stable Storage cache keys.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.variant = AppImageVariant.full,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.imageBuilder,
    this.progressIndicatorBuilder,
    this.errorWidget,
    this.fadeInDuration = const Duration(milliseconds: 280),
    this.memCacheWidth,
    this.memCacheHeight,
    this.maxWidthDiskCache,
    this.maxHeightDiskCache,
  });

  final String imageUrl;
  final AppImageVariant variant;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final ImageWidgetBuilder? imageBuilder;
  final ProgressIndicatorBuilder? progressIndicatorBuilder;
  final LoadingErrorWidgetBuilder? errorWidget;
  final Duration fadeInDuration;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final int? maxWidthDiskCache;
  final int? maxHeightDiskCache;

  int? get _memCacheWidth => memCacheWidth ?? _variantMemWidth(variant);
  int? get _maxWidthDiskCache =>
      maxWidthDiskCache ?? _variantDiskWidth(variant);
  int? get _maxHeightDiskCache =>
      maxHeightDiskCache ?? _variantDiskHeight(variant);

  static int? _variantMemWidth(AppImageVariant variant) => switch (variant) {
        AppImageVariant.full => 900,
        AppImageVariant.list => 560,
        AppImageVariant.avatar => 200,
        AppImageVariant.thumb => 200,
      };

  static int? _variantDiskWidth(AppImageVariant variant) => switch (variant) {
        AppImageVariant.full => 1200,
        AppImageVariant.list => 640,
        AppImageVariant.avatar => 256,
        AppImageVariant.thumb => 256,
      };

  static int? _variantDiskHeight(AppImageVariant variant) => switch (variant) {
        AppImageVariant.full => 1600,
        AppImageVariant.list => 960,
        AppImageVariant.avatar => 256,
        AppImageVariant.thumb => 256,
      };

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return errorWidget?.call(context, '', '') ?? const SizedBox.shrink();
    }

    String finalUrl = imageUrl;
    if (imageUrl.contains('firebasestorage.googleapis.com')) {
      final path = StorageUrls.objectPathFromUrl(imageUrl);
      if (path != null) {
        finalUrl = 'https://${StorageUrls.cdnHost}/$path';
      }
    }

    Widget image = CachedNetworkImage(
      imageUrl: finalUrl,
      width: width,
      height: height,
      fit: fit,
      imageBuilder: imageBuilder,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: Duration.zero,
      placeholderFadeInDuration: Duration.zero,
      progressIndicatorBuilder: progressIndicatorBuilder,
      errorWidget: errorWidget,
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }
}

/// Picks a thumbnail URL when available, otherwise the full image URL.
String appImageDisplayUrl({
  required String fullUrl,
  String thumbUrl = '',
  bool preferThumbnail = false,
}) {
  if (preferThumbnail && thumbUrl.trim().isNotEmpty) return thumbUrl;
  return fullUrl;
}
