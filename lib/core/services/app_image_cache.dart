import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:bombay_casting/core/services/storage_urls.dart';

/// Disk cache for remote images — higher limits than the default manager.
///
/// Must mix in [ImageCacheManager] when using [CachedNetworkImage] disk resize
/// (`maxWidthDiskCache` / `maxHeightDiskCache`).
class AppImageCacheManager extends CacheManager with ImageCacheManager {
  AppImageCacheManager._()
      : super(
          Config(
            key,
            stalePeriod: const Duration(days: 30),
            maxNrOfCacheObjects: 500,
          ),
        );

  static const key = 'appImageCache';

  static final AppImageCacheManager instance = AppImageCacheManager._();
}

/// Stable object path for [CachedNetworkImage.cacheKey] (Firebase or DO CDN).
String? storageObjectCacheKey(String url) {
  return StorageUrls.objectPathFromUrl(url);
}
