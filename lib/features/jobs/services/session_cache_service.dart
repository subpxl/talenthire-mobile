import 'package:bombay_casting/core/models/models.dart';
import 'package:bombay_casting/core/services/cache_ttl.dart';
import 'package:bombay_casting/core/services/disk_json_cache.dart';
import 'package:bombay_casting/features/creators/models/creator_profile.dart';

/// Persists applications and saved lists for faster session startup.
class SessionCacheService {
  SessionCacheService();

  static const _store = DiskJsonCache('session_cache.json');

  Future<SessionCacheSnapshot?> read(String uid) async {
    final payload = await _store.readPayload();
    if (payload == null) return null;
    if ((payload['uid'] ?? '').toString() != uid) return null;
    final savedAt = DateTime.tryParse(payload['saved_at']?.toString() ?? '');
    if (savedAt == null) return null;

    final applications = <Application>[];
    final rawApplications = payload['applications'];
    if (rawApplications is List) {
      for (final item in rawApplications) {
        if (item is Map) {
          applications.add(
            Application.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    final savedJobs = <Job>[];
    final rawSavedJobs = payload['saved_jobs'];
    if (rawSavedJobs is List) {
      for (final item in rawSavedJobs) {
        if (item is Map) {
          savedJobs.add(Job.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final savedCreators = <CreatorProfile>[];
    final rawSavedCreators = payload['saved_creators'];
    if (rawSavedCreators is List) {
      for (final item in rawSavedCreators) {
        if (item is Map) {
          savedCreators.add(
            CreatorProfile.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return SessionCacheSnapshot(
      savedAt: savedAt,
      applications: applications,
      savedJobs: savedJobs,
      savedCreators: savedCreators,
    );
  }

  Future<void> write({
    required String uid,
    required List<Application> applications,
    required List<Job> savedJobs,
    required List<CreatorProfile> savedCreators,
  }) {
    return _store.writePayload({
      'uid': uid,
      'saved_at': DateTime.now().toIso8601String(),
      'applications': [for (final item in applications) item.toJson()],
      'saved_jobs': [for (final item in savedJobs) item.toJson()],
      'saved_creators': [
        for (final item in savedCreators) item.toJson(),
      ],
    });
  }

  Future<void> clear() => _store.delete();
}

class SessionCacheSnapshot {
  const SessionCacheSnapshot({
    required this.savedAt,
    required this.applications,
    required this.savedJobs,
    required this.savedCreators,
  });

  final DateTime savedAt;
  final List<Application> applications;
  final List<Job> savedJobs;
  final List<CreatorProfile> savedCreators;

  bool get isFresh => cacheEntryIsFresh(savedAt, CacheTtl.session);
}
