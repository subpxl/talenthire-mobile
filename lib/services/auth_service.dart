import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

/// Web OAuth client ID from Firebase (client_type 3 in google-services.json).
/// Required on Android so Google returns an idToken for Firebase Auth.
const _kGoogleWebClientId =
    '483545794550-0lumq7gtac5k4tt6idq58q4hhv54ie98.apps.googleusercontent.com';

class AuthService {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;

  fb.User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  String? get uid => currentUser?.uid;
  String? lastError;

  // ===== Google Sign-In =====
  Future<void> initializeGoogleSignIn() async {
    await GoogleSignIn.instance.initialize(
      serverClientId: _kGoogleWebClientId,
    );
  }

  Future<fb.UserCredential?> signInWithGoogle() async {
    lastError = null;
    try {
      await initializeGoogleSignIn();
      // Clear any stale Credential Manager session from a prior attempt.
      await GoogleSignIn.instance.signOut();

      final GoogleSignInAccount googleUser =
          await GoogleSignIn.instance.authenticate();

      final idToken = googleUser.authentication.idToken;
      if (idToken == null) {
        lastError =
            'Google did not return an ID token. Register your app SHA-1 in Firebase Console, enable Google sign-in, then re-download google-services.json.';
        debugPrint('Google Sign-In error: $lastError');
        return null;
      }

      final credential = fb.GoogleAuthProvider.credential(idToken: idToken);
      return await _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      final details = e.toString();
      if (details.contains('Account reauth failed') || details.contains('[16]')) {
        lastError =
            'Google Sign-In failed: your app SHA-1 is not registered in Firebase. '
            'Add SHA-1 for package com.talenthire.app in Firebase Console → Project settings → Your apps, '
            'enable Google sign-in under Authentication, then re-download google-services.json.';
        debugPrint('Google Sign-In error: $lastError');
        return null;
      }
      if (e.code == GoogleSignInExceptionCode.canceled) {
        lastError = null;
        debugPrint('Google Sign-In cancelled');
        return null;
      }
      lastError = details;
      debugPrint('Google Sign-In error: $e');
      return null;
    } on fb.FirebaseAuthException catch (e) {
      lastError = e.message ?? e.code;
      debugPrint('Firebase Auth error: ${e.code} — ${e.message}');
      return null;
    } catch (e, stack) {
      lastError = e.toString();
      debugPrint('Google Sign-In error: $e\n$stack');
      return null;
    }
  }

  // ===== Phone OTP =====
  Future<void> sendOtp({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    required Function(fb.PhoneAuthCredential credential) onAutoVerify,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: '+91$phoneNumber',
        verificationCompleted: (fb.PhoneAuthCredential credential) {
          onAutoVerify(credential);
        },
        verificationFailed: (fb.FirebaseAuthException e) {
          onError(e.message ?? 'Verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  Future<fb.UserCredential?> verifyOtp({
    required String verificationId,
    required String otp,
  }) async {
    try {
      final credential = fb.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint('OTP verification error: $e');
      return null;
    }
  }

  Future<fb.UserCredential?> signInWithPhoneCredential(fb.PhoneAuthCredential credential) async {
    try {
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Auto OTP verification error: $e');
      return null;
    }
  }

  // ===== Sign Out =====
  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }
}
