import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:bombay_casting/core/services/storage_urls.dart';

/// Disk cache for remote images — higher limits than the default manager.
class AppImageCacheManager {
  AppImageCacheManager._();

  static const key = 'appImageCache';

  static final CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 500,
    ),
  );
}

/// Stable object path for [CachedNetworkImage.cacheKey] (Firebase or DO CDN).
String? storageObjectCacheKey(String url) {
  return StorageUrls.objectPathFromUrl(url);
}
