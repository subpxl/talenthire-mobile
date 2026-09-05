import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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
    this.fill = false,
    this.fit = BoxFit.cover,
    this.intrinsicHeight = false,
    this.memCacheWidth = 900,
    this.fadeInDuration = const Duration(milliseconds: 280),
  });

  final double height;
  final double borderRadius;
  final double? aspectRatio;
  final int imageIndex;
  final String imageUrl;
  final bool fill;
  final BoxFit fit;
  final bool intrinsicHeight;
  final int memCacheWidth;
  final Duration fadeInDuration;

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: Colors.grey.shade300,
      child: Icon(Icons.movie_filter_outlined, size: 72, color: Colors.grey.shade500),
    );
    final expand = fill || !intrinsicHeight;
    final image = imageUrl.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: imageUrl,
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
            fadeOutDuration: Duration.zero,
            placeholderFadeInDuration: Duration.zero,
            memCacheWidth: memCacheWidth,
            placeholder: (context, url) => intrinsicHeight
                ? AspectRatio(
                    aspectRatio: aspectRatio ?? 3 / 4,
                    child: ColoredBox(
                      color: Colors.grey.shade200,
                      child: Icon(
                        Icons.movie_filter_outlined,
                        size: 40,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  )
                : ColoredBox(
                    color: Colors.grey.shade200,
                    child: Icon(
                      Icons.movie_filter_outlined,
                      size: 56,
                      color: Colors.grey.shade400,
                    ),
                  ),
            errorWidget: (context, url, error) => Image.asset(
              JobAssets.pathFor(imageIndex),
              fit: fit,
              width: double.infinity,
              height: expand ? double.infinity : null,
              errorBuilder: (context, error, stackTrace) => fallback,
            ),
          )
        : Image.asset(
            JobAssets.pathFor(imageIndex),
            fit: fit,
            width: double.infinity,
            height: expand ? double.infinity : null,
            errorBuilder: (context, error, stackTrace) => fallback,
          );

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
  });

  final int imageIndex;
  final double radius;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey.shade400,
      child: Icon(Icons.movie_filter_outlined, size: radius * 0.9, color: Colors.white),
    );
    return ClipOval(
      child: imageUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: imageUrl,
              width: radius * 2,
              height: radius * 2,
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 220),
              fadeOutDuration: Duration.zero,
              memCacheWidth: 200,
              placeholder: (context, url) => ColoredBox(
                color: Colors.grey.shade300,
                child: Icon(
                  Icons.movie_filter_outlined,
                  size: radius * 0.9,
                  color: Colors.white,
                ),
              ),
              errorWidget: (context, url, error) => Image.asset(
                JobAssets.pathFor(imageIndex),
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => fallback,
              ),
            )
          : Image.asset(
              JobAssets.pathFor(imageIndex),
              width: radius * 2,
              height: radius * 2,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => fallback,
            ),
    );
  }
}
