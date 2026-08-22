import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:bombay_casting/data/creator_profiles.dart';
import 'package:bombay_casting/data/job_assets.dart';
import 'package:bombay_casting/models/models.dart';
import 'package:bombay_casting/providers/job_feed.dart';
import 'package:bombay_casting/services/auth_service.dart';
import 'package:bombay_casting/services/job_cache_service.dart';
import 'package:bombay_casting/services/storage_service.dart';

class AppState extends ChangeNotifier {
  AppState() {
    jobFeed = JobFeed(
      firestore: _firestore,
      cache: jobCache,
      onChange: notifyListeners,
    );
    _init();
  }

  final AuthService authService = AuthService();
  final StorageService storageService = StorageService();
  final JobCacheService jobCache = JobCacheService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final JobFeed jobFeed;

  bool isLoading = true;
  bool isAuthenticated = false;
  String? lastAuthError;

  User? user;
  Profile? profile;
  List<Application> applications = [];
  List<Job> savedJobs = [];
  List<CreatorProfile> creators = [];
  bool isUploadingPhoto = false;
  bool isLoadingCreators = false;

  List<Job> get jobs => jobFeed.jobs;
  bool get isLoadingJobs => jobFeed.isLoading;
  bool get isLoadingMoreJobs => jobFeed.isLoadingMore;
  bool get hasMoreJobs => jobFeed.hasMore;
  HomeJobFilter get jobFilter => jobFeed.filter;
  List<JobListing> get filteredJobListings => jobFeed.filteredListings;

  bool isJobSaved(String jobId) => savedJobs.any((job) => job.id == jobId);

  Job? jobById(String jobId) => jobFeed.byId(jobId);

  void setJobFilter(HomeJobFilter filter) => jobFeed.setFilter(filter);

  Future<void> refreshJobs() => jobFeed.refresh();

  Future<void> loadMoreJobs() => jobFeed.loadMore();

  Future<void> _init() async {
    try {
      await authService.initializeGoogleSignIn();
    } catch (error) {
      debugPrint('Google Sign-In init skipped: $error');
    }
    if (authService.isLoggedIn) {
      await _loadUserData(authService.uid!);
    } else {
      isAuthenticated = false;
    }
    isLoading = false;
    notifyListeners();
  }

  Future<bool> loginWithGoogle() async {
    lastAuthError = null;
    final credential = await authService.signInWithGoogle();
    if (credential?.user == null) {
      lastAuthError = authService.lastError ?? 'Google Sign-In failed.';
      notifyListeners();
      return false;
    }

    final firebaseUser = credential!.user!;
    await _createOrFetchUser(
      uid: firebaseUser.uid,
      name: firebaseUser.displayName ?? '',
      email: firebaseUser.email ?? '',
    );
    isAuthenticated = true;
    notifyListeners();
    return true;
  }

  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    lastAuthError = null;
    final credential = await authService.signInWithEmailPassword(
      email: email,
      password: password,
    );
    if (credential?.user == null) {
      lastAuthError = authService.lastError ?? 'Sign in failed.';
      notifyListeners();
      return false;
    }

    final firebaseUser = credential!.user!;
    await _createOrFetchUser(
      uid: firebaseUser.uid,
      name: firebaseUser.displayName ?? email.split('@').first,
      email: firebaseUser.email ?? email.trim(),
    );
    isAuthenticated = true;
    notifyListeners();
    return true;
  }

  Future<bool> registerWithEmail({
    required String email,
    required String password,
    String name = '',
  }) async {
    lastAuthError = null;
    final credential = await authService.registerWithEmailPassword(
      email: email,
      password: password,
      name: name.trim().isNotEmpty ? name.trim() : email.split('@').first,
    );
    if (credential?.user == null) {
      lastAuthError = authService.lastError ?? 'Registration failed.';
      notifyListeners();
      return false;
    }

    final firebaseUser = credential!.user!;
    await _createOrFetchUser(
      uid: firebaseUser.uid,
      name: name.trim().isNotEmpty ? name.trim() : email.split('@').first,
      email: firebaseUser.email ?? email.trim(),
    );
    isAuthenticated = true;
    notifyListeners();
    return true;
  }

  Future<void> _createOrFetchUser({
    required String uid,
    required String name,
    required String email,
    String mobile = '',
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final data = Map<String, dynamic>.from(userDoc.data()!);
        data['id'] = data['id']?.toString().isNotEmpty == true ? data['id'] : uid;
        user = User.fromJson(data);
      } else {
        user = User(id: uid, name: name, email: email, mobile: mobile);
        await _firestore.collection('users').doc(uid).set(user!.toJson());
      }
      await _loadUserData(uid);
      final googlePhoto = authService.currentUser?.photoURL;
      if (googlePhoto != null &&
          googlePhoto.isNotEmpty &&
          (profile?.profileImage ?? '').isEmpty) {
        await updateProfile(profile!.copyWith(profileImage: googlePhoto));
      }
    } catch (error) {
      debugPrint('Error creating/fetching user: $error');
      lastAuthError = 'Failed to load account data.';
    }
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final data = Map<String, dynamic>.from(userDoc.data()!);
        data['id'] = data['id']?.toString().isNotEmpty == true ? data['id'] : uid;
        user = User.fromJson(data);
      }

      await Future.wait([
        _loadProfile(uid),
        _loadApplications(uid),
        _loadSavedJobs(uid),
        jobFeed.hydrateAndLoad(),
      ]);
      isAuthenticated = true;
    } catch (error) {
      debugPrint('Error loading user data: $error');
      lastAuthError = 'Failed to load app data.';
      isAuthenticated = false;
    }
  }

  Future<void> _loadProfile(String uid) async {
    try {
      final profileDoc = await _firestore.collection('profiles').doc(uid).get();
      if (profileDoc.exists) {
        final data = Map<String, dynamic>.from(profileDoc.data()!);
        data['user_id'] = data['user_id'] ?? uid;
        profile = Profile.fromJson(data);
      } else {
        profile = Profile(userId: uid);
        await _firestore.collection('profiles').doc(uid).set(profile!.toJson());
      }
    } catch (error) {
      debugPrint('Error loading profile: $error');
      profile = Profile(userId: uid);
    }
  }

  Future<void> refreshSavedJobs() async {
    if (user == null) return;
    await _loadSavedJobs(user!.id);
    notifyListeners();
  }

  Future<void> refreshApplications() async {
    if (user == null) return;
    await _loadApplications(user!.id);
    notifyListeners();
  }

  Future<void> _loadApplications(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('applications')
          .where('user_id', isEqualTo: uid)
          .get();
      applications = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        if ((data['id']?.toString() ?? '').isEmpty) data['id'] = doc.id;
        return Application.fromJson(data);
      }).where((item) => item.status != ApplicationStatus.withdrawn).toList();
    } catch (error) {
      debugPrint('Error loading applications: $error');
      applications = [];
    }
  }

  Future<void> _loadSavedJobs(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('saved_jobs')
          .get();
      savedJobs = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = data['id'] ?? doc.id;
        return Job.fromJson(data);
      }).toList();
      for (final job in savedJobs) {
        jobFeed.index(job);
      }
    } catch (error) {
      debugPrint('Error loading saved jobs: $error');
      savedJobs = [];
    }
  }

  bool hasApplied(String jobId) {
    return applications.any((item) => item.jobId == jobId);
  }

  Future<void> applyToJob(Job job) async {
    if (user == null || hasApplied(job.id)) return;
    if (!(profile?.isPremium ?? false)) return;
    final application = Application(
      id: '${user!.id}_${job.id}',
      userId: user!.id,
      jobId: job.id,
      jobTitle: job.title,
      company: job.company,
    );
    applications = [...applications, application];
    notifyListeners();
    await _firestore.collection('applications').doc(application.id).set(
          application.toJson(),
        );
  }

  Future<void> toggleSavedJob(Job job) async {
    if (user == null) return;
    final exists = savedJobs.any((item) => item.id == job.id);
    final doc = _firestore
        .collection('users')
        .doc(user!.id)
        .collection('saved_jobs')
        .doc(job.id);
    if (exists) {
      savedJobs = savedJobs.where((item) => item.id != job.id).toList();
      notifyListeners();
      await doc.delete();
    } else {
      savedJobs = [...savedJobs, job];
      jobFeed.index(job);
      notifyListeners();
      await doc.set(job.toJson());
    }
  }

  Future<void> updateProfile(Profile updated) async {
    profile = updated;
    notifyListeners();
    if (user == null) return;
    final data = updated.toJson()
      ..remove('subscription_status')
      ..remove('is_verified')
      ..remove('account_status')
      ..remove('free_job_applications_used');
    await _firestore.collection('profiles').doc(user!.id).set(
          data,
          SetOptions(merge: true),
        );
  }

  Future<void> uploadProfilePhoto(File file) async {
    if (user == null || profile == null) return;
    final current = profile!.galleryPhotos;
    if (current.length >= Profile.maxPhotos) return;
    isUploadingPhoto = true;
    notifyListeners();
    try {
      final url = await storageService.uploadProfilePhoto(
        userId: user!.id,
        file: file,
      );
      final photos = [...current.where((item) => item != url), url];
      await updateProfile(
        profile!.copyWith(profileImage: photos.first, photos: photos),
      );
    } catch (error) {
      debugPrint('Error uploading profile photo: $error');
      rethrow;
    } finally {
      isUploadingPhoto = false;
      notifyListeners();
    }
  }

  Future<String?> uploadVerificationDocument(File file) async {
    if (user == null) return null;
    return storageService.uploadDocument(
      userId: user!.id,
      file: file,
      folder: 'verification',
    );
  }

  Future<void> removeProfilePhoto(String url) async {
    if (profile == null) return;
    final photos = profile!.galleryPhotos.where((item) => item != url).toList();
    await updateProfile(
      profile!.copyWith(
        profileImage: photos.isEmpty ? '' : photos.first,
        photos: photos,
      ),
    );
    try {
      await storageService.deleteProfilePhoto(url);
    } catch (error) {
      debugPrint('Error deleting profile photo: $error');
    }
  }

  Future<void> loadCreators() async {
    if (isLoadingCreators) return;
    isLoadingCreators = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _firestore.collection('profiles').limit(40).get(),
        _firestore.collection('users').limit(40).get(),
      ]);
      final profileSnap = results[0];
      final userSnap = results[1];
      final usersById = <String, User>{
        for (final doc in userSnap.docs)
          doc.id: User.fromJson({
            ...Map<String, dynamic>.from(doc.data()),
            'id': doc.id,
          }),
      };
      final loaded = <CreatorProfile>[];
      var fallbackIndex = 1;
      for (final doc in profileSnap.docs) {
        if (doc.id == user?.id) continue;
        final data = Map<String, dynamic>.from(doc.data());
        data['user_id'] = data['user_id'] ?? doc.id;
        final otherProfile = Profile.fromJson(data);
        final otherUser = usersById[doc.id] ?? User(id: doc.id, name: 'Creator');
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
      }
      creators = loaded;
    } catch (error) {
      debugPrint('Error loading creators: $error');
    } finally {
      isLoadingCreators = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await authService.signOut();
    user = null;
    profile = null;
    applications = [];
    savedJobs = [];
    creators = [];
    isLoadingCreators = false;
    jobFeed.reset();
    isAuthenticated = false;
    notifyListeners();
  }
}
