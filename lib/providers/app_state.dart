import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import '../models/transaction.dart';
import '../services/auth_service.dart';
import '../services/cashfree_service.dart';
import '../services/messaging_service.dart';
import '../services/notification_service.dart';

class AppState extends ChangeNotifier {
  bool isLoading = true;
  bool isAuthenticated = false;
  bool needsDobVerification = false;

  User? user;
  UserRole? userRole;

  Profile? profile;
  List<Profile> allInfluencers = [];
  List<Artist> artists = [];

  List<Job> jobs = [];
  List<Conversation> conversations = [];
  List<Application> applications = [];
  List<Job> savedJobs = [];
  List<AppTransaction> transactions = [];
  List<String> categories = ['Actor', 'Dancer', 'Influencer', 'Model', 'Musician', 'Other'];

  StreamSubscription? _conversationsSub;
  StreamSubscription? _applicationsSub;

  final AuthService authService = AuthService();
  final CashfreeService cashfreeService = CashfreeService();
  final MessagingService messagingService = MessagingService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool get isProfileCompleted => profile?.profileCompleted ?? false;

  AppState() {
    _init();
  }

  Future<void> _init() async {
    if (authService.isLoggedIn) {
      await _loadUserData(authService.uid!);
    } else {
      isAuthenticated = false;
    }
    isLoading = false;
    notifyListeners();
  }

  String? lastAuthError;

  Future<bool> loginWithGoogle(UserRole role) async {
    lastAuthError = null;

    final credential = await authService.signInWithGoogle();
    if (credential != null && credential.user != null) {
      final firebaseUser = credential.user!;
      userRole = role;

      await _createOrFetchUser(
        uid: firebaseUser.uid,
        name: firebaseUser.displayName ?? '',
        email: firebaseUser.email ?? '',
        role: role,
      );

      isAuthenticated = true;
      notifyListeners();
      return true;
    }

    lastAuthError = authService.lastError ?? 'Google Sign-In failed.';
    notifyListeners();
    return false;
  }

  Future<bool> loginWithEmail({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    lastAuthError = null;

    final credential = await authService.signInWithEmailPassword(
      email: email,
      password: password,
    );

    if (credential != null && credential.user != null) {
      final firebaseUser = credential.user!;
      userRole = role;

      await _createOrFetchUser(
        uid: firebaseUser.uid,
        name: firebaseUser.displayName ?? email.split('@').first,
        email: firebaseUser.email ?? email.trim(),
        role: role,
      );

      isAuthenticated = true;
      notifyListeners();
      return true;
    }

    lastAuthError = authService.lastError ?? 'Sign in failed.';
    notifyListeners();
    return false;
  }

  Future<bool> registerWithEmail({
    required String email,
    required String password,
    required UserRole role,
    String name = '',
  }) async {
    lastAuthError = null;

    final credential = await authService.registerWithEmailPassword(
      email: email,
      password: password,
      name: name.trim().isNotEmpty ? name.trim() : email.split('@').first,
    );

    if (credential != null && credential.user != null) {
      final firebaseUser = credential.user!;
      userRole = role;
      final displayName = name.trim().isNotEmpty
          ? name.trim()
          : email.split('@').first;

      await _createOrFetchUser(
        uid: firebaseUser.uid,
        name: displayName,
        email: firebaseUser.email ?? email.trim(),
        role: role,
      );

      isAuthenticated = true;
      notifyListeners();
      return true;
    }

    lastAuthError = authService.lastError ?? 'Registration failed.';
    notifyListeners();
    return false;
  }

  Future<bool> loginWithOtp({
    required String verificationId,
    required String otp,
    required UserRole role,
  }) async {
    lastAuthError = null;

    final credential = await authService.verifyOtp(
      verificationId: verificationId,
      otp: otp,
    );

    if (credential != null && credential.user != null) {
      final firebaseUser = credential.user!;
      userRole = role;

      await _createOrFetchUser(
        uid: firebaseUser.uid,
        name: firebaseUser.displayName ?? '',
        email: firebaseUser.email ?? '',
        mobile: firebaseUser.phoneNumber ?? '',
        role: role,
      );

      isAuthenticated = true;
      notifyListeners();
      return true;
    }

    lastAuthError = 'Invalid OTP. Please try again.';
    notifyListeners();
    return false;
  }

  Future<bool> loginWithPhoneCredential({
    required dynamic credential,
    required UserRole role,
  }) async {
    lastAuthError = null;

    final userCredential = await authService.signInWithPhoneCredential(credential);

    if (userCredential != null && userCredential.user != null) {
      final firebaseUser = userCredential.user!;
      userRole = role;

      await _createOrFetchUser(
        uid: firebaseUser.uid,
        name: firebaseUser.displayName ?? '',
        email: firebaseUser.email ?? '',
        mobile: firebaseUser.phoneNumber ?? '',
        role: role,
      );

      isAuthenticated = true;
      notifyListeners();
      return true;
    }

    lastAuthError = 'Phone verification failed.';
    notifyListeners();
    return false;
  }

  Future<void> _createOrFetchUser({
    required String uid,
    required String name,
    required String email,
    String mobile = '',
    required UserRole role,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists) {
        user = User.fromJson(userDoc.data()!);
        userRole = user!.role;
        needsDobVerification = user!.birthYear == null || user!.birthMonth == null || user!.birthDay == null;
      } else {
        user = User(
          id: uid,
          name: name,
          email: email,
          mobile: mobile,
          role: role,
        );
        await _firestore.collection('users').doc(uid).set(user!.toJson());
        needsDobVerification = true;
      }

      await _loadUserData(uid);
    } catch (e) {
      debugPrint('Error creating/fetching user: $e');
    }
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        user = User.fromJson(userDoc.data()!);
        userRole = user!.role;
        needsDobVerification = user!.birthYear == null || user!.birthMonth == null || user!.birthDay == null;
      }

      // Run independent data loads in parallel instead of sequentially.
      // This cuts login wait from ~10 round trips to ~2.
      await Future.wait([
        _loadInfluencerData(uid),
        _loadApplications(uid),
        _loadSavedJobs(uid),
        _loadTransactions(uid),
        _loadSharedData(),
        NotificationService().registerForUser(uid),
      ]);

      _listenToConversations(uid);
      _listenToApplications(uid);

      isAuthenticated = true;
    } catch (e) {
      debugPrint('Error loading user data: $e');
      lastAuthError = 'Failed to load app data. Please pull to refresh.';
      isAuthenticated = false;
    }
  }

  Future<void> _loadApplications(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('applications')
          .where('user_id', isEqualTo: uid)
          .get();
      applications = snapshot.docs.map((d) {
        final data = Map<String, dynamic>.from(d.data());
        if ((data['id']?.toString() ?? '').isEmpty) data['id'] = d.id;
        return Application.fromJson(data);
      }).where((a) => a.status != ApplicationStatus.withdrawn).toList();
    } catch (e) {
      debugPrint('Error loading applications: $e');
      applications = [];
    }
  }

  void _listenToApplications(String uid) {
    _applicationsSub?.cancel();
    _applicationsSub = _firestore
        .collection('applications')
        .where('user_id', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) {
      applications = snapshot.docs.map((d) {
        final data = Map<String, dynamic>.from(d.data());
        if ((data['id']?.toString() ?? '').isEmpty) data['id'] = d.id;
        return Application.fromJson(data);
      }).where((a) => a.status != ApplicationStatus.withdrawn).toList();
      notifyListeners();
    }, onError: (e) {
      debugPrint('Error listening to applications: $e');
    });
  }

  Future<void> _loadTransactions(String uid) async {
    try {
      final query1 = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: uid)
          .get();
      final query2 = await _firestore
          .collection('transactions')
          .where('fromUserId', isEqualTo: uid)
          .get();
      final query3 = await _firestore
          .collection('transactions')
          .where('toUserId', isEqualTo: uid)
          .get();

      final Map<String, AppTransaction> txsMap = {};

      for (final snapshot in [query1, query2, query3]) {
        for (var doc in snapshot.docs) {
          final data = doc.data();
          data['id'] = doc.id;
          txsMap[doc.id] = AppTransaction.fromJson(data);
        }
      }

      transactions = txsMap.values.toList();
      transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('Error loading transactions: $e');
      transactions = [];
    }
  }

  Future<void> _loadSavedJobs(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('saved_jobs')
          .get();
      savedJobs = snapshot.docs.map((d) => Job.fromJson(d.data())).toList();
    } catch (e) {
      debugPrint('Error loading saved jobs: $e');
      savedJobs = [];
    }
  }

  void _listenToConversations(String uid) {
    _conversationsSub?.cancel();
    _conversationsSub = _firestore
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .orderBy('updated_at', descending: true)
        .snapshots()
        .listen((snapshot) {
      conversations = snapshot.docs.map((d) {
        final data = d.data();
        data['id'] = d.id;
        return Conversation.fromJson(data);
      }).toList();
      notifyListeners();
    });
  }

  Future<void> _loadInfluencerData(String uid) async {
    try {
      final profileDoc = await _firestore.collection('profiles').doc(uid).get();
      if (profileDoc.exists) {
        profile = Profile.fromJson(profileDoc.data()!);
      } else {
        profile = Profile(userId: uid);
        await _firestore.collection('profiles').doc(uid).set(profile!.toJson());
      }
    } catch (e) {
      debugPrint('Error loading influencer data: $e');
      profile = Profile(userId: uid);
    }
  }

  Future<void> _loadSharedData() async {
    try {
      // Run all independent reads in parallel
      final results = await Future.wait([
        _firestore.collection('jobs').get(),
        _firestore.doc('settings/categories').get(),
        _firestore.collection('profiles').get(),
        _firestore.collection('users').where('role', isEqualTo: 'influencer').get(),
      ]);

      final jobsSnapshot = results[0] as QuerySnapshot;
      final categoriesDoc = results[1] as DocumentSnapshot;
      final profilesSnapshot = results[2] as QuerySnapshot;
      final usersSnapshot = results[3] as QuerySnapshot;

      jobs = jobsSnapshot.docs.map((d) {
        final data = Map<String, dynamic>.from(d.data() as Map);
        // Web-created jobs often omit embedded `id`; always prefer doc id.
        final embeddedId = data['id']?.toString() ?? '';
        data['id'] = embeddedId.isNotEmpty ? embeddedId : d.id;
        return Job.fromJson(data);
      }).where((j) {
        // Show open/published jobs (web used "open", mapped to published in model)
        return j.status == JobStatus.published;
      }).toList();

      if (categoriesDoc.exists && (categoriesDoc.data() as Map?)?['talentTypes'] != null) {
        final List<dynamic> types = (categoriesDoc.data() as Map)['talentTypes'];
        categories = types.map((e) => e.toString()).toList();
      }

      allInfluencers = profilesSnapshot.docs.map((d) => Profile.fromJson(d.data() as Map<String, dynamic>)).toList();

      final influencerUsers = usersSnapshot.docs.map((d) => User.fromJson(d.data() as Map<String, dynamic>)).toList();

      artists = influencerUsers.map((influencerUser) {
        final userProfile = allInfluencers.firstWhere(
          (p) => p.userId == influencerUser.id,
          orElse: () => Profile(userId: influencerUser.id),
        );

        final nameParts = influencerUser.name.split(' ');
        final initials = nameParts.length > 1
            ? '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase()
            : (influencerUser.name.isNotEmpty ? influencerUser.name[0].toUpperCase() : '?');

        return Artist(
          id: influencerUser.id,
          name: influencerUser.name,
          role: userProfile.talent.toUpperCase(),
          location: userProfile.city.isNotEmpty
              ? '${userProfile.city}${userProfile.state.isNotEmpty ? ', ${userProfile.state}' : ''}'
              : 'Location not set',
          description: userProfile.bio.isNotEmpty ? userProfile.bio : 'No description provided.',
          skills: [userProfile.talent.toUpperCase()],
          initials: initials,
          profileImage: userProfile.profileImage,
          photos: userProfile.photos,
          socialLinks: userProfile.socialLinks,
          achievementsVideoLink: userProfile.achievementsVideoLink,
          shortIntroVideoLink: userProfile.shortIntroVideoLink,
          previousWorksVideoLink: userProfile.previousWorksVideoLink,
          age: userProfile.age,
          gender: userProfile.gender,
          height: userProfile.height,
          bodyType: userProfile.bodyType,
          ethnicity: userProfile.ethnicity,
          experienceLevel: userProfile.experienceLevel,
        );
      }).toList();
    } catch (e, stacktrace) {
      debugPrint('Error loading shared data: $e\n$stacktrace');
    }
  }

  /// Pull-to-refresh: reload jobs/applications/artists without full-app splash.
  /// Do NOT toggle [isLoading] — main.dart shows SplashScreen when isLoading is true.
  Future<void> refreshData() async {
    try {
      if (user != null) {
        await _loadApplications(user!.id);
        await _loadSavedJobs(user!.id);
        await _loadTransactions(user!.id);
      }
      await _loadSharedData();
    } catch (e) {
      debugPrint('Error refreshing data: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> deactivateAccount() async {
    if (user == null) return;
    try {
      user!.isActive = false;
      await _firestore.collection('users').doc(user!.id).update({
        'is_active': false,
        'updated_at': DateTime.now().toIso8601String(),
      });
      await logout();
    } catch (e) {
      debugPrint('Error deactivating account: $e');
      rethrow;
    }
  }

  Future<void> scheduleAccountDeletion() async {
    if (user == null) return;
    try {
      final deleteDate = DateTime.now().add(const Duration(days: 30));
      user!.scheduledDeletionDate = deleteDate;
      await _firestore.collection('users').doc(user!.id).update({
        'scheduled_deletion_date': deleteDate.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      await logout();
    } catch (e) {
      debugPrint('Error scheduling account deletion: $e');
      rethrow;
    }
  }

  Future<void> reportUser(String reportedUserId, String description) async {
    if (user == null) return;
    try {
      await _firestore.collection('reports').add({
        'reporter_id': user!.id,
        'reported_user_id': reportedUserId,
        'description': description,
        'created_at': DateTime.now().toIso8601String(),
        'status': 'pending',
      });
    } catch (e) {
      debugPrint('Error reporting user: $e');
      rethrow;
    }
  }

  void updateProfile({
    String? name,
    String? email,
    String? phone,
    String? bio,
    String? contact,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? talent,
    String? videoInterviewLink,
    String? achievementsVideoLink,
    String? shortIntroVideoLink,
    String? previousWorksVideoLink,
    List<SocialLink>? socialLinks,
    int? age,
    String? gender,
    String? height,
    String? bodyType,
    String? ethnicity,
    String? experienceLevel,
    List<String>? languages,
  }) {
    if (user == null || profile == null) return;

    if (name != null) {
      user!.name = name;
      _firestore.collection('users').doc(user!.id).update({'name': name});
    }
    if (email != null) {
      user!.email = email;
      _firestore.collection('users').doc(user!.id).update({'email': email});
    }
    if (phone != null) {
      user!.mobile = phone;
      _firestore.collection('users').doc(user!.id).update({'mobile': phone});
    }
    if (bio != null) profile!.bio = bio;
    if (contact != null) profile!.contact = contact;
    if (address != null) profile!.address = address;
    if (city != null) profile!.city = city;
    if (state != null) profile!.state = state;
    if (pincode != null) profile!.pincode = pincode;
    if (talent != null) profile!.talent = talent;
    if (videoInterviewLink != null) profile!.videoInterviewLink = videoInterviewLink;
    if (achievementsVideoLink != null) profile!.achievementsVideoLink = achievementsVideoLink;
    if (shortIntroVideoLink != null) profile!.shortIntroVideoLink = shortIntroVideoLink;
    if (previousWorksVideoLink != null) profile!.previousWorksVideoLink = previousWorksVideoLink;
    if (socialLinks != null) profile!.socialLinks = socialLinks;
    if (age != null) profile!.age = age;
    if (gender != null) profile!.gender = gender;
    if (height != null) profile!.height = height;
    if (bodyType != null) profile!.bodyType = bodyType;
    if (ethnicity != null) profile!.ethnicity = ethnicity;
    if (experienceLevel != null) profile!.experienceLevel = experienceLevel;
    if (languages != null) profile!.languages = languages;

    profile!.profileCompleted = _checkProfileCompletion();

    try {
      _firestore.collection('profiles').doc(user!.id).set(profile!.toJson());
      _loadSharedData();
    } catch (e) {
      debugPrint('Error updating profile: $e');
    }

    notifyListeners();
  }

  bool _checkProfileCompletion() {
    if (profile == null) return false;
    return profile!.profileImage.isNotEmpty &&
        profile!.bio.isNotEmpty &&
        profile!.city.isNotEmpty &&
        profile!.talent.isNotEmpty && profile!.talent.toLowerCase() != 'other';
  }

  int getProfileCompletionPercent() {
    if (profile == null) return 0;
    int total = 0;
    if (profile!.profileImage.isNotEmpty) total += 20;
    if (profile!.bio.isNotEmpty) total += 15;
    if (profile!.city.isNotEmpty) total += 10;
    if (profile!.state.isNotEmpty) total += 5;
    if (profile!.talent.isNotEmpty && profile!.talent.toLowerCase() != 'other') total += 15;
    if (profile!.contact.isNotEmpty) total += 10;
    if (profile!.achievementsVideoLink.isNotEmpty) total += 10;
    if (profile!.shortIntroVideoLink.isNotEmpty) total += 10;
    if (profile!.previousWorksVideoLink.isNotEmpty) total += 5;
    return total;
  }

  void addPhoto(String photoUrl) {
    if (profile == null) return;
    if (profile!.photos.length >= 4) return;

    profile!.photos.add(photoUrl);
    if (profile!.profileImage.isEmpty) {
      profile!.profileImage = photoUrl;
    }
    _firestore.collection('profiles').doc(user!.id).update({
      'photos': profile!.photos,
      'profile_image': profile!.profileImage,
    });
    notifyListeners();
  }

  void removePhoto(String photoUrl) {
    if (profile == null) return;
    profile!.photos.remove(photoUrl);
    if (profile!.profileImage == photoUrl) {
      profile!.profileImage = profile!.photos.isNotEmpty ? profile!.photos.first : '';
    }
    _firestore.collection('profiles').doc(user!.id).update({
      'photos': profile!.photos,
      'profile_image': profile!.profileImage,
    });
    notifyListeners();
  }

  void setProfilePhoto(String photoUrl) {
    if (profile == null) return;
    profile!.profileImage = photoUrl;
    _firestore.collection('profiles').doc(user!.id).update({
      'profile_image': photoUrl,
    });
    notifyListeners();
  }

  bool canApplyToJob() {
    if (profile == null) return false;
    if (profile!.isPremium) return true;
    return profile!.canApplyFreeJob;
  }

  String? getApplyBlockedReason() {
    if (profile == null) return 'Complete your profile first';
    if (profile!.isPremium) return null;
    if (!profile!.canApplyFreeJob) {
      return 'Free accounts can apply to ${AppPricing.freeJobApplicationLimit} job. Upgrade to Premium for unlimited applications.';
    }
    return null;
  }

  Future<bool> applyToJob(
    Job job, {
    String script = '',
    String videoUrl = '',
  }) async {
    if (user == null || !canApplyToJob()) return false;
    if (job.id.isEmpty) {
      debugPrint('Error applying to job: missing job id');
      return false;
    }
    if (applications.any((a) => a.jobId == job.id)) return false;
    if (job.isAudition && videoUrl.trim().isEmpty) {
      debugPrint('Error applying to job: audition video required');
      return false;
    }

    var companyName = job.company;
    if (companyName.isEmpty && job.createdBy.isNotEmpty) {
      try {
        final agencySnap =
            await _firestore.collection('users').doc(job.createdBy).get();
        companyName =
            (agencySnap.data()?['agencyName'] ?? agencySnap.data()?['agency_name'] ?? '')
                .toString();
      } catch (_) {}
    }

    final app = Application(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: user!.id,
      jobId: job.id,
      jobTitle: job.title,
      company: companyName,
      script: script,
      videoUrl: videoUrl.trim(),
    );

    try {
      await _firestore.collection('applications').doc(app.id).set(app.toJson());

      if (profile != null && !profile!.isPremium) {
        profile!.freeJobApplicationsUsed++;
        await _firestore.collection('profiles').doc(user!.id).update({
          'free_job_applications_used': profile!.freeJobApplicationsUsed,
        });
      }

      try {
        await _firestore.collection('jobs').doc(job.id).update({
          'applied': FieldValue.increment(1),
        });
      } catch (e) {
        // Job doc may not have applied field yet; don't fail the application.
        debugPrint('Warning: could not increment job applied count: $e');
      }

      final jobIndex = jobs.indexWhere((j) => j.id == job.id);
      if (jobIndex >= 0) {
        jobs[jobIndex] = jobs[jobIndex].copyWith(applied: jobs[jobIndex].applied + 1);
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error applying to job: $e');
      return false;
    }
  }

  Future<void> updateApplication(String applicationId, {String? script, String? videoUrl}) async {
    if (user == null) return;

    final index = applications.indexWhere((a) => a.id == applicationId);
    if (index < 0) return;

    final app = applications[index];
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (script != null) updates['script'] = script;
    if (videoUrl != null) updates['video_url'] = videoUrl; // Using video_url to match toJson

    try {
      await _firestore.collection('applications').doc(app.id).update(updates);
      // Local state will be updated via the firestore snapshot listener
    } catch (e) {
      debugPrint('Error updating application: $e');
    }
  }

  Future<void> withdrawApplication(String jobId) async {
    if (user == null) return;

    final index = applications.indexWhere((a) => a.jobId == jobId);
    if (index < 0) return;

    final app = applications[index];

    try {
      await _firestore.collection('applications').doc(app.id).update({
        'status': applicationStatusToString(ApplicationStatus.withdrawn),
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (profile != null && !profile!.isPremium && profile!.freeJobApplicationsUsed > 0) {
        profile!.freeJobApplicationsUsed--;
        await _firestore.collection('profiles').doc(user!.id).update({
          'free_job_applications_used': profile!.freeJobApplicationsUsed,
        });
      }

      final jobIndex = jobs.indexWhere((j) => j.id == jobId);
      if (jobIndex >= 0 && jobs[jobIndex].applied > 0) {
        await _firestore.collection('jobs').doc(jobId).update({
          'applied': FieldValue.increment(-1),
        });
        jobs[jobIndex] = jobs[jobIndex].copyWith(applied: jobs[jobIndex].applied - 1);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error withdrawing application: $e');
    }
  }

  Application? getApplicationForJob(String jobId) {
    for (final app in applications) {
      if (app.jobId == jobId) return app;
    }
    return null;
  }

  bool hasApplied(String jobId) {
    return applications.any((a) => a.jobId == jobId);
  }

  Future<void> toggleSavedJob(Job job) async {
    if (user == null) return;

    final index = savedJobs.indexWhere((j) => j.id == job.id);
    final savedRef = _firestore
        .collection('users')
        .doc(user!.id)
        .collection('saved_jobs')
        .doc(job.id);

    if (index >= 0) {
      savedJobs.removeAt(index);
      await savedRef.delete();
    } else {
      savedJobs.add(job);
      await savedRef.set(job.toJson());
    }
    notifyListeners();
  }

  bool isJobSaved(String jobId) {
    return savedJobs.any((j) => j.id == jobId);
  }

  Future<Conversation?> getOrCreateConversation(
    String participantName,
    String participantId, {
    String type = 'talent',
  }) async {
    if (user == null) return null;
    if (user!.id == participantId) return null;

    // Check in-memory first
    final existingLocal = conversations.where((c) => c.participants.contains(participantId));
    if (existingLocal.isNotEmpty) return existingLocal.first;

    // Check Firestore to avoid duplicates
    final existingRemote = await messagingService.findExistingConversation(
      user!.id,
      participantId,
    );
    if (existingRemote != null) return existingRemote;

    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final initials = participantName.isNotEmpty
        ? participantName.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : '??';

    final myInitials = user!.name.isNotEmpty
        ? user!.name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : '??';

    final newConversation = Conversation(
      id: newId,
      lastMessage: 'Start a conversation...',
      participants: [user!.id, participantId],
      unreadCounts: {user!.id: 0, participantId: 0},
      participantNames: {
        user!.id: user!.name,
        participantId: participantName,
      },
      participantInitials: {
        user!.id: myInitials,
        participantId: initials,
      },
      participantTypes: {
        user!.id: userRoleToString(user!.role),
        participantId: type,
      },
    );

    await messagingService.createConversation(newConversation);
    return newConversation;
  }

  Future<void> sendMessage(String conversationId, String text) async {
    if (user == null) return;

    String recipientId = '';
    final local = conversations.where((c) => c.id == conversationId);
    if (local.isNotEmpty) {
      recipientId = local.first.getOtherParticipantId(user!.id);
    } else {
      final doc = await _firestore.collection('conversations').doc(conversationId).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        recipientId = Conversation.fromJson(data).getOtherParticipantId(user!.id);
      }
    }
    if (recipientId.isEmpty) return;

    await messagingService.sendMessage(
      conversationId: conversationId,
      senderId: user!.id,
      recipientId: recipientId,
      text: text,
    );
  }

  Future<void> markConversationAsRead(String conversationId) async {
    if (user == null) return;
    await messagingService.markAsRead(conversationId, user!.id);

    final index = conversations.indexWhere((c) => c.id == conversationId);
    if (index >= 0) {
      conversations[index].unreadCounts[user!.id] = 0;
      notifyListeners();
    }
  }

  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    return messagingService.watchMessages(conversationId);
  }

  Future<Conversation?> getConversationById(String conversationId) async {
    final local = conversations.where((c) => c.id == conversationId);
    if (local.isNotEmpty) return local.first;

    final doc = await _firestore.collection('conversations').doc(conversationId).get();
    if (doc.exists) {
      final data = doc.data()!;
      data['id'] = doc.id;
      return Conversation.fromJson(data);
    }
    return null;
  }

  int get totalUnreadMessages {
    if (user == null) return 0;
    return conversations.fold<int>(
      0,
      (total, c) => total + c.unreadFor(user!.id),
    );
  }

  Future<bool> completeDobVerification({
    required int birthMonth,
    required int birthDay,
    required int birthYear,
  }) async {
    if (user == null) return false;
    final now = DateTime.now();
    var age = now.year - birthYear;
    if (now.month < birthMonth || (now.month == birthMonth && now.day < birthDay)) age--;
    if (age < 18) return false;

    try {
      await _firestore.collection('users').doc(user!.id).update({
        'birth_month': birthMonth,
        'birth_day': birthDay,
        'birth_year': birthYear,
        'updated_at': DateTime.now().toIso8601String(),
      });
      user!.birthMonth = birthMonth;
      user!.birthDay = birthDay;
      user!.birthYear = birthYear;
      needsDobVerification = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error saving DOB: $e');
      return false;
    }
  }

  Future<bool> upgradeToPremium() async {
    if (user == null) return false;
    final success = await cashfreeService.upgradeToPremium(user!.id);
    if (success && profile != null) {
      profile!.subscriptionStatus = SubscriptionStatus.premium;
      profile!.isVerified = true;
      await _loadTransactions(user!.id);
      notifyListeners();
    }
    return success;
  }

  Future<void> logout() async {
    if (user != null) {
      await NotificationService().unregisterForUser(user!.id);
    }
    await authService.signOut();
    _conversationsSub?.cancel();
    _applicationsSub?.cancel();
    isAuthenticated = false;
    user = null;
    userRole = null;
    profile = null;
    applications.clear();
    savedJobs.clear();
    transactions.clear();
    conversations.clear();
    notifyListeners();
  }
}
