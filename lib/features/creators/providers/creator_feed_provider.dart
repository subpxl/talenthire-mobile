import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:bombay_casting/core/models/models.dart';
import 'package:bombay_casting/features/creators/models/creator_profile.dart';
import 'package:bombay_casting/features/creators/services/creator_cache_service.dart';
import 'package:bombay_casting/features/creators/utils/creator_feed_sort.dart';

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
  List<CreatorProfile> pendingCreators = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMore = true;
  Object? loadError;

  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  String? _lastPaginationDocId;
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
    pendingCreators.clear();
    _onChange();
    maybeFillFilteredFeed(filter);
  }

  void applyPending() {
    if (pendingCreators.isEmpty) return;
    _mergeCreatorsInPlace(pendingCreators);
    pendingCreators.clear();
    _onChange();
  }

  Future<void> hydrateAndLoad() async {
    await _hydrateFromCache();
    if (creators.isEmpty) {
      await fetchPage(reset: true);
      return;
    }

    isLoading = false;
    _onChange();
    if (!_cacheIsFresh) {
      unawaited(_syncStaleFeed());
    } else {
      unawaited(_establishPaginationCursor());
    }
  }

  Future<void> refresh() => fetchPage(reset: true, fromServer: true);

  Future<void> loadMore() async {
    if (_cursor == null && creators.isNotEmpty && !_fetchInFlight) {
      await _establishPaginationCursor();
    }
    await fetchPage(reset: false);
  }

  void reset() {
    _requestId++;
    creators = [];
    pendingCreators.clear();
    _creatorsById.clear();
    _cursor = null;
    _lastPaginationDocId = null;
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
    hasMore = cached.creators.length >= CreatorCacheService.maxCreators;
    _cursor = null;
    _lastPaginationDocId = cached.lastPaginationDocId;
  }

  /// Refreshes cached rows in place without clearing the list or pagination.
  Future<void> _syncStaleFeed() async {
    if (_fetchInFlight || creators.isEmpty) return;
    _fetchInFlight = true;
    try {
      await _fetchChunk(
        requestId: _requestId,
        fromServer: false,
        limit: _nextPageSize,
        replace: false,
        applyCursor: false,
        notify: false,
        queueNew: true,
      );
      await _cache.write(
        creators,
        lastPaginationDocId: _lastPaginationDocId,
      );
      _cacheIsFresh = true;
    } catch (error) {
      debugPrint('Stale creator feed sync failed: $error');
    } finally {
      _fetchInFlight = false;
      _onChange();
      unawaited(_establishPaginationCursor());
    }
  }

  /// Aligns [_cursor] with how many creator user docs are already shown.
  Future<void> _establishPaginationCursor() async {
    if (_cursor != null || creators.isEmpty || _fetchInFlight) return;

    final limit = creators.length.clamp(1, CreatorCacheService.maxCreators);
    var query = _usersQuery().limit(limit);
    final snapshot = await _getQuery(
      query,
      fromServer: false,
      limit: limit,
    );

    if (snapshot.docs.isEmpty) {
      hasMore = false;
      return;
    }

    _cursor = snapshot.docs.last;
    _lastPaginationDocId = _cursor!.id;
    hasMore = snapshot.docs.length >= limit;
  }

  Future<void> fetchPage({
    required bool reset,
    bool fromServer = false,
  }) async {
    if (!reset && (_fetchInFlight || isLoadingMore || !hasMore)) return;
    if (!reset && isLoading) return;

    final requestId = ++_requestId;
    _fetchInFlight = true;
    final notifyLoading = reset ? creators.isEmpty : true;
    if (reset) {
      isLoading = creators.isEmpty;
      isLoadingMore = false;
      loadError = null;
      _autoFillPages = 0;
      if (fromServer) {
        _cursor = null;
        _lastPaginationDocId = null;
        _fallbackSeed = 1;
      }
    } else {
      isLoadingMore = true;
    }
    if (notifyLoading) _onChange();

    try {
      if (reset) {
        await _fetchChunk(
          requestId: requestId,
          fromServer: fromServer,
          limit: firstPaintSize,
          replace: fromServer,
          applyCursor: false,
          notify: false,
        );
        if (requestId != _requestId) return;
        isLoading = false;
        final remaining = _nextPageSize - firstPaintSize;
        final loadSecondChunk =
            !_slowNetwork && hasMore && remaining > 0;
        isLoadingMore = loadSecondChunk;

        if (loadSecondChunk) {
          await _fetchChunk(
            requestId: requestId,
            fromServer: fromServer,
            limit: remaining,
            replace: false,
            applyCursor: true,
            notify: false,
          );
        }
      } else {
        await _fetchChunk(
          requestId: requestId,
          fromServer: fromServer,
          limit: _nextPageSize,
          replace: false,
          applyCursor: true,
          notify: false,
        );
      }

      if (requestId == _requestId) {
        loadError = null;
        await _cache.write(
          creators,
          lastPaginationDocId: _lastPaginationDocId,
        );
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
    bool notify = true,
    bool queueNew = false,
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

    final page = <CreatorProfile>[];
    final missingDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

    for (final doc in snapshot.docs) {
      final data = Map<String, dynamic>.from(doc.data());
      if (data['profile_deleted_at'] != null) continue;
      if (data['account_deleted_at'] != null) continue;
      final feedCard = data['feed_card'];
      if (feedCard is Map) {
        final creator = CreatorProfile.fromFeedCard(
          userData: data,
          userId: doc.id,
          feedCard: Map<String, dynamic>.from(feedCard),
          fallbackIndex: _nextFallbackIndex(),
          currentUserId: _currentUserId,
        );
        if (creator != null) {
          page.add(creator);
          continue;
        }
      }
      missingDocs.add(doc);
    }

    if (missingDocs.isNotEmpty) {
      final profilesById = await _profilesByIds(
        missingDocs.map((doc) => doc.id).toList(),
      );
      if (requestId != _requestId) return;

      for (final doc in missingDocs) {
        final creator = _creatorFrom(
          data: Map<String, dynamic>.from(doc.data()),
          id: doc.id,
          profilesById: profilesById,
        );
        if (creator != null) page.add(creator);
      }
    }

    if (replace) {
      _replaceCreators(page);
    } else {
      if (queueNew) {
        for (final c in page) {
          final existing = _creatorsById[c.id];
          if (existing == null || existing.profileScore != c.profileScore || existing.hasPhoto != c.hasPhoto) {
            // Significant change or new user -> queue to prevent feed jump
            final pendingIndex = pendingCreators.indexWhere((p) => p.id == c.id);
            if (pendingIndex >= 0) {
              pendingCreators[pendingIndex] = c;
            } else {
              pendingCreators.add(c);
            }
          } else {
            // Minor update -> apply in place silently
            final index = creators.indexWhere((x) => x.id == c.id);
            if (index >= 0) creators[index] = c;
            _creatorsById[c.id] = c;
          }
        }
      } else {
        _mergeCreatorsInPlace(page);
      }
    }

    if (notify || (queueNew && pendingCreators.isNotEmpty)) _onChange();

    if (snapshot.docs.isNotEmpty) {
      _cursor = snapshot.docs.last;
      _lastPaginationDocId = _cursor!.id;
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
    if (!filter.isActive) return;
    if (!hasMore || _fetchInFlight || isLoadingMore) return;
    if (_slowNetwork) return;
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
    if (otherProfile.accountStatus == AccountStatus.deleted) return null;
    data['id'] = data['id'] ?? id;
    final otherUser = User.fromJson(data);
    final isCurrentUser = id == _currentUserId;
    if (!isCurrentUser && !otherUser.isActive) return null;
    if (!isCurrentUser && otherUser.isAccountDeleted) return null;
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
    final sorted = [...next]..sort(compareCreatorsForFeed);
    creators = sorted;
    _creatorsById
      ..clear()
      ..addEntries(sorted.map((creator) => MapEntry(creator.id, creator)));
    _fallbackSeed = sorted.length * 4 + 1;
  }

  void _mergeCreatorsInPlace(List<CreatorProfile> incoming) {
    if (incoming.isEmpty) return;

    final sortedIncoming = [...incoming]..sort(compareCreatorsForFeed);
    for (final creator in sortedIncoming) {
      _creatorsById[creator.id] = creator;
      final existingIndex = creators.indexWhere((c) => c.id == creator.id);
      if (existingIndex >= 0) {
        creators.removeAt(existingIndex);
      }
      final insertAt = insertIndexForCreator(creator, creators);
      creators.insert(insertAt, creator);
    }
  }
}
