class VideoLinkUtils {
  VideoLinkUtils._();

  static String normalize(String input) {
    final value = input.trim();
    if (value.isEmpty) return '';
    if (RegExp(r'^https?://', caseSensitive: false).hasMatch(value)) {
      return value;
    }
    return 'https://$value';
  }

  static Uri? tryParse(String input) {
    final normalized = normalize(input);
    if (normalized.isEmpty) return null;
    final uri = Uri.tryParse(normalized);
    if (uri == null || uri.host.isEmpty) return null;
    return uri;
  }

  static String _host(Uri uri) =>
      uri.host.replaceFirst(RegExp(r'^www\.'), '').toLowerCase();

  static bool isYouTube(String url) {
    final uri = tryParse(url);
    if (uri == null) return false;
    final host = _host(uri);
    return host == 'youtu.be' ||
        host == 'youtube.com' ||
        host.endsWith('.youtube.com');
  }

  static bool isInstagram(String url) {
    final uri = tryParse(url);
    if (uri == null) return false;
    final host = _host(uri);
    return host == 'instagram.com' ||
        host == 'instagr.am' ||
        host.endsWith('.instagram.com');
  }

  static bool isYouTubeOrInstagram(String url) =>
      isYouTube(url) || isInstagram(url);

  static String? youtubeVideoId(String url) {
    final uri = tryParse(url);
    if (uri == null || !isYouTube(url)) return null;
    final host = _host(uri);
    if (host == 'youtu.be') {
      return uri.pathSegments.isEmpty ? null : uri.pathSegments.first;
    }
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

  static String? introVideoError(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    if (!isYouTubeOrInstagram(text)) {
      return 'Use a YouTube or Instagram link';
    }
    return null;
  }
}
