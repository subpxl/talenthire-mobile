import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bombay_casting/core/models/models.dart';
import 'package:bombay_casting/core/services/auth_service.dart';
import 'package:bombay_casting/core/services/storage_service.dart';
import 'package:bombay_casting/core/widgets/option_picker.dart';
import 'package:bombay_casting/features/auth/providers/auth_provider.dart';
import 'package:bombay_casting/features/creators/models/creator_profile.dart';
import 'package:bombay_casting/features/jobs/models/job_listing.dart';
import 'package:bombay_casting/features/jobs/providers/job_feed_provider.dart';
import 'package:bombay_casting/features/jobs/providers/job_state.dart';
import 'package:bombay_casting/features/jobs/services/job_cache_service.dart';
import 'package:bombay_casting/features/profile/providers/profile_provider.dart';

class AppState extends ChangeNotifier {
  AppState() {
    _profile = ProfileProvider(onChange: notifyListeners);
    _jobs = JobState(onChange: notifyListeners);
    _auth = AuthProvider(
      onSessionReady: _onSessionReady,
      onChange: notifyListeners,
    );
    _loadLocale();
    _listenCategories();
  }

  StreamSubscription? _categoriesSub;

  void _listenCategories() {
    _categoriesSub = FirebaseFirestore.instance
        .collection('settings')
        .doc('categories')
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        final data = doc.data();
        final raw = data?['talentTypes'];
        if (raw is List && raw.isNotEmpty) {
          final list = raw
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList();
          if (list.isNotEmpty) {
            ProfileOptions.setDynamicTalentCategories(list);
            notifyListeners();
          }
        }
      }
    }, onError: (_) {});
  }

  Locale? _appLocale;
  Locale? get appLocale => _appLocale;

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code');
    if (languageCode != null) {
      _appLocale = Locale(languageCode);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_appLocale == locale) return;
    _appLocale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
    notifyListeners();
  }

  late final AuthProvider _auth;
  late final ProfileProvider _profile;
  late final JobState _jobs;

  AuthService get authService => _auth.authService;
  StorageService get storageService => _profile.storageService;
  JobCacheService get jobCache => _jobs.jobCache;
  JobFeed get jobFeed => _jobs.jobFeed;

  bool get isLoading => _auth.isLoading;
  bool get isAuthenticated => _auth.isAuthenticated;
  String? get lastAuthError => _auth.lastAuthError;
  User? get user => _auth.user;
  Profile? get profile => _profile.profile;

  /// Premium is only valid when the loaded profile belongs to the signed-in user.
  bool get isPremiumUser {
    final uid = user?.id;
    if (uid == null) return false;
    final currentProfile = profile;
    if (currentProfile == null || currentProfile.userId != uid) return false;
    return currentProfile.isPremium;
  }
  List<Application> get applications => _jobs.applications;
  List<Job> get savedJobs => _jobs.savedJobs;
  List<CreatorProfile> get savedCreators => _jobs.savedCreators;
  List<CreatorProfile> get creators => _jobs.creators;
  bool get isUploadingPhoto => _profile.isUploadingPhoto;
  bool get isLoadingCreators => _jobs.isLoadingCreators;
  List<Job> get jobs => _jobs.jobs;
  bool get isLoadingJobs => _jobs.isLoadingJobs;
  bool get isLoadingMoreJobs => _jobs.isLoadingMoreJobs;
  bool get hasMoreJobs => _jobs.hasMoreJobs;
  HomeJobFilter get jobFilter => _jobs.jobFilter;
  List<JobListing> get filteredJobListings => _jobs.filteredJobListings;
  CreatorFilter get creatorFilter => _jobs.creatorFilter;

  int homeInnerTabIndex = 0;
  int creatorsInnerTabIndex = 0;

  void setHomeInnerTab(int index) {
    if (homeInnerTabIndex == index) return;
    homeInnerTabIndex = index;
    notifyListeners();
  }

  void setCreatorsInnerTab(int index) {
    if (creatorsInnerTabIndex == index) return;
    creatorsInnerTabIndex = index;
    notifyListeners();
  }

  void onMainShellTabSelected(int index) {
    var changed = false;
    if (index == 0 && homeInnerTabIndex != 0) {
      homeInnerTabIndex = 0;
      changed = true;
    }
    if (index == 1 && creatorsInnerTabIndex != 0) {
      creatorsInnerTabIndex = 0;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  bool isJobSaved(String jobId) => _jobs.isJobSaved(jobId);
  bool isCreatorSaved(String creatorId) => _jobs.isCreatorSaved(creatorId);
  Job? jobById(String jobId) => _jobs.jobById(jobId);
  void setJobFilter(HomeJobFilter filter) => _jobs.setJobFilter(filter);
  void setCreatorFilter(CreatorFilter filter) => _jobs.setCreatorFilter(filter);
  Future<void> refreshJobs() => _jobs.refreshJobs();
  Future<void> loadMoreJobs() => _jobs.loadMoreJobs();
  bool hasApplied(String jobId) => _jobs.hasApplied(jobId);

  Future<bool> loginWithGoogle() => _auth.loginWithGoogle();
  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) =>
      _auth.loginWithEmail(email: email, password: password);
  Future<bool> registerWithEmail({
    required String email,
    required String password,
    String name = '',
  }) =>
      _auth.registerWithEmail(email: email, password: password, name: name);

  Future<void> refreshSavedJobs() async {
    final uid = user?.id;
    if (uid == null) return;
    await _jobs.refreshSavedJobs(uid);
  }

  Future<void> refreshApplications() async {
    final uid = user?.id;
    if (uid == null) return;
    await _jobs.refreshApplications(uid);
  }

  Future<bool> applyToJob(Job job) async {
    final uid = user?.id;
    if (uid == null) return false;
    return _jobs.applyToJob(
      job,
      userId: uid,
      isPremium: isPremiumUser,
    );
  }

  Future<void> toggleSavedJob(Job job) async {
    final uid = user?.id;
    if (uid == null) return;
    await _jobs.toggleSavedJob(job, userId: uid);
  }

  Future<void> refreshSavedCreators() async {
    final uid = user?.id;
    if (uid == null) return;
    await _jobs.refreshSavedCreators(uid);
  }

  Future<void> toggleSavedCreator(CreatorProfile creator) async {
    final uid = user?.id;
    if (uid == null) return;
    await _jobs.toggleSavedCreator(creator, userId: uid);
  }

  Future<void> updateProfile(Profile updated) =>
      _profile.updateProfile(updated, userId: user?.id);

  Future<void> uploadProfilePhoto(File file) async {
    final uid = user?.id;
    if (uid == null) return;
    await _profile.uploadProfilePhoto(userId: uid, file: file);
  }

  Future<String?> uploadVerificationDocument(File file) async {
    final uid = user?.id;
    if (uid == null) return null;
    return _profile.uploadVerificationDocument(userId: uid, file: file);
  }

  Future<void> removeProfilePhoto(String url) =>
      _profile.removeProfilePhoto(url, userId: user?.id);

  Future<void> refreshProfile() async {
    final uid = user?.id;
    if (uid == null) return;
    await _profile.loadProfile(uid);
  }

  Future<void> loadCreators({bool forceRefresh = false}) =>
      _jobs.loadCreators(currentUserId: user?.id, forceRefresh: forceRefresh);

  Future<void> logout() async {
    await _auth.logout();
    _profile.reset();
    _jobs.reset();
    homeInnerTabIndex = 0;
    creatorsInnerTabIndex = 0;
    notifyListeners();
  }

  Future<void> _onSessionReady(SessionBootstrap bootstrap) async {
    _profile.reset();
    _jobs.reset();
    if (bootstrap.isNewUser) {
      await _profile.createDefault(
        uid: bootstrap.uid,
        profileImage: bootstrap.googlePhotoUrl ?? '',
      );
    } else {
      await _profile.loadProfile(bootstrap.uid);
      unawaited(_profile.syncGooglePhoto(bootstrap.googlePhotoUrl));
    }
    _jobs.startBackgroundLoads(
      bootstrap.uid,
      isNewUser: bootstrap.isNewUser,
    );
  }

  @override
  void dispose() {
    _categoriesSub?.cancel();
    super.dispose();
  }
}
