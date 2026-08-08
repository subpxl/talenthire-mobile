import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Disk LRU cache for network images with on-disk resize support.
///
/// Must use [ImageCacheManager] so [CachedNetworkImage] can store resized
/// thumbnails instead of re-downloading full-resolution files.
class FsapImageCacheManager extends CacheManager with ImageCacheManager {
  static const _cacheKey = 'fsapImageCache';

  static final FsapImageCacheManager _instance = FsapImageCacheManager._();

  factory FsapImageCacheManager() => _instance;

  FsapImageCacheManager._()
      : super(
          Config(
            _cacheKey,
            stalePeriod: const Duration(days: 30),
            maxNrOfCacheObjects: 500,
          ),
        );
}

class ImageCacheService {
  ImageCacheService._();

  static FsapImageCacheManager get instance => FsapImageCacheManager();

  /// Stable disk-cache key for Firebase Storage URLs (path only, no token).
  static String cacheKeyFor(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;

    final host = uri.host;
    if (host == 'firebasestorage.googleapis.com' ||
        host.endsWith('.firebasestorage.app') ||
        host.endsWith('storage.googleapis.com')) {
      return uri.path;
    }

    return url;
  }

  static Future<void> clearCache() => instance.emptyCache();
}
