import 'package:bombay_casting/core/models/models.dart';
import 'package:bombay_casting/core/services/cache_ttl.dart';
import 'package:bombay_casting/core/services/disk_json_cache.dart';

/// Persists the influencer profile so the profile tab loads instantly.
class ProfileCacheService {
  ProfileCacheService();

  static const _store = DiskJsonCache('profile_cache.json');

  Future<ProfileCacheSnapshot?> read(String uid) async {
    final payload = await _store.readPayload();
    if (payload == null) return null;
    if ((payload['uid'] ?? '').toString() != uid) return null;
    final savedAt = DateTime.tryParse(payload['saved_at']?.toString() ?? '');
    final rawProfile = payload['profile'];
    if (savedAt == null || rawProfile is! Map) return null;
    return ProfileCacheSnapshot(
      savedAt: savedAt,
      profile: Profile.fromJson(Map<String, dynamic>.from(rawProfile)),
      remoteExists: payload['remote_exists'] == true,
    );
  }

  Future<void> write({
    required String uid,
    required Profile profile,
    required bool remoteExists,
  }) {
    return _store.writePayload({
      'uid': uid,
      'saved_at': DateTime.now().toIso8601String(),
      'remote_exists': remoteExists,
      'profile': profile.toJson(),
    });
  }

  Future<void> clear() => _store.delete();
}

class ProfileCacheSnapshot {
  const ProfileCacheSnapshot({
    required this.savedAt,
    required this.profile,
    required this.remoteExists,
  });

  final DateTime savedAt;
  final Profile profile;
  final bool remoteExists;

  bool get isFresh => cacheEntryIsFresh(savedAt, CacheTtl.profile);
}
