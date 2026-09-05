class VideoLinkUtils {
  VideoLinkUtils._();

  static String? youtubeVideoId(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || uri.host.isEmpty) return null;
    final host = uri.host.replaceFirst('www.', '').toLowerCase();
    if (host == 'youtu.be') {
      return uri.pathSegments.isEmpty ? null : uri.pathSegments.first;
    }
    if (!host.contains('youtube.com')) return null;
    final shortsIndex = uri.pathSegments.indexOf('shorts');
    if (shortsIndex >= 0 && shortsIndex + 1 < uri.pathSegments.length) {
      return uri.pathSegments[shortsIndex + 1];
    }
    final embedIndex = uri.pathSegments.indexOf('embed');
    if (embedIndex >= 0 && embedIndex + 1 < uri.pathSegments.length) {
      return uri.pathSegments[embedIndex + 1];
    }
    return uri.queryParameters['v'];
  }

  static String? youtubeThumbnailUrl(String url) {
    final id = youtubeVideoId(url);
    if (id == null || id.isEmpty) return null;
    return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
  }

  static bool isInstagram(String url) {
    final lower = url.toLowerCase();
    return lower.contains('instagram.com/') || lower.contains('instagr.am/');
  }
}
