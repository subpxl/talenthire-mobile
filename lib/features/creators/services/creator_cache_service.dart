import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:bombay_casting/core/services/cache_ttl.dart';
import 'package:bombay_casting/features/creators/models/creator_profile.dart';
import 'package:bombay_casting/features/creators/utils/creator_feed_sort.dart';

/// Persists the newest creators on disk so a cold start does not wait on Firestore.
class CreatorCacheService {
  CreatorCacheService();

  static const fileName = 'creators_feed_cache.json';
  static const ttl = CacheTtl.feed;
  static const maxCreators = 80;

  Future<File?> _cacheFile() async {
    if (kIsWeb) return null;
    try {
      final dir = await getApplicationDocumentsDirectory();
      return File(p.join(dir.path, fileName));
    } catch (error) {
      debugPrint('Creator cache path unavailable: $error');
      return null;
    }
  }

  Future<CreatorCacheSnapshot?> read() async {
    try {
      final file = await _cacheFile();
      if (file == null || !await file.exists()) return null;
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return null;
      final savedAt = DateTime.tryParse(decoded['saved_at']?.toString() ?? '');
      final rawCreators = decoded['creators'];
      final lastPaginationDocId =
          decoded['last_pagination_doc_id']?.toString().trim();
      if (savedAt == null || rawCreators is! List) return null;
      final creators = [
        for (final item in rawCreators)
          if (item is Map)
            CreatorProfile.fromJson(Map<String, dynamic>.from(item)),
      ]..sort(compareCreatorsForFeed);
      return CreatorCacheSnapshot(
        savedAt: savedAt,
        creators: creators,
        lastPaginationDocId: lastPaginationDocId?.isNotEmpty == true
            ? lastPaginationDocId
            : null,
      );
    } catch (error) {
      debugPrint('Creator cache read failed: $error');
      return null;
    }
  }

  Future<void> write(
    List<CreatorProfile> creators, {
    String? lastPaginationDocId,
  }) async {
    try {
      final file = await _cacheFile();
      if (file == null) return;
      final newest = [...creators]..sort(compareCreatorsForFeed);
      final payload = jsonEncode({
        'saved_at': DateTime.now().toIso8601String(),
        if (lastPaginationDocId != null && lastPaginationDocId.isNotEmpty)
          'last_pagination_doc_id': lastPaginationDocId,
        'creators': [
          for (final creator in newest.take(maxCreators)) creator.toJson(),
        ],
      });
      await file.writeAsString(payload, flush: true);
    } catch (error) {
      debugPrint('Creator cache write failed: $error');
    }
  }
}

class CreatorCacheSnapshot {
  const CreatorCacheSnapshot({
    required this.savedAt,
    required this.creators,
    this.lastPaginationDocId,
  });

  final DateTime savedAt;
  final List<CreatorProfile> creators;
  final String? lastPaginationDocId;

  bool get isFresh =>
      DateTime.now().difference(savedAt) < CreatorCacheService.ttl;
}
