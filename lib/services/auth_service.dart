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
      // NOTE: GoogleSignIn.instance is already initialized at app startup (app_state._init).
      // Do NOT call initialize() again here — double-init resets Credential Manager state.
      // Do NOT call signOut() here — it wipes Credential Manager's cached credential,
      // which causes error [16] "Account reauth failed" even when SHA-1 is correct.

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
      // Error code [16] = DEVELOPER_ERROR. Can mean SHA-1 not registered, OR
      // Credential Manager has no usable credential (e.g. no Google account on device,
      // or the Credential Manager flow was interrupted). Not always a SHA-1 issue.
      if (details.contains('Account reauth failed') || details.contains('[16]')) {
        lastError =
            'Google Sign-In failed. Please make sure you have a Google account added on '
            'this device and try again. If the issue persists, restart the app.';
        debugPrint('Google Sign-In DEVELOPER_ERROR [16]: $details');
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

  // ===== Email & Password =====
  Future<fb.UserCredential?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    lastError = null;
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on fb.FirebaseAuthException catch (e) {
      lastError = _emailAuthMessage(e);
      debugPrint('Email sign-in error: ${e.code} — ${e.message}');
      return null;
    } catch (e) {
      lastError = e.toString();
      debugPrint('Email sign-in error: $e');
      return null;
    }
  }

  Future<fb.UserCredential?> registerWithEmailPassword({
    required String email,
    required String password,
    String name = '',
  }) async {
    lastError = null;
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Firebase Auth doesn't set displayName for email/password signup.
      // Set it explicitly so it's available immediately (matching Google flow).
      final displayName = name.trim().isNotEmpty
          ? name.trim()
          : email.split('@').first;
      await credential.user?.updateDisplayName(displayName);
      await credential.user?.reload();

      return credential;
    } on fb.FirebaseAuthException catch (e) {
      lastError = _emailAuthMessage(e);
      debugPrint('Email registration error: ${e.code} — ${e.message}');
      return null;
    } catch (e) {
      lastError = e.toString();
      debugPrint('Email registration error: $e');
      return null;
    }
  }

  String _emailAuthMessage(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  // ===== Sign Out =====
  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }
}
