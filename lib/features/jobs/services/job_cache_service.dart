import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:bombay_casting/core/models/models.dart';
import 'package:bombay_casting/core/services/cache_ttl.dart';

/// Persists the newest jobs on disk so a cold start does not wait on Firestore.
class JobCacheService {
  JobCacheService();

  static const fileName = 'jobs_feed_cache.json';
  static const ttl = CacheTtl.feed;
  static const maxJobs = 80;

  Future<File?> _cacheFile() async {
    if (kIsWeb) return null;
    try {
      final dir = await getApplicationDocumentsDirectory();
      return File(p.join(dir.path, fileName));
    } catch (error) {
      debugPrint('Job cache path unavailable: $error');
      return null;
    }
  }

  Future<JobCacheSnapshot?> read() async {
    try {
      final file = await _cacheFile();
      if (file == null || !await file.exists()) return null;
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return null;
      final savedAt = DateTime.tryParse(decoded['saved_at']?.toString() ?? '');
      final rawJobs = decoded['jobs'];
      if (savedAt == null || rawJobs is! List) return null;
      final jobs = [
        for (final item in rawJobs)
          if (item is Map)
            Job.fromJson(Map<String, dynamic>.from(item)),
      ]..sort((a, b) => b.postedAt.compareTo(a.postedAt));
      return JobCacheSnapshot(savedAt: savedAt, jobs: jobs);
    } catch (error) {
      debugPrint('Job cache read failed: $error');
      return null;
    }
  }

  Future<void> write(List<Job> jobs) async {
    try {
      final file = await _cacheFile();
      if (file == null) return;
      final newest = [...jobs]..sort((a, b) => b.postedAt.compareTo(a.postedAt));
      final payload = jsonEncode({
        'saved_at': DateTime.now().toIso8601String(),
        'jobs': [
          for (final job in newest.take(maxJobs)) job.toJson(),
        ],
      });
      await file.writeAsString(payload, flush: true);
    } catch (error) {
      debugPrint('Job cache write failed: $error');
    }
  }
}

class JobCacheSnapshot {
  const JobCacheSnapshot({required this.savedAt, required this.jobs});

  final DateTime savedAt;
  final List<Job> jobs;

  bool get isFresh => DateTime.now().difference(savedAt) < JobCacheService.ttl;
}
