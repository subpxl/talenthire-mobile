import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:bombay_casting/core/models/models.dart';
import 'package:bombay_casting/features/creators/models/creator_profile.dart';
import 'package:bombay_casting/features/jobs/models/job_listing.dart';
import 'package:bombay_casting/features/jobs/providers/job_feed_provider.dart';
import 'package:bombay_casting/features/jobs/services/job_cache_service.dart';

class JobState extends ChangeNotifier {
  JobState({required this._onChange}) {
    jobFeed = JobFeed(
      firestore: _firestore,
      cache: jobCache,
      onChange: _notify,
    );
  }

  final JobCacheService jobCache = JobCacheService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final VoidCallback _onChange;
  late final JobFeed jobFeed;

  static const _creatorsTtl = Duration(minutes: 15);
  static const _userIdChunkSize = 10;

  List<Application> applications = [];
  List<Job> savedJobs = [];
  List<CreatorProfile> savedCreators = [];
  List<CreatorProfile> creators = [];
  bool isLoadingCreators = false;
  DateTime? _creatorsLoadedAt;
  int _loadGeneration = 0;

  List<Job> get jobs => jobFeed.jobs;
  bool get isLoadingJobs => jobFeed.isLoading;
  bool get isLoadingMoreJobs => jobFeed.isLoadingMore;
  bool get hasMoreJobs => jobFeed.hasMore;
  HomeJobFilter get jobFilter => jobFeed.filter;
  List<JobListing> get filteredJobListings => jobFeed.filteredListings;

  void _notify() {
    notifyListeners();
    _onChange();
  }

  bool isJobSaved(String jobId) => savedJobs.any((job) => job.id == jobId);

  bool isCreatorSaved(String creatorId) =>
      savedCreators.any((creator) => creator.id == creatorId);

  Job? jobById(String jobId) => jobFeed.byId(jobId);

  void setJobFilter(HomeJobFilter filter) => jobFeed.setFilter(filter);

  Future<void> refreshJobs() => jobFeed.refresh();

  Future<void> loadMoreJobs() => jobFeed.loadMore();

  void startBackgroundLoads(String uid, {required bool isNewUser}) {
    final token = ++_loadGeneration;
    if (isNewUser) {
      applications = [];
      savedJobs = [];
      savedCreators = [];
    }
    jobFeed.markAwaitingFirstPage();
    unawaited(_runBackgroundLoads(token, uid, isNewUser: isNewUser));
  }

  Future<void> _runBackgroundLoads(
    int token,
    String uid, {
    required bool isNewUser,
  }) async {
    try {
      if (isNewUser) {
        await jobFeed.hydrateAndLoad();
      } else {
        await Future.wait([
          _loadApplications(uid, token: token),
          _loadSavedJobs(uid, token: token),
          _loadSavedCreators(uid, token: token),
          jobFeed.hydrateAndLoad(),
        ]);
      }
    } catch (error) {
      debugPrint('Error loading session data: $error');
    } finally {
      if (token == _loadGeneration) _notify();
    }
  }

  Future<void> refreshSavedJobs(String uid) async {
    await _loadSavedJobs(uid, token: _loadGeneration);
    _notify();
  }

  Future<void> refreshSavedCreators(String uid) async {
    await _loadSavedCreators(uid, token: _loadGeneration);
    _notify();
  }

  Future<void> refreshApplications(String uid) async {
    await _loadApplications(uid, token: _loadGeneration);
    _notify();
  }

  Future<void> _loadApplications(String uid, {required int token}) async {
    try {
      final snapshot = await _firestore
          .collection('applications')
          .where('user_id', isEqualTo: uid)
          .get();
      if (token != _loadGeneration) return;
      applications = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        if ((data['id']?.toString() ?? '').isEmpty) data['id'] = doc.id;
        return Application.fromJson(data);
      }).where((item) => item.status != ApplicationStatus.withdrawn).toList();
    } catch (error) {
      debugPrint('Error loading applications: $error');
      if (token != _loadGeneration) return;
      applications = [];
    }
  }

  Future<void> _loadSavedJobs(String uid, {required int token}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('saved_jobs')
          .get();
      if (token != _loadGeneration) return;
      final loaded = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = data['id'] ?? doc.id;
        final job = Job.fromJson(data);
        final savedAt = parseFlexibleDate(data['saved_at']) ?? job.postedAt;
        return (job: job, savedAt: savedAt);
      }).toList()
        ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
      savedJobs = [for (final item in loaded) item.job];
      for (final job in savedJobs) {
        jobFeed.index(job);
      }
    } catch (error) {
      debugPrint('Error loading saved jobs: $error');
      if (token != _loadGeneration) return;
      savedJobs = [];
    }
  }

  Future<void> _loadSavedCreators(String uid, {required int token}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('saved_creators')
          .get();
      if (token != _loadGeneration) return;
      final loaded = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = data['id'] ?? doc.id;
        final creator = CreatorProfile.fromJson(data);
        final savedAt = creator.savedAt ??
            creator.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return (creator: creator, savedAt: savedAt);
      }).toList()
        ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
      savedCreators = [for (final item in loaded) item.creator];
    } catch (error) {
      debugPrint('Error loading saved creators: $error');
      if (token != _loadGeneration) return;
      savedCreators = [];
    }
  }

  bool hasApplied(String jobId) {
    return applications.any((item) => item.jobId == jobId);
  }

  Future<bool> applyToJob(Job job, {required String userId, required bool isPremium}) async {
    if (hasApplied(job.id) || !isPremium) return false;
    final application = Application(
      id: '${userId}_${job.id}',
      userId: userId,
      jobId: job.id,
      jobTitle: job.title,
      company: job.company,
    );
    applications = [...applications, application];
    _notify();
    try {
      await _firestore.collection('applications').doc(application.id).set(
            application.toJson(),
          );
      return true;
    } catch (error) {
      debugPrint('Error applying to job: $error');
      applications =
          applications.where((item) => item.id != application.id).toList();
      _notify();
      return false;
    }
  }

  Future<void> toggleSavedJob(Job job, {required String userId}) async {
    final exists = savedJobs.any((item) => item.id == job.id);
    final doc = _firestore
        .collection('users')
        .doc(userId)
        .collection('saved_jobs')
        .doc(job.id);
    if (exists) {
      savedJobs = savedJobs.where((item) => item.id != job.id).toList();
      _notify();
      try {
        await doc.delete();
      } catch (error) {
        debugPrint('Error unsaving job: $error');
        savedJobs = [job, ...savedJobs];
        jobFeed.index(job);
        _notify();
      }
    } else {
      savedJobs = [job, ...savedJobs];
      jobFeed.index(job);
      _notify();
      try {
        await doc.set({
          ...job.toJson(),
          'saved_at': DateTime.now().toIso8601String(),
        });
      } catch (error) {
        debugPrint('Error saving job: $error');
        savedJobs = savedJobs.where((item) => item.id != job.id).toList();
        _notify();
      }
    }
  }

  Future<void> toggleSavedCreator(
    CreatorProfile creator, {
    required String userId,
  }) async {
    if (creator.id.isEmpty) return;
    final exists = savedCreators.any((item) => item.id == creator.id);
    final doc = _firestore
        .collection('users')
        .doc(userId)
        .collection('saved_creators')
        .doc(creator.id);
    if (exists) {
      savedCreators =
          savedCreators.where((item) => item.id != creator.id).toList();
      _notify();
      try {
        await doc.delete();
      } catch (error) {
        debugPrint('Error unsaving creator: $error');
        savedCreators = [creator, ...savedCreators];
        _notify();
      }
    } else {
      final data = {
        ...creator.toJson(),
        'saved_at': DateTime.now().toIso8601String(),
      };
      savedCreators = [CreatorProfile.fromJson(data), ...savedCreators];
      _notify();
      try {
        await doc.set(data);
      } catch (error) {
        debugPrint('Error saving creator: $error');
        savedCreators =
            savedCreators.where((item) => item.id != creator.id).toList();
        _notify();
      }
    }
  }

  Future<void> loadCreators({
    String? currentUserId,
    bool forceRefresh = false,
  }) async {
    if (isLoadingCreators) return;
    final cacheIsFresh = _creatorsLoadedAt != null &&
        DateTime.now().difference(_creatorsLoadedAt!) < _creatorsTtl;
    if (!forceRefresh && cacheIsFresh) return;

    isLoadingCreators = true;
    _notify();
    try {
      QuerySnapshot<Map<String, dynamic>> userSnap;
      try {
        userSnap = await _firestore
            .collection('users')
            .orderBy('created_at', descending: true)
            .limit(80)
            .get();
      } catch (error) {
        debugPrint('Error ordering creators by created_at: $error');
        userSnap = await _firestore.collection('users').limit(80).get();
      }
      final profileIds = [
        for (final doc in userSnap.docs)
          if (doc.id != currentUserId) doc.id,
      ];
      final profilesById = await _profilesByIds(profileIds);
      final loaded = <CreatorProfile>[];
      var fallbackIndex = 1;
      for (final doc in userSnap.docs) {
        if (doc.id == currentUserId) continue;
        final otherProfile = profilesById[doc.id];
        if (otherProfile == null) continue;
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = data['id'] ?? doc.id;
        final otherUser = User.fromJson(data);
        if (otherUser.name.trim().isEmpty &&
            otherProfile.galleryPhotos.isEmpty &&
            otherProfile.city.isEmpty) {
          continue;
        }
        loaded.add(
          CreatorProfile.fromRecords(
            user: otherUser,
            profile: otherProfile,
            fallbackIndex: fallbackIndex,
          ),
        );
        fallbackIndex += 4;
        if (loaded.length >= 40) break;
      }
      loaded.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      creators = loaded;
      _creatorsLoadedAt = DateTime.now();
    } catch (error) {
      debugPrint('Error loading creators: $error');
    } finally {
      isLoadingCreators = false;
      _notify();
    }
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

  void reset() {
    _loadGeneration++;
    applications = [];
    savedJobs = [];
    savedCreators = [];
    creators = [];
    isLoadingCreators = false;
    _creatorsLoadedAt = null;
    jobFeed.reset();
    _notify();
  }
}
