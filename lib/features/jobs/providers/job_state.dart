import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:bombay_casting/core/models/models.dart';
import 'package:bombay_casting/features/creators/models/creator_profile.dart';
import 'package:bombay_casting/features/creators/providers/creator_feed_provider.dart';
import 'package:bombay_casting/features/creators/services/creator_cache_service.dart';
import 'package:bombay_casting/features/jobs/models/agency_profile.dart';
import 'package:bombay_casting/features/jobs/models/job_listing.dart';
import 'package:bombay_casting/features/jobs/providers/job_feed_provider.dart';
import 'package:bombay_casting/features/jobs/services/job_cache_service.dart';
import 'package:bombay_casting/core/services/application_service.dart';

class JobState extends ChangeNotifier {
  JobState({
    required this._onChange,
    ApplicationService? applicationService,
  })  : applicationService = applicationService ?? ApplicationService() {
    jobFeed = JobFeed(
      firestore: _firestore,
      cache: jobCache,
      onChange: _notify,
    );
    creatorFeed = CreatorFeed(
      firestore: _firestore,
      cache: creatorCache,
      onChange: _notify,
    );
  }

  final JobCacheService jobCache = JobCacheService();
  final CreatorCacheService creatorCache = CreatorCacheService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final VoidCallback _onChange;
  final ApplicationService applicationService;
  late final JobFeed jobFeed;
  late final CreatorFeed creatorFeed;

  List<Application> applications = [];
  List<Job> savedJobs = [];
  List<CreatorProfile> savedCreators = [];
  int _loadGeneration = 0;

  List<Job> get jobs => jobFeed.jobs;
  bool get isLoadingJobs => jobFeed.isLoading;
  bool get isLoadingMoreJobs => jobFeed.isLoadingMore;
  bool get hasMoreJobs => jobFeed.hasMore;
  Object? get jobsLoadError => jobFeed.loadError;
  HomeJobFilter get jobFilter => jobFeed.filter;
  List<JobListing> get filteredJobListings => jobFeed.filteredListings;

  List<CreatorProfile> get creators => creatorFeed.creators;
  bool get isLoadingCreators => creatorFeed.isLoading;
  bool get isLoadingMoreCreators => creatorFeed.isLoadingMore;
  bool get hasMoreCreators => creatorFeed.hasMore;
  Object? get creatorsLoadError => creatorFeed.loadError;

  CreatorFilter creatorFilter = const CreatorFilter();
  
  void setCreatorFilter(CreatorFilter filter) {
    creatorFilter = filter;
    creatorFeed.setFilter(filter);
    _notify();
  }

  void _notify() {
    notifyListeners();
    _onChange();
  }

  bool isJobSaved(String jobId) => savedJobs.any((job) => job.id == jobId);

  bool isCreatorSaved(String creatorId) =>
      savedCreators.any((creator) => creator.id == creatorId);

  Job? jobById(String jobId) => jobFeed.byId(jobId);

  Future<Job?> fetchJobById(String id) async {
    if (id.isEmpty) return null;
    final cached = jobById(id);
    if (cached != null) return cached;
    final doc = await _firestore.collection('jobs').doc(id).get();
    if (!doc.exists) return null;
    final job = Job.fromJson({
      ...Map<String, dynamic>.from(doc.data() ?? const {}),
      'id': doc.id,
    });
    jobFeed.index(job);
    return job;
  }

  Future<CreatorProfile?> fetchCreatorById(String id) async {
    if (id.isEmpty) return null;
    final cached = creatorFeed.byId(id);
    if (cached != null) return cached;
    for (final creator in savedCreators) {
      if (creator.id == id) return creator;
    }

    final userDoc = await _firestore.collection('users').doc(id).get();
    if (!userDoc.exists) return null;
    final profileDoc = await _firestore.collection('profiles').doc(id).get();
    if (!profileDoc.exists) return null;
    final user = User.fromJson({
      ...Map<String, dynamic>.from(userDoc.data() ?? const {}),
      'id': userDoc.id,
    });
    final profile = Profile.fromJson({
      ...Map<String, dynamic>.from(profileDoc.data() ?? const {}),
      'user_id': profileDoc.id,
    });
    return CreatorProfile.fromRecords(
      user: user,
      profile: profile,
      fallbackIndex: 1,
    );
  }

  Future<AgencyProfile?> fetchAgencyById(String id) async {
    if (id.isEmpty) return null;
    final fromLoaded = jobs.where(
      (job) => job.createdBy == id,
    );
    if (fromLoaded.isNotEmpty) {
      return AgencyProfile.fromJob(fromLoaded.first, allJobs: jobs);
    }

    QuerySnapshot<Map<String, dynamic>>? snap;
    try {
      snap = await _firestore
          .collection('jobs')
          .where('created_by', isEqualTo: id)
          .limit(20)
          .get();
    } catch (_) {}
    if (snap == null || snap.docs.isEmpty) {
      try {
        snap = await _firestore
            .collection('jobs')
            .where('agencyId', isEqualTo: id)
            .limit(20)
            .get();
      } catch (_) {}
    }
    final fetched = [
      if (snap != null)
        for (final doc in snap.docs)
          Job.fromJson({
            ...Map<String, dynamic>.from(doc.data()),
            'id': doc.id,
          }),
    ];
    for (final job in fetched) {
      jobFeed.index(job);
    }
    if (fetched.isNotEmpty) {
      return AgencyProfile.fromJob(fetched.first, allJobs: [...jobs, ...fetched]);
    }

    final userDoc = await _firestore.collection('users').doc(id).get();
    if (!userDoc.exists) return null;
    final data = userDoc.data() ?? const <String, dynamic>{};
    return AgencyProfile(
      id: id,
      name: (data['name'] ?? 'Agency').toString(),
      createdBy: id,
    );
  }

  void setJobFilter(HomeJobFilter filter) => jobFeed.setFilter(filter);

  Future<void> refreshJobs() => jobFeed.refresh();

  Future<void> loadMoreJobs() => jobFeed.loadMore();

  Future<void> refreshCreators({String? currentUserId}) {
    creatorFeed.setCurrentUserId(currentUserId);
    return creatorFeed.refresh();
  }

  Future<void> loadMoreCreators({String? currentUserId}) {
    creatorFeed.setCurrentUserId(currentUserId);
    return creatorFeed.loadMore();
  }

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
      creatorFeed.setCurrentUserId(uid);
      creatorFeed.markAwaitingFirstPage();
      if (isNewUser) {
        await Future.wait([
          jobFeed.hydrateAndLoad(),
          creatorFeed.hydrateAndLoad(),
        ]);
      } else {
        await Future.wait([
          _loadApplications(uid, token: token),
          _loadSavedJobs(uid, token: token),
          _loadSavedCreators(uid, token: token),
          jobFeed.hydrateAndLoad(),
          creatorFeed.hydrateAndLoad(),
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
      }).where((item) =>
          item.status != ApplicationStatus.withdrawn &&
          item.jobId.trim().isNotEmpty).toList();
      await _resolveApplicationJobs(token);
    } catch (error) {
      debugPrint('Error loading applications: $error');
      if (token != _loadGeneration) return;
      applications = [];
    }
  }

  Future<void> _resolveApplicationJobs(int token) async {
    final missing = {
      for (final item in applications)
        if (jobById(item.jobId) == null) item.jobId,
    };
    if (missing.isEmpty) return;
    final missingIds = <String>{};
    await Future.wait(missing.map((id) async {
      try {
        final job = await fetchJobById(id);
        if (job == null) missingIds.add(id);
      } catch (error) {
        debugPrint('Error resolving applied job $id: $error');
      }
    }));
    if (token != _loadGeneration) return;
    if (missingIds.isEmpty) return;
    applications = [
      for (final item in applications)
        if (!missingIds.contains(item.jobId)) item,
    ];
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

  Application? applicationFor(String jobId) {
    for (final item in applications) {
      if (item.jobId == jobId) return item;
    }
    return null;
  }

  Future<bool> applyToJob(
    Job job, {
    required String userId,
    String script = '',
    String youtubeShortUrl = '',
  }) async {
    if (hasApplied(job.id)) return false;

    final result = await applicationService.submit(
      jobId: job.id,
      script: script,
      youtubeShortUrl: youtubeShortUrl,
    );
    if (!result.isSuccess) {
      debugPrint('Apply rejected: ${result.failure}');
      return false;
    }

    final application = result.application!;
    applications = [
      for (final item in applications)
        if (item.jobId != job.id) item,
      application,
    ];
    _notify();
    return true;
  }

  Future<bool> updateApplicationLink(
    Application application, {
    required String youtubeShortUrl,
  }) async {
    final previous = applications;
    final updated = application.copyWith(youtubeShortUrl: youtubeShortUrl);
    applications = [
      for (final item in applications)
        if (item.id == application.id) updated else item,
    ];
    _notify();
    try {
      await _firestore.collection('applications').doc(application.id).update({
        'youtube_short_url': youtubeShortUrl,
      });
      return true;
    } catch (error) {
      debugPrint('Error updating application link: $error');
      applications = previous;
      _notify();
      return false;
    }
  }

  Future<bool> withdrawApplication(Application application) async {
    final previous = applications;
    applications =
        applications.where((item) => item.id != application.id).toList();
    _notify();
    try {
      await _firestore.collection('applications').doc(application.id).update({
        'status': ApplicationStatus.withdrawn.name,
      });
      return true;
    } catch (error) {
      debugPrint('Error withdrawing application: $error');
      applications = previous;
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
  }) {
    creatorFeed.setCurrentUserId(currentUserId);
    if (forceRefresh) return creatorFeed.refresh();
    return creatorFeed.hydrateAndLoad();
  }

  void reset() {
    _loadGeneration++;
    applications = [];
    savedJobs = [];
    savedCreators = [];
    jobFeed.reset();
    creatorFeed.reset();
    _notify();
  }
}
