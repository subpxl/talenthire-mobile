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
  }) {
    return uploadProfilePhotos(userId: userId, files: [file]);
  }

  Future<void> uploadProfilePhotos({
    required String userId,
    required List<File> files,
    int? mainIndex,
  }) async {
    if (profile == null || files.isEmpty) return;
    final current = profile!.galleryPhotos;
    final remaining = Profile.maxPhotos - current.length;
    if (remaining <= 0) return;
    final toUpload = files.take(remaining).toList();
    isUploadingPhoto = true;
    _notify();
    final newUrls = <String>[];
    try {
      for (var i = 0; i < toUpload.length; i++) {
        final url = await storageService.uploadProfilePhoto(
          userId: userId,
          file: toUpload[i],
          fileName: '${DateTime.now().microsecondsSinceEpoch}_$i.jpg',
        );
        newUrls.add(url);
      }
      await _saveGallery(
        current: current,
        newUrls: newUrls,
        mainIndex: mainIndex,
        userId: userId,
      );
    } catch (error) {
      debugPrint('Error uploading profile photo: $error');
      if (newUrls.isNotEmpty) {
        try {
          await _saveGallery(
            current: current,
            newUrls: newUrls,
            mainIndex: mainIndex,
            userId: userId,
          );
        } catch (saveError) {
          debugPrint('Error saving uploaded photos: $saveError');
        }
      }
      rethrow;
    } finally {
      isUploadingPhoto = false;
      _notify();
    }
  }

  Future<void> _saveGallery({
    required List<String> current,
    required List<String> newUrls,
    required int? mainIndex,
    required String userId,
  }) async {
    var photos = [
      ...current,
      ...newUrls.where((url) => !current.contains(url)),
    ];
    if (mainIndex != null && mainIndex >= 0 && mainIndex < newUrls.length) {
      final mainUrl = newUrls[mainIndex];
      photos = [mainUrl, ...photos.where((url) => url != mainUrl)];
    }
    photos = photos.take(Profile.maxPhotos).toList();
    if (photos.isEmpty) return;
    await updateProfile(
      profile!.copyWith(profileImage: photos.first, photos: photos),
      userId: userId,
    );
  }

  Future<void> setMainProfilePhoto(String url, {String? userId}) async {
    if (profile == null || url.isEmpty) return;
    final photos = profile!.galleryPhotos;
    if (!photos.contains(url) || photos.first == url) return;
    final reordered = [url, ...photos.where((item) => item != url)];
    await updateProfile(
      profile!.copyWith(profileImage: url, photos: reordered),
      userId: userId,
    );
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
