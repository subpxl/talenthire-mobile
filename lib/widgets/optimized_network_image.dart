import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../services/image_cache_service.dart';

/// Cached, memory- and disk-downsampled network image for grids, carousels, and thumbnails.
class OptimizedNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const OptimizedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  static int? cachePixelSize(double? logicalSize, BuildContext context) {
    if (logicalSize == null || !logicalSize.isFinite || logicalSize <= 0) {
      return null;
    }
    return (logicalSize * MediaQuery.devicePixelRatioOf(context)).round();
  }

  static ImageProvider provider(
    String imageUrl, {
    required BuildContext context,
    double? width,
    double? height,
  }) {
    return CachedNetworkImageProvider(
      imageUrl,
      maxWidth: cachePixelSize(width, context),
      maxHeight: cachePixelSize(height, context),
      cacheManager: ImageCacheService.instance,
      cacheKey: ImageCacheService.cacheKeyFor(imageUrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return errorWidget ?? const SizedBox.shrink();
    }

    final memWidth = cachePixelSize(width, context);
    final memHeight = cachePixelSize(height, context);
    final cacheKey = ImageCacheService.cacheKeyFor(imageUrl);

    Widget image = CachedNetworkImage(
      imageUrl: imageUrl,
      cacheKey: cacheKey,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: memWidth,
      memCacheHeight: memHeight,
      maxWidthDiskCache: memWidth,
      maxHeightDiskCache: memHeight,
      cacheManager: ImageCacheService.instance,
      useOldImageOnUrlChange: true,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (_, __) =>
          placeholder ??
          Container(
            width: width,
            height: height,
            color: Colors.grey.shade200,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      errorWidget: (_, __, ___) =>
          errorWidget ??
          Container(
            width: width,
            height: height,
            color: Colors.grey.shade300,
            child: const Icon(Icons.broken_image_outlined),
          ),
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }
}
