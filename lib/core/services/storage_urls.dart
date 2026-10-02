/// Helpers for DigitalOcean Spaces CDN and legacy Firebase Storage URLs.
class StorageUrls {
  StorageUrls._();

  static const cdnHost = 'talenthire-media.sgp1.cdn.digitaloceanspaces.com';
  static const originHost = 'talenthire-media.sgp1.digitaloceanspaces.com';

  static bool isStorageUrl(String url) {
    if (url.isEmpty) return false;
    return url.contains('firebasestorage.googleapis.com')
        || url.contains(cdnHost)
        || url.contains(originHost);
  }

  /// Public CDN URL for a storage object path.
  static String publicObjectUrl(String objectPath) {
    final normalized = objectPath.replaceFirst(RegExp(r'^/+'), '');
    final segments =
        normalized.split('/').map(Uri.encodeComponent).join('/');
    return 'https://$cdnHost/$segments';
  }

  /// Prefer CDN for display when safe; keeps tokenized Firebase download links.
  static String displayStorageUrl(String url) {
    if (url.isEmpty) return url;
    if (url.contains('firebasestorage.googleapis.com')) {
      // Token URLs work without auth. Rewriting to CDN breaks files that were
      // never copied to Spaces (common for Play Store builds still on Firebase).
      if (url.contains('token=')) return url;
      final path = objectPathFromUrl(url);
      if (path != null) return publicObjectUrl(path);
    }
    return url;
  }

  static String? objectPathFromUrl(String url) {
    if (url.isEmpty) return null;
    if (url.contains(cdnHost) || url.contains(originHost)) {
      try {
        final path = Uri.parse(url).path.replaceFirst('/', '');
        return path.isEmpty ? null : Uri.decodeComponent(path);
      } catch (_) {
        return null;
      }
    }
    if (!url.contains('firebasestorage.googleapis.com')) return null;
    const marker = '/o/';
    final start = url.indexOf(marker);
    if (start == -1) return null;
    var encoded = url.substring(start + marker.length);
    final query = encoded.indexOf('?');
    if (query != -1) encoded = encoded.substring(0, query);
    final decoded = Uri.decodeComponent(encoded);
    return decoded.isEmpty ? null : decoded;
  }
}
