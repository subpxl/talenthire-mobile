import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:bombay_casting/core/models/models.dart';
import 'package:bombay_casting/core/services/storage_service.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider({required this._onChange});

  final StorageService storageService = StorageService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final VoidCallback _onChange;

  Profile? profile;
  bool isUploadingPhoto = false;

  void _notify() {
    notifyListeners();
    _onChange();
  }

  Future<void> createDefault({
    required String uid,
    String profileImage = '',
  }) async {
    profile = Profile(userId: uid, profileImage: profileImage);
    await _firestore.collection('profiles').doc(uid).set(profile!.toJson());
    _notify();
  }

  Future<void> loadProfile(String uid) async {
    profile = null;
    _notify();
    try {
      final profileDoc = await _firestore.collection('profiles').doc(uid).get();
      if (profileDoc.exists) {
        final data = Map<String, dynamic>.from(profileDoc.data()!);
        data['user_id'] = uid;
        profile = Profile.fromJson(data);
      } else {
        profile = Profile(userId: uid);
        await _firestore.collection('profiles').doc(uid).set(profile!.toJson());
      }
    } catch (error) {
      debugPrint('Error loading profile: $error');
      profile = Profile(userId: uid);
    }
    _notify();
  }

  Future<void> syncGooglePhoto(String? googlePhoto) async {
    if (googlePhoto == null ||
        googlePhoto.isEmpty ||
        profile == null ||
        (profile!.profileImage).isNotEmpty) {
      return;
    }
    await updateProfile(profile!.copyWith(profileImage: googlePhoto));
  }

  Future<void> updateProfile(Profile updated, {String? userId}) async {
    profile = updated;
    _notify();
    if (userId == null) return;
    final data = updated.toJson()
      ..remove('subscription_status')
      ..remove('is_verified')
      ..remove('account_status')
      ..remove('free_job_applications_used');
    await _firestore.collection('profiles').doc(userId).set(
          data,
          SetOptions(merge: true),
        );
  }

  Future<void> uploadProfilePhoto({
    required String userId,
    required File file,
  }) async {
    if (profile == null) return;
    final current = profile!.galleryPhotos;
    if (current.length >= Profile.maxPhotos) return;
    isUploadingPhoto = true;
    _notify();
    try {
      final url = await storageService.uploadProfilePhoto(
        userId: userId,
        file: file,
      );
      final photos = [...current.where((item) => item != url), url];
      await updateProfile(
        profile!.copyWith(profileImage: photos.first, photos: photos),
        userId: userId,
      );
    } catch (error) {
      debugPrint('Error uploading profile photo: $error');
      rethrow;
    } finally {
      isUploadingPhoto = false;
      _notify();
    }
  }

  Future<String?> uploadVerificationDocument({
    required String userId,
    required File file,
  }) async {
    return storageService.uploadDocument(
      userId: userId,
      file: file,
      folder: 'verification',
    );
  }

  Future<void> removeProfilePhoto(String url, {String? userId}) async {
    if (profile == null) return;
    final photos = profile!.galleryPhotos.where((item) => item != url).toList();
    await updateProfile(
      profile!.copyWith(
        profileImage: photos.isEmpty ? '' : photos.first,
        photos: photos,
      ),
      userId: userId,
    );
    try {
      await storageService.deleteProfilePhoto(url);
    } catch (error) {
      debugPrint('Error deleting profile photo: $error');
    }
  }

  void reset() {
    profile = null;
    isUploadingPhoto = false;
    _notify();
  }
}
