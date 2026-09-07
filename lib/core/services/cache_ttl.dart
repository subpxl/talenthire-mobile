/// Shared TTL values for on-device caches (Phase 1 caching).
class CacheTtl {
  CacheTtl._();

  /// Job and creator home feeds.
  static const feed = Duration(hours: 3);

  /// Signed-in user account doc.
  static const user = Duration(hours: 6);

  /// Influencer profile document.
  static const profile = Duration(hours: 6);

  /// Applications + saved jobs/creators for a session.
  static const session = Duration(hours: 3);
}

bool cacheEntryIsFresh(DateTime savedAt, Duration ttl) =>
    DateTime.now().difference(savedAt) < ttl;
