import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:bombay_casting/core/models/models.dart';
import 'package:bombay_casting/core/services/auth_service.dart';

class SessionBootstrap {
  const SessionBootstrap({
    required this.uid,
    this.isNewUser = false,
    this.googlePhotoUrl,
  });

  final String uid;
  final bool isNewUser;
  final String? googlePhotoUrl;
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthSessionLoader _onSessionReady;
  final VoidCallback _onChange;

  bool isLoading = true;
  bool isAuthenticated = false;
  String? lastAuthError;
  User? user;

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
    await _createOrFetchUser(
      uid: firebaseUser.uid,
      name: firebaseUser.displayName ?? '',
      email: firebaseUser.email ?? '',
    );
    isAuthenticated = true;
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
    await _createOrFetchUser(
      uid: firebaseUser.uid,
      name: firebaseUser.displayName ?? email.split('@').first,
      email: firebaseUser.email ?? email.trim(),
    );
    isAuthenticated = true;
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
    await _createOrFetchUser(
      uid: firebaseUser.uid,
      name: name.trim().isNotEmpty ? name.trim() : email.split('@').first,
      email: firebaseUser.email ?? email.trim(),
    );
    isAuthenticated = true;
    _notify();
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
      final isNewUser = !userDoc.exists;
      if (isNewUser) {
        user = User(id: uid, name: name, email: email, mobile: mobile);
        await Future.wait([
          _firestore.collection('users').doc(uid).set(user!.toJson()),
          _onSessionReady(
            SessionBootstrap(
              uid: uid,
              isNewUser: true,
              googlePhotoUrl: authService.currentUser?.photoURL,
            ),
          ),
        ]);
      } else {
        final data = Map<String, dynamic>.from(userDoc.data()!);
        data['id'] = data['id']?.toString().isNotEmpty == true ? data['id'] : uid;
        user = User.fromJson(data);
        await _onSessionReady(
          SessionBootstrap(
            uid: uid,
            googlePhotoUrl: authService.currentUser?.photoURL,
          ),
        );
      }
    } catch (error) {
      debugPrint('Error creating/fetching user: $error');
      lastAuthError = 'Failed to load account data.';
    }
  }

  Future<void> _loadExistingSession(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final data = Map<String, dynamic>.from(userDoc.data()!);
        data['id'] = data['id']?.toString().isNotEmpty == true ? data['id'] : uid;
        user = User.fromJson(data);
      }
      await _onSessionReady(SessionBootstrap(uid: uid));
      isAuthenticated = true;
    } catch (error) {
      debugPrint('Error loading user data: $error');
      lastAuthError = 'Failed to load app data.';
      isAuthenticated = false;
    }
  }

  Future<void> updateUser({
    String? name,
    String? email,
    String? mobile,
  }) async {
    if (user == null) return;
    user = user!.copyWith(
      name: name,
      email: email,
      mobile: mobile,
      updatedAt: DateTime.now(),
    );
    _notify();
    await _firestore.collection('users').doc(user!.id).set(
          user!.toJson(),
          SetOptions(merge: true),
        );
  }

  Future<void> logout() async {
    await authService.signOut();
    user = null;
    isAuthenticated = false;
    _notify();
  }
}
