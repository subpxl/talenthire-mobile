import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:bombay_casting/features/jobs/models/job_listing.dart';
import 'package:bombay_casting/core/models/models.dart';
import 'package:bombay_casting/features/jobs/services/job_cache_service.dart';

class JobFeed {
  JobFeed({
    required this._firestore,
    required this._cache,
    required this._onChange,
  });

  static const pageSize = 40;
  static const firstPaintSize = 12;
  static const slowPageSize = 20;
  static const _maxAutoFillPages = 5;
  static const _slowNetworkThreshold = Duration(milliseconds: 1500);

  final FirebaseFirestore _firestore;
  final JobCacheService _cache;
  final VoidCallback _onChange;
  final Map<String, Job> _jobsById = {};

  List<Job> jobs = [];
  HomeJobFilter filter = const HomeJobFilter();
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
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _realtimeSub;

  int get _nextPageSize => _slowNetwork ? slowPageSize : pageSize;

  List<JobListing> get filteredListings => listingsForJobs(jobs, filter);

  Job? byId(String jobId) => _jobsById[jobId];

  void index(Job job) => _jobsById[job.id] = job;

  void markAwaitingFirstPage() {
    if (jobs.isNotEmpty || isLoading) return;
    isLoading = true;
    _onChange();
  }

  void setFilter(HomeJobFilter next) {
    filter = next;
    _autoFillPages = 0;
    _onChange();
    maybeFillFilteredFeed();
  }

  Future<void> hydrateAndLoad() async {
    await _hydrateFromCache();
    if (jobs.isEmpty) {
      await fetchPage(reset: true);
    } else if (!_cacheIsFresh) {
      unawaited(fetchPage(reset: true));
    }
  }

  Future<void> refresh() => fetchPage(reset: true, fromServer: true);

  Future<void> loadMore() => fetchPage(reset: false);

  /// Starts a real-time listener on the newest [limit] published jobs.
  /// Any new job posted by an agency appears immediately in the feed
  /// without requiring a manual pull-to-refresh.
  void startRealtimeListener({int limit = 40}) {
    _realtimeSub?.cancel();
    _realtimeSub = _publishedQuery()
        .limit(limit)
        .snapshots()
        .listen(_onRealtimeSnapshot, onError: (_) {});
  }

  void stopRealtimeListener() {
    _realtimeSub?.cancel();
    _realtimeSub = null;
  }

  void _onRealtimeSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final incoming = snapshot.docs
        .map(_jobFromDoc)
        .where((job) => job.status == JobStatus.published)
        .toList();
    if (incoming.isEmpty) return;
    _mergeJobs(incoming);
    _onChange();
  }

  void reset() {
    stopRealtimeListener();
    _requestId++;
    jobs = [];
    _jobsById.clear();
    _cursor = null;
    hasMore = true;
    isLoading = false;
    isLoadingMore = false;
    loadError = null;
    _cacheIsFresh = false;
    _slowNetwork = false;
    _autoFillPages = 0;
  }

  Future<void> _hydrateFromCache() async {
    final cached = await _cache.read();
    if (cached == null || cached.jobs.isEmpty) {
      _cacheIsFresh = false;
      return;
    }
    _cacheIsFresh = cached.isFresh;
    _replaceJobs(cached.jobs);
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
      isLoading = jobs.isEmpty;
      isLoadingMore = false;
      loadError = null;
      _autoFillPages = 0;
      _cursor = null;
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

        if (isLoadingMore) {
          if (remaining > 0) {
            await _fetchChunk(
              requestId: requestId,
              fromServer: fromServer,
              limit: remaining,
              replace: false,
              applyCursor: true,
            );
          }
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
        if (reset && !fromServer && jobs.length > _nextPageSize) {
          _cursor = null;
          hasMore = true;
        }
        await _cache.write(jobs);
        _cacheIsFresh = true;
      }
    } catch (error) {
      debugPrint('Error loading jobs: $error');
      if (requestId == _requestId) {
        loadError = error;
        if (reset && jobs.isEmpty) {
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
          maybeFillFilteredFeed();
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
    var query = _publishedQuery();
    if (applyCursor) query = _applyCursor(query);
    query = query.limit(limit);

    final started = DateTime.now();
    final snapshot = await _getQuery(query, fromServer: fromServer, limit: limit);
    _slowNetwork = DateTime.now().difference(started) >= _slowNetworkThreshold;
    if (requestId != _requestId) return;

    final page = snapshot.docs
        .map(_jobFromDoc)
        .where((job) => job.status == JobStatus.published)
        .toList();

    if (replace) {
      _replaceJobs(page);
    } else {
      _mergeJobs(page);
    }

    if (snapshot.docs.isNotEmpty) {
      _cursor = snapshot.docs.last;
    }
    hasMore = snapshot.docs.length >= limit;
  }

  Query<Map<String, dynamic>> _publishedQuery() {
    return _firestore
        .collection('jobs')
        .where('status', isEqualTo: 'published')
        .orderBy('posted_at', descending: true);
  }

  Query<Map<String, dynamic>> _applyCursor(Query<Map<String, dynamic>> query) {
    if (_cursor != null) return query.startAfterDocument(_cursor!);
    if (jobs.isEmpty) return query;
    return query.startAfter([Timestamp.fromDate(jobs.last.postedAt)]);
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
      debugPrint('Jobs query retry: $error');
      try {
        return await query.get();
      } catch (fallbackError) {
        debugPrint(
          'Published jobs query failed, trying freshness only: $fallbackError',
        );
        var fallback = _firestore
            .collection('jobs')
            .orderBy('posted_at', descending: true);
        if (_cursor != null) {
          fallback = fallback.startAfterDocument(_cursor!);
        } else if (jobs.isNotEmpty) {
          fallback = fallback.startAfter([
            Timestamp.fromDate(jobs.last.postedAt),
          ]);
        }
        return fallback.limit(limit).get();
      }
    }
  }

  void maybeFillFilteredFeed() {
    if (!hasMore || _fetchInFlight || isLoadingMore) return;
    if (_slowNetwork && !filter.isActive) return;
    if (filteredListings.length >= firstPaintSize) return;
    if (_autoFillPages >= (_slowNetwork ? 1 : _maxAutoFillPages)) return;
    if (jobs.isEmpty && !filter.isActive) return;
    _autoFillPages += 1;
    loadMore();
  }

  Job _jobFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = Map<String, dynamic>.from(doc.data());
    final embeddedId = data['id']?.toString() ?? '';
    data['id'] = embeddedId.isNotEmpty ? embeddedId : doc.id;
    return Job.fromJson(data);
  }

  void _replaceJobs(List<Job> next) {
    final sorted = [...next]..sort((a, b) => b.postedAt.compareTo(a.postedAt));
    jobs = sorted;
    for (final job in sorted) {
      _jobsById[job.id] = job;
    }
  }

  void _mergeJobs(List<Job> incoming) {
    final byId = {for (final job in jobs) job.id: job};
    for (final job in incoming) {
      byId[job.id] = job;
      _jobsById[job.id] = job;
    }
    jobs = byId.values.toList()
      ..sort((a, b) => b.postedAt.compareTo(a.postedAt));
  }
}
