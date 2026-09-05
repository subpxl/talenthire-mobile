/// Normalizes social profile inputs into working URLs and handles.
class SocialLinkUtils {
  SocialLinkUtils._();

  static String normalizeUrl(String platform, String input) {
    final value = input.trim();
    if (value.isEmpty) return '';

    switch (platform.trim().toLowerCase()) {
      case 'instagram':
        return _normalizeInstagram(value);
      case 'youtube':
        return _normalizeYouTube(value);
      case 'facebook':
        return _normalizeFacebook(value);
      case 'imdb':
        return _normalizeImdb(value);
      case 'website':
        return _normalizeWebsite(value);
      default:
        return _normalizeWebsite(value);
    }
  }

  static String extractHandle(String platform, String input) {
    final normalized = normalizeUrl(platform, input);
    if (normalized.isEmpty) return _stripAt(input.trim());

    switch (platform.trim().toLowerCase()) {
      case 'instagram':
        return _pathSegment(normalized, fallback: input);
      case 'youtube':
        return _extractYouTubeHandle(normalized, input);
      case 'facebook':
        return _pathSegment(normalized, fallback: input);
      case 'imdb':
        return _extractImdbHandle(normalized, input);
      case 'website':
        return normalized;
      default:
        return normalized;
    }
  }

  static String displayValue(
    String platform, {
    required String url,
    required String handle,
  }) {
    final resolvedUrl = url.trim().isNotEmpty ? url : handle;
    if (resolvedUrl.isEmpty) return '';

    final normalized = normalizeUrl(platform, resolvedUrl);
    final resolvedHandle = handle.trim().isNotEmpty
        ? handle.trim()
        : extractHandle(platform, normalized);

    switch (platform.trim().toLowerCase()) {
      case 'instagram':
      case 'youtube':
        if (resolvedHandle.isEmpty) return resolvedUrl;
        return resolvedHandle.startsWith('@')
            ? resolvedHandle
            : '@$resolvedHandle';
      default:
        return resolvedHandle.isNotEmpty ? resolvedHandle : normalized;
    }
  }

  static String resolveLaunchUrl(
    String platform, {
    required String url,
    required String handle,
  }) {
    final raw = url.trim().isNotEmpty ? url : handle;
    if (raw.isEmpty) return '';
    return normalizeUrl(platform, raw);
  }

  static String? validationError(String platform, String input) {
    final value = input.trim();
    if (value.isEmpty) return null;

    final normalized = normalizeUrl(platform, value);
    if (normalized.isEmpty) {
      return _invalidMessage(platform);
    }

    final uri = Uri.tryParse(normalized);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return _invalidMessage(platform);
    }

    switch (platform.trim().toLowerCase()) {
      case 'instagram':
        final handle = extractHandle(platform, normalized);
        if (!_isValidHandle(handle)) {
          return _invalidMessage(platform);
        }
        break;
      case 'youtube':
        final handle = extractHandle(platform, normalized);
        if (handle.isEmpty) {
          return _invalidMessage(platform);
        }
        break;
      case 'facebook':
        final handle = extractHandle(platform, normalized);
        if (!_isValidHandle(handle)) {
          return _invalidMessage(platform);
        }
        break;
      case 'imdb':
        final handle = extractHandle(platform, normalized);
        if (!_isValidImdbHandle(handle)) {
          return _invalidMessage(platform);
        }
        break;
      case 'website':
        if (!_isValidWebsiteHost(uri.host)) {
          return _invalidMessage(platform);
        }
        break;
    }

    return null;
  }

  static String _invalidMessage(String platform) {
    switch (platform.trim().toLowerCase()) {
      case 'instagram':
        return 'Enter a valid Instagram username or profile URL';
      case 'youtube':
        return 'Enter a valid YouTube channel link or handle';
      case 'facebook':
        return 'Enter a valid Facebook profile or page URL';
      case 'imdb':
        return 'Enter a valid IMDb profile link or ID';
      case 'website':
        return 'Enter a valid website URL';
      default:
        return 'Enter a valid link';
    }
  }

  static bool _isValidHandle(String handle) {
    final value = _stripAt(handle.trim());
    return value.isNotEmpty && RegExp(r'^[\w.]+$').hasMatch(value);
  }

  static bool _isValidImdbHandle(String handle) {
    final value = handle.trim();
    return RegExp(r'^(name/)?nm\d+$', caseSensitive: false).hasMatch(value) ||
        value.isNotEmpty && RegExp(r'^nm\d+$', caseSensitive: false).hasMatch(value);
  }

  static bool _isValidWebsiteHost(String host) {
    final normalized = host.toLowerCase();
    if (normalized == 'localhost') return true;
    return normalized.contains('.');
  }

  static String _normalizeInstagram(String value) {
    final lower = value.toLowerCase();
    if (lower.contains('instagram.com') || lower.contains('instagr.am')) {
      return _ensureScheme(value);
    }

    final username = _stripAt(value).replaceAll('/', '');
    if (username.isEmpty) return '';
    return 'https://instagram.com/$username';
  }

  static String _normalizeYouTube(String value) {
    final lower = value.toLowerCase();
    if (lower.contains('youtube.com') || lower.contains('youtu.be')) {
      return _ensureScheme(value);
    }

    final stripped = _stripAt(value);
    if (RegExp(r'^UC[\w-]{22}$').hasMatch(stripped)) {
      return 'https://youtube.com/channel/$stripped';
    }
    if (stripped.startsWith('channel/') ||
        stripped.startsWith('c/') ||
        stripped.startsWith('user/')) {
      return 'https://youtube.com/$stripped';
    }

    final handle = stripped.startsWith('@') ? stripped : '@$stripped';
    return 'https://youtube.com/$handle';
  }

  static String _normalizeFacebook(String value) {
    final lower = value.toLowerCase();
    if (lower.contains('facebook.com') || lower.contains('fb.com')) {
      return _ensureScheme(value);
    }

    final page = _stripAt(value).replaceAll('/', '');
    if (page.isEmpty) return '';
    return 'https://facebook.com/$page';
  }

  static String _normalizeImdb(String value) {
    final lower = value.toLowerCase();
    if (lower.contains('imdb.com')) {
      return _ensureScheme(value);
    }

    final id = _stripAt(value);
    if (RegExp(r'^nm\d+$', caseSensitive: false).hasMatch(id)) {
      return 'https://www.imdb.com/name/${id.toLowerCase()}';
    }
    if (id.startsWith('name/')) {
      return 'https://www.imdb.com/$id';
    }
    if (id.isEmpty) return '';
    return 'https://www.imdb.com/name/$id';
  }

  static String _normalizeWebsite(String value) {
    return _ensureScheme(value);
  }

  static String _ensureScheme(String value) {
    if (RegExp(r'^https?://', caseSensitive: false).hasMatch(value)) {
      return value;
    }
    return 'https://$value';
  }

  static String _stripAt(String value) => value.startsWith('@') ? value.substring(1) : value;

  static String _pathSegment(String url, {required String fallback}) {
    final uri = Uri.tryParse(url);
    if (uri == null) return _stripAt(fallback);
    final segments = uri.pathSegments.where((segment) => segment.isNotEmpty).toList();
    if (segments.isEmpty) return _stripAt(fallback);
    return segments.last;
  }

  static String _extractYouTubeHandle(String normalized, String fallback) {
    final uri = Uri.tryParse(normalized);
    if (uri == null) return _stripAt(fallback);

    final segments = uri.pathSegments.where((segment) => segment.isNotEmpty).toList();
    if (segments.isEmpty) return _stripAt(fallback);

    if (segments.first == 'channel' && segments.length > 1) {
      return segments[1];
    }
    if (segments.first.startsWith('@')) {
      return segments.first;
    }
    if (segments.length > 1 &&
        {'c', 'user'}.contains(segments.first.toLowerCase())) {
      return segments[1];
    }
    return segments.last;
  }

  static String _extractImdbHandle(String normalized, String fallback) {
    final uri = Uri.tryParse(normalized);
    if (uri == null) return _stripAt(fallback);

    final segments = uri.pathSegments.where((segment) => segment.isNotEmpty).toList();
    if (segments.length >= 2 && segments.first.toLowerCase() == 'name') {
      return segments[1];
    }
    if (segments.isNotEmpty) return segments.last;
    return _stripAt(fallback);
  }
}
