import 'package:flutter_cache_manager/flutter_cache_manager.dart';

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

/// Extracts a stable Firebase Storage object path for [CachedNetworkImage.cacheKey].
String? storageObjectCacheKey(String url) {
  if (url.isEmpty || !url.contains('firebasestorage.googleapis.com')) {
    return null;
  }
  final marker = '/o/';
  final start = url.indexOf(marker);
  if (start == -1) return null;
  var encoded = url.substring(start + marker.length);
  final query = encoded.indexOf('?');
  if (query != -1) encoded = encoded.substring(0, query);
  final decoded = Uri.decodeComponent(encoded);
  return decoded.isEmpty ? null : decoded;
}
