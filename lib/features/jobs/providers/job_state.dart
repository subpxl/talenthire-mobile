import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:bombay_casting/core/models/models.dart';
import 'package:bombay_casting/features/creators/models/creator_profile.dart';
import 'package:bombay_casting/features/jobs/models/agency_profile.dart';
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

  CreatorFilter creatorFilter = const CreatorFilter();
  
  void setCreatorFilter(CreatorFilter filter) {
    creatorFilter = filter;
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
    for (final creator in [...creators, ...savedCreators]) {
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
    final application = Application(
      id: '${userId}_${job.id}',
      userId: userId,
      jobId: job.id,
      jobTitle: job.title,
      company: job.company,
      script: script,
      youtubeShortUrl: youtubeShortUrl,
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
        for (final doc in userSnap.docs) doc.id,
      ];
      if (currentUserId != null &&
          currentUserId.isNotEmpty &&
          !profileIds.contains(currentUserId)) {
        profileIds.add(currentUserId);
      }
      final profilesById = await _profilesByIds(profileIds);
      final loaded = <CreatorProfile>[];
      var fallbackIndex = 1;
      var includedCurrentUser = false;

      CreatorProfile? creatorFrom({
        required Map<String, dynamic> data,
        required String id,
      }) {
        final otherProfile = profilesById[id];
        if (otherProfile == null) return null;
        data['id'] = data['id'] ?? id;
        final otherUser = User.fromJson(data);
        final isCurrentUser = id == currentUserId;
        if (!isCurrentUser &&
            otherUser.name.trim().isEmpty &&
            otherProfile.galleryPhotos.isEmpty &&
            otherProfile.city.isEmpty) {
          return null;
        }
        final creator = CreatorProfile.fromRecords(
          user: otherUser,
          profile: otherProfile,
          fallbackIndex: fallbackIndex,
        );
        fallbackIndex += 4;
        return creator;
      }

      for (final doc in userSnap.docs) {
        final creator = creatorFrom(data: Map<String, dynamic>.from(doc.data()), id: doc.id);
        if (creator == null) continue;
        if (doc.id == currentUserId) includedCurrentUser = true;
        loaded.add(creator);
        if (loaded.length >= 40) break;
      }

      if (currentUserId != null &&
          currentUserId.isNotEmpty &&
          !includedCurrentUser) {
        final already = loaded.any((item) => item.id == currentUserId);
        if (!already) {
          final selfDoc =
              await _firestore.collection('users').doc(currentUserId).get();
          if (selfDoc.exists) {
            final creator = creatorFrom(
              data: Map<String, dynamic>.from(selfDoc.data()!),
              id: selfDoc.id,
            );
            if (creator != null) loaded.insert(0, creator);
          }
        }
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
