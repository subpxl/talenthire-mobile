import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bombay_casting/core/deep_links/deep_link_target.dart';
import 'package:bombay_casting/core/models/models.dart';
import 'package:bombay_casting/core/services/account_service.dart';
import 'package:bombay_casting/core/services/analytics_service.dart';
import 'package:bombay_casting/core/services/auth_service.dart';
import 'package:bombay_casting/core/utils/phone_utils.dart';
import 'package:bombay_casting/features/onboarding/first_login_step.dart';
import 'package:bombay_casting/core/services/push_notification_service.dart';
import 'package:bombay_casting/core/services/storage_service.dart';
import 'package:bombay_casting/core/widgets/option_picker.dart';
import 'package:bombay_casting/features/auth/providers/auth_provider.dart';
import 'package:bombay_casting/features/creators/models/creator_profile.dart';
import 'package:bombay_casting/features/jobs/models/agency_profile.dart';
import 'package:bombay_casting/features/jobs/models/job_listing.dart';
import 'package:bombay_casting/features/jobs/providers/job_feed_provider.dart';
import 'package:bombay_casting/features/jobs/providers/job_state.dart';
import 'package:bombay_casting/features/jobs/utils/apply_quota.dart';
import 'package:bombay_casting/features/jobs/services/job_cache_service.dart';
import 'package:bombay_casting/features/messaging/providers/messaging_provider.dart';
import 'package:bombay_casting/features/notifications/providers/notifications_provider.dart';
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
    _listenDeepLinks();
    _listenBanners();
  }

  StreamSubscription? _categoriesSub;
  StreamSubscription? _bannersSub;
  StreamSubscription<PushTapTarget>? _pushTapSub;
  MessagingProvider? _messaging;
  NotificationsProvider? _notifications;
  PushTapTarget? pendingPushTap;
  bool pendingNotificationsOpen = false;

  MessagingProvider? get messaging => _messaging;
  NotificationsProvider? get notifications => _notifications;
  int get unreadMessageCount => _messaging?.unreadTotal ?? 0;
  int get unreadNotificationCount => _notifications?.unreadCount ?? 0;

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

  void _listenBanners() {
    _bannersSub = FirebaseFirestore.instance
        .collection('banners')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _homeBanners = snapshot.docs.map((doc) => HomeBanner.fromFirestore(doc)).toList();
      notifyListeners();
    }, onError: (_) {});
  }

  void _listenDeepLinks() {
    _deepLinkSub = _appLinks.uriLinkStream.listen(_queueDeepLink);
    unawaited(
      _appLinks.getInitialLink().then((uri) {
        if (uri != null) _queueDeepLink(uri);
      }),
    );
  }

  void _queueDeepLink(Uri uri) {
    final target = DeepLinkTarget.tryParse(uri);
    if (target == null || target == pendingDeepLink) return;
    pendingDeepLink = target;
    notifyListeners();
  }

  void clearPendingDeepLink() {
    if (pendingDeepLink == null) return;
    pendingDeepLink = null;
    notifyListeners();
  }

  static const _languagePromptKey = 'language_prompt_done';

  Locale? _appLocale;
  Locale? get appLocale => _appLocale;
  bool _hasSelectedLanguage = false;
  bool get hasSelectedLanguage => _hasSelectedLanguage;
  FirstLoginStep _firstLoginStep = FirstLoginStep.none;
  FirstLoginStep get firstLoginStep => _firstLoginStep;
  bool get shouldShowFirstLoginSetup =>
      _firstLoginStep != FirstLoginStep.none;
  bool _localeReady = false;
  bool get localeReady => _localeReady;

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code');
    final promptDone = prefs.getBool(_languagePromptKey) == true;
    _hasSelectedLanguage = _hasSelectedLanguage || promptDone || languageCode != null;
    if (languageCode != null) {
      _appLocale = Locale(languageCode);
    }
    _localeReady = true;
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _appLocale = locale;
    _hasSelectedLanguage = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
    await prefs.setBool(_languagePromptKey, true);
    notifyListeners();
  }

  Future<void> markLanguagePromptDone() async {
    if (_hasSelectedLanguage) return;
    _hasSelectedLanguage = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_languagePromptKey, true);
    notifyListeners();
  }

  Future<void> completeMobileOnboarding(String mobile) async {
    await updateUser(mobile: mobile);
    final current = profile;
    if (current != null) {
      await updateProfile(
        current.mergeFormSection('personal', {
          'mobile': mobile,
          'whatsapp': mobile,
          'whatsapp_same_as_mobile': true,
        }),
      );
    }
    await _setFirstLoginStep(FirstLoginStep.language);
  }

  Future<void> completeLanguageOnboarding(Locale locale) async {
    await setLocale(locale);
    await _setFirstLoginStep(FirstLoginStep.photo);
  }

  Future<void> completePhotoOnboarding() =>
      _setFirstLoginStep(FirstLoginStep.category);

  Future<void> completeCategoryOnboarding() =>
      _setFirstLoginStep(FirstLoginStep.creator);

  Future<void> completeCreatorOnboarding() =>
      _setFirstLoginStep(FirstLoginStep.social);

  Future<void> completeSocialOnboarding() => _completeFirstLoginSetup();

  Future<void> goToPreviousFirstLoginStep() async {
    switch (_firstLoginStep) {
      case FirstLoginStep.social:
        await _setFirstLoginStep(FirstLoginStep.creator);
        break;
      case FirstLoginStep.creator:
        await _setFirstLoginStep(FirstLoginStep.category);
        break;
      case FirstLoginStep.category:
        await _setFirstLoginStep(FirstLoginStep.photo);
        break;
      case FirstLoginStep.photo:
        await _setFirstLoginStep(FirstLoginStep.language);
        break;
      case FirstLoginStep.language:
        await _setFirstLoginStep(FirstLoginStep.mobile);
        break;
      case FirstLoginStep.mobile:
      case FirstLoginStep.none:
        break;
    }
  }

  Future<void> _setFirstLoginStep(FirstLoginStep step) async {
    _firstLoginStep = step;
    notifyListeners();
    try {
      await _auth.updateUser(
        onboardingStep: step.storageValue,
        onboardingCompleted: step == FirstLoginStep.none,
      );
    } catch (error) {
      debugPrint('Failed to persist onboarding step: $error');
    }
  }

  Future<void> _completeFirstLoginSetup() async {
    await markLanguagePromptDone();
    await _setFirstLoginStep(FirstLoginStep.none);
  }

  void _resolveFirstLoginStep() {
    final currentUser = user;
    if (currentUser == null) {
      _firstLoginStep = FirstLoginStep.mobile;
      return;
    }
    if (currentUser.onboardingCompleted) {
      _firstLoginStep = FirstLoginStep.none;
      return;
    }
    var step = FirstLoginStep.fromStorage(
      currentUser.onboardingStep,
      completed: false,
    );
    if (step == FirstLoginStep.mobile &&
        PhoneUtils.isValidIndianMobile(currentUser.mobile)) {
      step = FirstLoginStep.language;
    }
    _firstLoginStep = step;
  }

  late final AuthProvider _auth;
  late final ProfileProvider _profile;
  late final JobState _jobs;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _deepLinkSub;
  DeepLinkTarget? pendingDeepLink;

  AuthService get authService => _auth.authService;
  StorageService get storageService => _profile.storageService;
  JobCacheService get jobCache => _jobs.jobCache;
  JobFeed get jobFeed => _jobs.jobFeed;

  bool get isLoading => _auth.isLoading;
  bool get isAuthenticated => _auth.isAuthenticated;
  bool get isAccountDeactivated =>
      _auth.isAuthenticated && _auth.user?.isActive == false;
  String? get lastAuthError => _auth.lastAuthError;
  User? get user => _auth.user;
  Profile? get profile => _profile.profile;
  bool get isAdmin => user?.role == UserRole.admin;

  /// Premium is only valid when the loaded profile belongs to the signed-in user.
  bool get isPremiumUser {
    final uid = user?.id;
    if (uid == null) return false;
    final currentProfile = profile;
    if (currentProfile == null || currentProfile.userId != uid) return false;
    return currentProfile.isPremium;
  }

  ApplyGate get applyGate => ApplyQuota.evaluate(
        isPremium: isPremiumUser,
        accountCreatedAt: user?.createdAt,
        applications: applications,
      );

  List<Application> get applications => _jobs.applications;
  List<Job> get savedJobs => _jobs.savedJobs;
  List<CreatorProfile> get savedCreators => _jobs.savedCreators;
  List<CreatorProfile> get creators {
    final loaded = _jobs.creators;
    final currentUser = user;
    final currentProfile = profile;
    if (currentUser == null || currentProfile == null) return loaded;

    final self = CreatorProfile.fromRecords(
      user: currentUser,
      profile: currentProfile,
      fallbackIndex: 1,
    );
    if (loaded.isEmpty) return [self];

    final result = <CreatorProfile>[];
    var included = false;
    for (final creator in loaded) {
      if (creator.id == currentUser.id) {
        result.add(self);
        included = true;
      } else {
        result.add(creator);
      }
    }
    if (!included) result.insert(0, self);
    return result;
  }
  bool get isUploadingPhoto => _profile.isUploadingPhoto;
  bool get isLoadingCreators => _jobs.isLoadingCreators;
  bool get isLoadingMoreCreators => _jobs.isLoadingMoreCreators;
  bool get hasMoreCreators => _jobs.hasMoreCreators;
  Object? get creatorsLoadError => _jobs.creatorsLoadError;
  bool get isCreatorsFeedEmpty => _jobs.creators.isEmpty;
  
  List<HomeBanner> _homeBanners = [];
  List<HomeBanner> get homeBanners => _homeBanners;
  
  List<Job> get jobs => _jobs.jobs;
  bool get isLoadingJobs => _jobs.isLoadingJobs;
  bool get isLoadingMoreJobs => _jobs.isLoadingMoreJobs;
  bool get hasMoreJobs => _jobs.hasMoreJobs;
  Object? get jobsLoadError => _jobs.jobsLoadError;
  HomeJobFilter get jobFilter => _jobs.jobFilter;
  List<JobListing> get filteredJobListings => _jobs.filteredJobListings;
  CreatorFilter get creatorFilter => _jobs.creatorFilter;

  int homeInnerTabIndex = 0;
  int creatorsInnerTabIndex = 0;
  int jobsInnerTabIndex = 0;
  int? requestedMainShellTab;

  void openJobsTabWithFilter(HomeJobFilter filter) {
    setJobFilter(filter);
    jobsInnerTabIndex = 0;
    requestedMainShellTab = 2;
    notifyListeners();
  }

  void clearRequestedMainShellTab() {
    if (requestedMainShellTab == null) return;
    requestedMainShellTab = null;
    notifyListeners();
  }

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

  void setJobsInnerTab(int index) {
    if (jobsInnerTabIndex == index) return;
    jobsInnerTabIndex = index;
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
    if (index == 2 && jobsInnerTabIndex != 0) {
      jobsInnerTabIndex = 0;
      changed = true;
    }
    final keepPresetSearch = index == 2 && requestedMainShellTab == 2;
    if (!keepPresetSearch && jobFilter.searchQuery.isNotEmpty) {
      setJobFilter(jobFilter.copyWith(searchQuery: ''));
      return;
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
  Application? applicationFor(String jobId) => _jobs.applicationFor(jobId);

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

  Future<bool> applyToJob(
    Job job, {
    String script = '',
    String youtubeShortUrl = '',
  }) async {
    final uid = user?.id;
    if (uid == null) return false;
    if (applyGate != ApplyGate.allowed) return false;
    final ok = await _jobs.applyToJob(
      job,
      userId: uid,
      script: script,
      youtubeShortUrl: youtubeShortUrl,
    );
    AnalyticsService.instance.track(
      () => AnalyticsService.instance.logApplyJob(
        jobId: job.id,
        success: ok,
      ),
    );
    return ok;
  }

  Future<bool> updateApplicationLink(
    Application application, {
    required String youtubeShortUrl,
  }) {
    return _jobs.updateApplicationLink(
      application,
      youtubeShortUrl: youtubeShortUrl,
    );
  }

  Future<bool> withdrawApplication(Application application) {
    return _jobs.withdrawApplication(application);
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

  Future<void> updateUser({
    String? name,
    String? email,
    String? mobile,
    bool? onboardingCompleted,
    String? onboardingStep,
  }) =>
      _auth.updateUser(
        name: name,
        email: email,
        mobile: mobile,
        onboardingCompleted: onboardingCompleted,
        onboardingStep: onboardingStep,
      );

  Future<void> uploadProfilePhoto(File file) async {
    final uid = user?.id;
    if (uid == null) return;
    await _profile.uploadProfilePhoto(userId: uid, file: file);
  }

  Future<void> uploadProfilePhotos(
    List<File> files, {
    int? mainIndex,
  }) async {
    final uid = user?.id;
    if (uid == null) return;
    await _profile.uploadProfilePhotos(
      userId: uid,
      files: files,
      mainIndex: mainIndex,
    );
  }

  Future<void> setMainProfilePhoto(String url) =>
      _profile.setMainProfilePhoto(url, userId: user?.id);

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

  Future<void> refreshCreators() =>
      _jobs.refreshCreators(currentUserId: user?.id);

  Future<void> loadMoreCreators() =>
      _jobs.loadMoreCreators(currentUserId: user?.id);

  Future<Job?> fetchJobById(String id) => _jobs.fetchJobById(id);

  Future<CreatorProfile?> fetchCreatorById(String id) =>
      _jobs.fetchCreatorById(id);

  Future<AgencyProfile?> fetchAgencyById(String id) =>
      _jobs.fetchAgencyById(id);

  Future<void> deactivateAccount() async {
    await _auth.deactivateAccount();
    await logout();
  }

  Future<void> reactivateAccount() async {
    await _auth.reactivateAccount();
    final uid = user?.id;
    if (uid == null) return;
    await _onSessionReady(SessionBootstrap(uid: uid));
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    final uid = user?.id;
    if (uid != null) {
      await PushNotificationService.instance.unregisterToken(uid);
    }
    await AccountService().deleteAccount();
    _pushTapSub?.cancel();
    _pushTapSub = null;
    _messaging?.dispose();
    _messaging = null;
    _notifications?.dispose();
    _notifications = null;
    pendingPushTap = null;
    pendingNotificationsOpen = false;
    await _auth.logout();
    AnalyticsService.instance.track(AnalyticsService.instance.clearUserContext);
    _profile.reset();
    _jobs.reset();
    _firstLoginStep = FirstLoginStep.none;
    homeInnerTabIndex = 0;
    creatorsInnerTabIndex = 0;
    jobsInnerTabIndex = 0;
    notifyListeners();
  }

  Future<void> logout() async {
    final uid = user?.id;
    if (uid != null) {
      await PushNotificationService.instance.unregisterToken(uid);
    }
    _pushTapSub?.cancel();
    _pushTapSub = null;
    _messaging?.dispose();
    _messaging = null;
    _notifications?.dispose();
    _notifications = null;
    pendingPushTap = null;
    pendingNotificationsOpen = false;
    await _auth.logout();
    AnalyticsService.instance.track(AnalyticsService.instance.clearUserContext);
    _profile.reset();
    _jobs.reset();
    _firstLoginStep = FirstLoginStep.none;
    homeInnerTabIndex = 0;
    creatorsInnerTabIndex = 0;
    jobsInnerTabIndex = 0;
    notifyListeners();
  }

  Future<void> _onSessionReady(SessionBootstrap bootstrap) async {
    _profile.reset();
    _jobs.reset();
    if (user?.isActive == false) {
      notifyListeners();
      return;
    }
    if (bootstrap.isNewUser) {
      // Don't eagerly write an empty profile doc at login (slow + caused
      // permission issues). Keep it in memory; it's created lazily on first
      // save via ProfileProvider.updateProfile.
      _profile.createLocalDefault(uid: bootstrap.uid);
    } else {
      await _profile.loadProfile(bootstrap.uid);
      if (user?.onboardingCompleted == true) {
        await markLanguagePromptDone();
      }
    }
    _resolveFirstLoginStep();
    notifyListeners();
    _jobs.startBackgroundLoads(
      bootstrap.uid,
      isNewUser: bootstrap.isNewUser,
    );
    _startInbox(bootstrap.uid, isNewUser: bootstrap.isNewUser);
    _syncAnalyticsUser(bootstrap);
  }

  void _syncAnalyticsUser(SessionBootstrap bootstrap) {
    final currentUser = user;
    if (currentUser == null) return;
    final profile = _profile.profile;
    AnalyticsService.instance.track(
      () => AnalyticsService.instance.setUserContext(
        userId: bootstrap.uid,
        accountRole: currentUser.role.name,
        subscriptionStatus: profile?.subscriptionStatus.name,
        profileCompleted: currentUser.onboardingCompleted,
        isVerified: profile?.isVerified,
      ),
    );
    if (bootstrap.isNewUser) {
      AnalyticsService.instance.track(
        () => AnalyticsService.instance.logOnboardingStep('started'),
      );
    }
  }

  void _startInbox(String uid, {bool isNewUser = false}) {
    _pushTapSub?.cancel();
    _messaging?.dispose();
    _notifications?.dispose();
    final displayName = user?.name.trim().isNotEmpty == true ? user!.name : 'User';
    _messaging = MessagingProvider(
      userId: uid,
      userName: displayName,
      isNewUser: isNewUser,
      onChange: notifyListeners,
    );
    _messaging!.start();
    _notifications = NotificationsProvider(
      userId: uid,
      onChange: notifyListeners,
    );
    _notifications!.start();
    unawaited(PushNotificationService.instance.registerToken(uid));
    _pushTapSub = PushNotificationService.instance.onNotificationTap.listen(
      _handlePushTap,
    );
  }

  void _handlePushTap(PushTapTarget target) {
    if (target.opensConversation) {
      pendingNotificationsOpen = false;
      pendingPushTap = null;
      _messaging?.queueConversationOpen(target.conversationId);
      requestedMainShellTab = 3;
      notifyListeners();
      return;
    }
    pendingPushTap = target;
    pendingNotificationsOpen = true;
    notifyListeners();
  }

  PushTapTarget? consumePendingPushTap() {
    final target = pendingPushTap;
    pendingPushTap = null;
    return target;
  }

  void clearPendingNotificationsOpen() {
    if (!pendingNotificationsOpen) return;
    pendingNotificationsOpen = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _categoriesSub?.cancel();
    _bannersSub?.cancel();
    _deepLinkSub?.cancel();
    _pushTapSub?.cancel();
    _messaging?.dispose();
    _notifications?.dispose();
    super.dispose();
  }
}
