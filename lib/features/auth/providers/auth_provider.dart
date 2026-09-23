import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:bombay_casting/core/models/models.dart';
import 'package:bombay_casting/core/services/auth_service.dart';
import 'package:bombay_casting/core/services/analytics_service.dart';
import 'package:bombay_casting/core/services/referral_service.dart';
import 'package:bombay_casting/core/services/user_cache_service.dart';

class SessionBootstrap {
  const SessionBootstrap({
    required this.uid,
    this.isNewUser = false,
  });

  final String uid;
  final bool isNewUser;
}

typedef AuthSessionLoader = Future<void> Function(SessionBootstrap bootstrap);

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required this._onSessionReady,
    required this._onChange,
  }) {
    _init();
  }

  final AuthService authService = AuthService();
  final UserCacheService _userCache = UserCacheService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthSessionLoader _onSessionReady;
  final VoidCallback _onChange;

  bool isLoading = true;
  bool isAuthenticated = false;
  String? lastAuthError;
  User? user;

  /// Whether the `users/{uid}` document is known to exist in Firestore.
  /// Drives create-vs-update behaviour in [updateUser] so a partial merge is
  /// never rejected as a failed create.
  bool _userDocExists = false;

  void _notify() {
    notifyListeners();
    _onChange();
  }

  Future<void> _init() async {
    try {
      await authService.initializeGoogleSignIn();
    } catch (error) {
      debugPrint('Google Sign-In init skipped: $error');
    }
    if (authService.isLoggedIn) {
      await _loadExistingSession(authService.uid!);
    } else {
      isAuthenticated = false;
    }
    isLoading = false;
    _notify();
  }

  Future<bool> loginWithGoogle() async {
    lastAuthError = null;
    final credential = await authService.signInWithGoogle();
    if (credential?.user == null) {
      lastAuthError = authService.lastError ?? 'Google Sign-In failed.';
      _notify();
      return false;
    }

    final firebaseUser = credential!.user!;
    final ready = await _createOrFetchUser(
      uid: firebaseUser.uid,
      name: firebaseUser.displayName ?? '',
      email: firebaseUser.email ?? '',
    );
    if (!ready) {
      await authService.signOut();
      user = null;
      _userDocExists = false;
      isAuthenticated = false;
      _notify();
      return false;
    }
    isAuthenticated = true;
    AnalyticsService.instance.track(
      () => AnalyticsService.instance.logLogin('google'),
    );
    _notify();
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
      _notify();
      return false;
    }

    final firebaseUser = credential!.user!;
    final ready = await _createOrFetchUser(
      uid: firebaseUser.uid,
      name: firebaseUser.displayName ?? email.split('@').first,
      email: firebaseUser.email ?? email.trim(),
    );
    if (!ready) {
      await authService.signOut();
      user = null;
      _userDocExists = false;
      isAuthenticated = false;
      _notify();
      return false;
    }
    isAuthenticated = true;
    AnalyticsService.instance.track(
      () => AnalyticsService.instance.logLogin('email'),
    );
    _notify();
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
      _notify();
      return false;
    }

    final firebaseUser = credential!.user!;
    final ready = await _createOrFetchUser(
      uid: firebaseUser.uid,
      name: name.trim().isNotEmpty ? name.trim() : email.split('@').first,
      email: firebaseUser.email ?? email.trim(),
    );
    if (!ready) {
      await authService.signOut();
      user = null;
      _userDocExists = false;
      isAuthenticated = false;
      _notify();
      return false;
    }
    isAuthenticated = true;
    AnalyticsService.instance.track(
      () => AnalyticsService.instance.logSignUp('email'),
    );
    _notify();
    return true;
  }

  Future<void> _backfillProfileFromAuth({
    required String name,
    required String email,
  }) async {
    if (user == null) return;
    final trimmedEmail = email.trim();
    final trimmedName = name.trim();
    final needsEmail = user!.email.trim().isEmpty && trimmedEmail.isNotEmpty;
    final needsName = user!.name.trim().isEmpty && trimmedName.isNotEmpty;
    if (!needsEmail && !needsName) return;
    await updateUser(
      name: needsName ? trimmedName : null,
      email: needsEmail ? trimmedEmail : null,
    );
  }

  Future<bool> _createOrFetchUser({
    required String uid,
    required String name,
    required String email,
    String mobile = '',
  }) async {
    try {
      final cached = await _userCache.read(uid);
      if (cached != null) {
        _userDocExists = true;
        user = cached.user;
        await _backfillProfileFromAuth(name: name, email: email);
        await _onSessionReady(SessionBootstrap(uid: uid));
        if (!cached.isFresh) {
          unawaited(_syncUserFromServer(uid: uid));
        }
        return true;
      }

      final userDoc = await _firestore.collection('users').doc(uid).get();
      final isNewUser = !userDoc.exists;
      if (isNewUser) {
        final referredByCode = await ReferralService.pendingReferralCode();
        user = User(
          id: uid,
          name: name,
          email: email,
          mobile: mobile,
          onboardingCompleted: false,
          onboardingStep: 'mobile',
          referredByCode: referredByCode,
        );
        await Future.wait([
          _firestore
              .collection('users')
              .doc(uid)
              .set(user!.toJson())
              .then((_) async {
            _userDocExists = true;
            if (referredByCode != null) {
              await ReferralService.clearPendingReferralCode();
            }
          }),
          _onSessionReady(
            SessionBootstrap(
              uid: uid,
              isNewUser: true,
            ),
          ),
        ]);
      } else {
        _userDocExists = true;
        final data = Map<String, dynamic>.from(userDoc.data()!);
        data['id'] = data['id']?.toString().isNotEmpty == true ? data['id'] : uid;
        user = User.fromJson(data);
        await _backfillProfileFromAuth(name: name, email: email);
        await _userCache.write(uid, user!);
        await _onSessionReady(
          SessionBootstrap(uid: uid),
        );
      }
      return true;
    } catch (error) {
      debugPrint('Error creating/fetching user: $error');
      lastAuthError = 'Failed to load account data.';
      return false;
    }
  }

  Future<void> _syncUserFromServer({required String uid}) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) return;
      final data = Map<String, dynamic>.from(userDoc.data()!);
      data['id'] = data['id']?.toString().isNotEmpty == true ? data['id'] : uid;
      user = User.fromJson(data);
      _userDocExists = true;
      await _userCache.write(uid, user!);
      _notify();
    } catch (error) {
      debugPrint('Background user sync failed: $error');
    }
  }

  Future<void> _loadExistingSession(String uid) async {
    try {
      final firebaseUser = authService.currentUser;
      if (firebaseUser == null) {
        isAuthenticated = false;
        return;
      }

      final email = firebaseUser.email ?? '';
      final ready = await _createOrFetchUser(
        uid: uid,
        name: firebaseUser.displayName ??
            (email.isNotEmpty ? email.split('@').first : ''),
        email: email,
      );
      if (!ready) {
        await authService.signOut();
        user = null;
        _userDocExists = false;
        isAuthenticated = false;
        return;
      }
      isAuthenticated = true;
    } catch (error) {
      debugPrint('Error loading user data: $error');
      lastAuthError = 'Failed to load app data.';
      await authService.signOut();
      user = null;
      _userDocExists = false;
      isAuthenticated = false;
    }
  }

  Future<void> updateUser({
    String? name,
    String? email,
    String? mobile,
    bool? onboardingCompleted,
    String? onboardingStep,
  }) async {
    if (user == null) return;
    user = user!.copyWith(
      name: name,
      email: email,
      mobile: mobile,
      onboardingCompleted: onboardingCompleted,
      onboardingStep: onboardingStep,
      updatedAt: DateTime.now(),
    );
    _notify();
    final ref = _firestore.collection('users').doc(user!.id);

    if (!_userDocExists) {
      // Document doesn't exist yet → write the full, rules-valid user object so
      // it satisfies the stricter `create` security rule (role, id, name,
      // email, ...). A partial merge here would be rejected as a failed create.
      await ref.set(user!.toJson(), SetOptions(merge: true));
      _userDocExists = true;
      unawaited(_userCache.write(user!.id, user!));
      return;
    }

    // Document exists → merge only the changed fields (matches the `update`
    // security rule's allowed key set).
    final data = <String, dynamic>{
      'updated_at': user!.updatedAt.toIso8601String(),
    };
    if (name != null) data['name'] = name;
    if (email != null) data['email'] = email;
    if (mobile != null) data['mobile'] = mobile;
    if (onboardingCompleted != null) {
      data['onboarding_completed'] = onboardingCompleted;
    }
    if (onboardingStep != null) data['onboarding_step'] = onboardingStep;
    await ref.set(data, SetOptions(merge: true));
    if (user != null) {
      unawaited(_userCache.write(user!.id, user!));
    }
  }

  Future<void> deactivateAccount() async {
    await _setIsActive(false);
  }

  Future<void> reactivateAccount() async {
    await _setIsActive(true);
  }

  Future<void> _setIsActive(bool isActive) async {
    if (user == null) return;
    final updatedAt = DateTime.now();
    await _firestore.collection('users').doc(user!.id).set(
      {
        'is_active': isActive,
        'updated_at': updatedAt.toIso8601String(),
      },
      SetOptions(merge: true),
    );
    user = user!.copyWith(isActive: isActive, updatedAt: updatedAt);
  }

  Future<void> logout() async {
    await authService.signOut();
    await _userCache.clear();
    user = null;
    _userDocExists = false;
    isAuthenticated = false;
    _notify();
  }
}
