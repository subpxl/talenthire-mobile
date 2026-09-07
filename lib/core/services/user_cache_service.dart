import 'package:bombay_casting/core/models/models.dart';
import 'package:bombay_casting/core/services/cache_ttl.dart';
import 'package:bombay_casting/core/services/disk_json_cache.dart';

/// Persists the signed-in user doc so login can render instantly.
class UserCacheService {
  UserCacheService();

  static const _store = DiskJsonCache('user_cache.json');

  Future<UserCacheSnapshot?> read(String uid) async {
    final payload = await _store.readPayload();
    if (payload == null) return null;
    if ((payload['uid'] ?? '').toString() != uid) return null;
    final savedAt = DateTime.tryParse(payload['saved_at']?.toString() ?? '');
    final rawUser = payload['user'];
    if (savedAt == null || rawUser is! Map) return null;
    return UserCacheSnapshot(
      savedAt: savedAt,
      user: User.fromJson(Map<String, dynamic>.from(rawUser)),
    );
  }

  Future<void> write(String uid, User user) {
    return _store.writePayload({
      'uid': uid,
      'saved_at': DateTime.now().toIso8601String(),
      'user': user.toJson(),
    });
  }

  Future<void> clear() => _store.delete();
}

class UserCacheSnapshot {
  const UserCacheSnapshot({required this.savedAt, required this.user});

  final DateTime savedAt;
  final User user;

  bool get isFresh => cacheEntryIsFresh(savedAt, CacheTtl.user);
}
