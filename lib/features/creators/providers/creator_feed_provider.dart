import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:bombay_casting/core/models/models.dart';
import 'package:bombay_casting/features/creators/models/creator_profile.dart';
import 'package:bombay_casting/features/creators/services/creator_cache_service.dart';

class CreatorFeed {
  CreatorFeed({
    required FirebaseFirestore firestore,
    required CreatorCacheService cache,
    required VoidCallback onChange,
  })  : _firestore = firestore,
        _cache = cache,
        _onChange = onChange;

  static const pageSize = 30;
  static const firstPaintSize = 12;
  static const slowPageSize = 15;
  static const _maxAutoFillPages = 5;
  static const _slowNetworkThreshold = Duration(milliseconds: 1500);
  static const _userIdChunkSize = 10;

  final FirebaseFirestore _firestore;
  final CreatorCacheService _cache;
  final VoidCallback _onChange;
  final Map<String, CreatorProfile> _creatorsById = {};

  List<CreatorProfile> creators = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMore = true;
  Object? loadError;

  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  int _autoFillPages = 0;
  int _requestId = 0;
  bool _fetchInFlight = false;
  bool _cacheIsFresh = false;
  bool _slowNetwork = false;
  bool _orderedByCreatedAt = true;
  int _fallbackSeed = 1;
  String? _currentUserId;
  CreatorFilter _filter = const CreatorFilter();

  int get _nextPageSize => _slowNetwork ? slowPageSize : pageSize;

  CreatorProfile? byId(String id) => _creatorsById[id];

  void setCurrentUserId(String? userId) => _currentUserId = userId;

  void markAwaitingFirstPage() {
    if (creators.isNotEmpty || isLoading) return;
    isLoading = true;
    _onChange();
  }

  void setFilter(CreatorFilter filter) {
    _filter = filter;
    _autoFillPages = 0;
    _onChange();
    maybeFillFilteredFeed(filter);
  }

  Future<void> hydrateAndLoad() async {
    await _hydrateFromCache();
    if (creators.isEmpty || !_cacheIsFresh) {
      await fetchPage(reset: true);
    }
  }

  Future<void> refresh() => fetchPage(reset: true, fromServer: true);

  Future<void> loadMore() => fetchPage(reset: false);

  void reset() {
    _requestId++;
    creators = [];
    _creatorsById.clear();
    _cursor = null;
    hasMore = true;
    isLoading = false;
    isLoadingMore = false;
    loadError = null;
    _cacheIsFresh = false;
    _slowNetwork = false;
    _autoFillPages = 0;
    _fallbackSeed = 1;
    _currentUserId = null;
    _orderedByCreatedAt = true;
    _filter = const CreatorFilter();
  }

  Future<void> _hydrateFromCache() async {
    final cached = await _cache.read();
    if (cached == null || cached.creators.isEmpty) {
      _cacheIsFresh = false;
      return;
    }
    _cacheIsFresh = cached.isFresh;
    _replaceCreators(cached.creators);
    hasMore = true;
    _cursor = null;
  }

  Future<void> fetchPage({
    required bool reset,
    bool fromServer = false,
  }) async {
    if (!reset && (_fetchInFlight || isLoadingMore || !hasMore)) return;
    if (!reset && isLoading) return;

    final requestId = ++_requestId;
    _fetchInFlight = true;
    if (reset) {
      isLoading = creators.isEmpty;
      isLoadingMore = false;
      loadError = null;
      _autoFillPages = 0;
      _cursor = null;
      if (fromServer) {
        _fallbackSeed = 1;
      }
    } else {
      isLoadingMore = true;
    }
    _onChange();

    try {
      if (reset) {
        await _fetchChunk(
          requestId: requestId,
          fromServer: fromServer,
          limit: firstPaintSize,
          replace: fromServer,
          applyCursor: false,
        );
        if (requestId != _requestId) return;
        isLoading = false;
        final remaining = _nextPageSize - firstPaintSize;
        isLoadingMore = !_slowNetwork && hasMore && remaining > 0;
        _onChange();

        if (isLoadingMore && remaining > 0) {
          await _fetchChunk(
            requestId: requestId,
            fromServer: fromServer,
            limit: remaining,
            replace: false,
            applyCursor: true,
          );
        }
      } else {
        await _fetchChunk(
          requestId: requestId,
          fromServer: fromServer,
          limit: _nextPageSize,
          replace: false,
          applyCursor: true,
        );
      }

      if (requestId == _requestId) {
        loadError = null;
        await _cache.write(creators);
        _cacheIsFresh = true;
      }
    } catch (error) {
      debugPrint('Error loading creators: $error');
      if (requestId == _requestId) {
        loadError = error;
        if (reset && creators.isEmpty) {
          hasMore = false;
        }
      }
    } finally {
      if (requestId == _requestId) {
        isLoading = false;
        isLoadingMore = false;
        _fetchInFlight = false;
        _onChange();
        if (loadError == null) {
          maybeFillFilteredFeed(_filter);
        }
      }
    }
  }

  Future<void> _fetchChunk({
    required int requestId,
    required bool fromServer,
    required int limit,
    required bool replace,
    required bool applyCursor,
  }) async {
    var query = _usersQuery();
    if (applyCursor) query = _applyCursor(query);
    query = query.limit(limit);

    final started = DateTime.now();
    final snapshot = await _getQuery(
      query,
      fromServer: fromServer,
      limit: limit,
    );
    _slowNetwork =
        DateTime.now().difference(started) >= _slowNetworkThreshold;
    if (requestId != _requestId) return;

    final profileIds = [for (final doc in snapshot.docs) doc.id];
    final profilesById = await _profilesByIds(profileIds);
    if (requestId != _requestId) return;

    final page = <CreatorProfile>[];
    for (final doc in snapshot.docs) {
      final creator = _creatorFrom(
        data: Map<String, dynamic>.from(doc.data()),
        id: doc.id,
        profilesById: profilesById,
      );
      if (creator != null) page.add(creator);
    }

    if (replace) {
      _replaceCreators(page);
    } else {
      _mergeCreators(page);
    }

    if (snapshot.docs.isNotEmpty) {
      _cursor = snapshot.docs.last;
    }
    hasMore = snapshot.docs.length >= limit;
  }

  Query<Map<String, dynamic>> _usersQuery() {
    if (_orderedByCreatedAt) {
      return _firestore
          .collection('users')
          .orderBy('created_at', descending: true);
    }
    return _firestore.collection('users');
  }

  Query<Map<String, dynamic>> _applyCursor(
    Query<Map<String, dynamic>> query,
  ) {
    if (_cursor != null) return query.startAfterDocument(_cursor!);
    return query;
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _getQuery(
    Query<Map<String, dynamic>> query, {
    required bool fromServer,
    required int limit,
  }) async {
    try {
      if (fromServer) {
        return await query.get(const GetOptions(source: Source.server));
      }
      return await query.get();
    } catch (error) {
      if (_orderedByCreatedAt) {
        debugPrint('Creators query retry without created_at order: $error');
        _orderedByCreatedAt = false;
        _cursor = null;
        return _firestore.collection('users').limit(limit).get();
      }
      debugPrint('Creators query failed: $error');
      rethrow;
    }
  }

  void maybeFillFilteredFeed(CreatorFilter filter) {
    if (!hasMore || _fetchInFlight || isLoadingMore) return;
    if (_slowNetwork && !filter.isActive) return;
    final visible = creators.where((creator) => filter.matches(creator)).length;
    if (visible >= firstPaintSize) return;
    if (_autoFillPages >= (_slowNetwork ? 1 : _maxAutoFillPages)) return;
    if (creators.isEmpty && !filter.isActive) return;
    _autoFillPages += 1;
    loadMore();
  }

  CreatorProfile? _creatorFrom({
    required Map<String, dynamic> data,
    required String id,
    required Map<String, Profile> profilesById,
  }) {
    final otherProfile = profilesById[id];
    if (otherProfile == null) return null;
    data['id'] = data['id'] ?? id;
    final otherUser = User.fromJson(data);
    final isCurrentUser = id == _currentUserId;
    if (!isCurrentUser && !otherUser.isActive) return null;
    if (!isCurrentUser &&
        otherUser.name.trim().isEmpty &&
        otherProfile.galleryPhotos.isEmpty &&
        otherProfile.city.isEmpty) {
      return null;
    }
    final creator = CreatorProfile.fromRecords(
      user: otherUser,
      profile: otherProfile,
      fallbackIndex: _nextFallbackIndex(),
    );
    return creator;
  }

  int _nextFallbackIndex() {
    final next = _fallbackSeed;
    _fallbackSeed += 4;
    return next;
  }

  Future<Map<String, Profile>> _profilesByIds(List<String> ids) async {
    if (ids.isEmpty) return {};
    final chunks = <List<String>>[];
    for (var i = 0; i < ids.length; i += _userIdChunkSize) {
      chunks.add(
        ids.sublist(
          i,
          i + _userIdChunkSize > ids.length ? ids.length : i + _userIdChunkSize,
        ),
      );
    }
    final snapshots = await Future.wait([
      for (final chunk in chunks)
        _firestore
            .collection('profiles')
            .where(FieldPath.documentId, whereIn: chunk)
            .get(),
    ]);
    return {
      for (final snapshot in snapshots)
        for (final doc in snapshot.docs)
          doc.id: Profile.fromJson({
            ...Map<String, dynamic>.from(doc.data()),
            'user_id': doc.id,
          }),
    };
  }

  void _replaceCreators(List<CreatorProfile> next) {
    final sorted = [...next]..sort(_byCreatedAtDesc);
    creators = sorted;
    _creatorsById
      ..clear()
      ..addEntries(sorted.map((creator) => MapEntry(creator.id, creator)));
    _fallbackSeed = sorted.length * 4 + 1;
  }

  void _mergeCreators(List<CreatorProfile> incoming) {
    final byId = {for (final creator in creators) creator.id: creator};
    for (final creator in incoming) {
      byId[creator.id] = creator;
      _creatorsById[creator.id] = creator;
    }
    creators = byId.values.toList()..sort(_byCreatedAtDesc);
  }

  int _byCreatedAtDesc(CreatorProfile a, CreatorProfile b) {
    final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bTime.compareTo(aTime);
  }
}
