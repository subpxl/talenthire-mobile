class DeepLinkTarget {
  const DeepLinkTarget({required this.kind, required this.id});

  final DeepLinkKind kind;
  final String id;

  static const host = 'bombaycastingcompany.com';
  static const origin = 'https://$host';
  static const playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.bombaycastingcompany.app';

  static String creatorUrl(String id) => '$origin/c/$id';
  static String jobUrl(String id) => '$origin/j/$id';
  static String agencyUrl(String id) => '$origin/a/$id';

  static DeepLinkTarget? tryParse(Uri uri) {
    final incomingHost = uri.host.toLowerCase();
    if (incomingHost != host && incomingHost != 'www.$host') return null;
    final parts = uri.pathSegments.where((part) => part.isNotEmpty).toList();
    if (parts.length < 2) return null;
    final kind = DeepLinkKind.fromPath(parts[0]);
    final id = Uri.decodeComponent(parts[1]).trim();
    if (kind == null || id.isEmpty) return null;
    return DeepLinkTarget(kind: kind, id: id);
  }

  @override
  bool operator ==(Object other) {
    return other is DeepLinkTarget && other.kind == kind && other.id == id;
  }

  @override
  int get hashCode => Object.hash(kind, id);
}

enum DeepLinkKind {
  creator,
  job,
  agency;

  static DeepLinkKind? fromPath(String segment) {
    switch (segment) {
      case 'c':
        return DeepLinkKind.creator;
      case 'j':
        return DeepLinkKind.job;
      case 'a':
        return DeepLinkKind.agency;
      default:
        return null;
    }
  }
}
