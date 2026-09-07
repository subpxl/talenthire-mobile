import 'package:flutter/material.dart';
import 'package:bombay_casting/core/widgets/app_network_image.dart';
import 'package:bombay_casting/features/jobs/models/job_assets.dart';

/// Local placeholder avatars — no network images required for UI preview.
class PlaceholderAvatar extends StatelessWidget {
  const PlaceholderAvatar({
    super.key,
    this.radius = 14,
    this.color,
    this.iconSize,
  });

  final double radius;
  final Color? color;
  final double? iconSize;

  static const List<Color> stackColors = [
    Color(0xFF7986CB),
    Color(0xFF81C784),
    Color(0xFFFFB74D),
  ];

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: color ?? Colors.grey.shade400,
      child: Icon(
        Icons.person,
        size: iconSize ?? radius * 0.9,
        color: Colors.white,
      ),
    );
  }
}

class PlaceholderProfileImage extends StatelessWidget {
  const PlaceholderProfileImage({
    super.key,
    this.height = 360,
    this.borderRadius = 16,
    this.aspectRatio,
    this.imageIndex = 1,
    this.imageUrl = '',
    this.thumbUrl = '',
    this.preferThumbnail = true,
    this.fill = false,
    this.fit = BoxFit.cover,
    this.intrinsicHeight = false,
    this.variant = AppImageVariant.list,
    this.fadeInDuration = const Duration(milliseconds: 280),
    this.fallbackIcon = Icons.movie_filter_outlined,
  });

  final double height;
  final double borderRadius;
  final double? aspectRatio;
  final int imageIndex;
  final String imageUrl;
  final String thumbUrl;
  final bool preferThumbnail;
  final bool fill;
  final BoxFit fit;
  final bool intrinsicHeight;
  final AppImageVariant variant;
  final Duration fadeInDuration;

  /// Shown when [imageUrl] is empty or fails to load.
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final fallback = JobPosterFallback(
      imageIndex: imageIndex,
      icon: fallbackIcon,
    );
    final expand = fill || !intrinsicHeight;
    final displayUrl = appImageDisplayUrl(
      fullUrl: imageUrl,
      thumbUrl: thumbUrl,
      preferThumbnail: preferThumbnail,
    );
    final image = displayUrl.isNotEmpty
        ? AppNetworkImage(
            imageUrl: displayUrl,
            variant: variant,
            fit: fit,
            width: double.infinity,
            height: expand ? double.infinity : null,
            imageBuilder: intrinsicHeight
                ? (context, provider) => Image(
                      image: provider,
                      fit: fit,
                      width: double.infinity,
                    )
                : null,
            fadeInDuration: fadeInDuration,
            progressIndicatorBuilder: (context, url, progress) =>
                intrinsicHeight
                    ? AspectRatio(
                        aspectRatio: aspectRatio ?? 3 / 4,
                        child: NetworkImageLoadingPlaceholder(
                          progress: progress.progress,
                        ),
                      )
                    : NetworkImageLoadingPlaceholder(
                        progress: progress.progress,
                      ),
            errorWidget: (context, url, error) => fallback,
          )
        : fallback;

    final clipped = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: fill
          ? SizedBox.expand(child: image)
          : intrinsicHeight
              ? image
              : aspectRatio != null
                  ? AspectRatio(aspectRatio: aspectRatio!, child: image)
                  : SizedBox(width: double.infinity, height: height, child: image),
    );
    return clipped;
  }
}

class JobAvatar extends StatelessWidget {
  const JobAvatar({
    super.key,
    required this.imageIndex,
    this.radius = 26,
    this.imageUrl = '',
    this.thumbUrl = '',
  });

  final int imageIndex;
  final double radius;
  final String imageUrl;
  final String thumbUrl;

  @override
  Widget build(BuildContext context) {
    final fallback = JobPosterFallback(
      imageIndex: imageIndex,
      iconSize: radius * 0.9,
    );
    final displayUrl = appImageDisplayUrl(
      fullUrl: imageUrl,
      thumbUrl: thumbUrl,
      preferThumbnail: true,
    );
    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: displayUrl.isNotEmpty
            ? AppNetworkImage(
                imageUrl: displayUrl,
                variant: AppImageVariant.avatar,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 220),
                progressIndicatorBuilder: (context, url, progress) =>
                    NetworkImageLoadingPlaceholder(
                      progress: progress.progress,
                      compact: true,
                    ),
                errorWidget: (context, url, error) => fallback,
              )
            : fallback,
      ),
    );
  }
}

class NetworkImageLoadingPlaceholder extends StatelessWidget {
  const NetworkImageLoadingPlaceholder({
    super.key,
    this.progress,
    this.compact = false,
  });

  final double? progress;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shortest = constraints.biggest.shortestSide;
        final size = compact || shortest < 80 ? 16.0 : 28.0;
        return ColoredBox(
          color: const Color(0xFFF0F0F0),
          child: Center(
            child: SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: progress,
                color: const Color(0xFFDC1C38),
              ),
            ),
          ),
        );
      },
    );
  }
}

class JobPosterFallback extends StatelessWidget {
  const JobPosterFallback({
    super.key,
    this.imageIndex = 1,
    this.iconSize = 56,
    this.icon = Icons.movie_filter_outlined,
  });

  final int imageIndex;
  final double iconSize;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = JobAssets.colorsFor(imageIndex);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: iconSize,
          color: Colors.white.withValues(alpha: 0.92),
        ),
      ),
    );
  }
}
