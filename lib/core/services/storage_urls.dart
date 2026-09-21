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
