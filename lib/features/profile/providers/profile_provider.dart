import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:bombay_casting/core/models/models.dart';
import 'package:bombay_casting/core/services/profile_cache_service.dart';
import 'package:bombay_casting/core/services/storage_service.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider({required this._onChange});

  final StorageService storageService = StorageService();
  final ProfileCacheService _cache = ProfileCacheService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final VoidCallback _onChange;

  Profile? profile;
  bool isUploadingPhoto = false;

  /// Whether the profile document is known to exist in Firestore.
  /// Drives create-vs-update behaviour in [updateProfile] so we never write
  /// eager empty placeholder docs at login.
  bool _remoteExists = false;

  void _notify() {
    notifyListeners();
    _onChange();
  }

  /// Sets an in-memory default profile for a brand new user WITHOUT writing to
  /// Firestore. The document is created lazily on the first real save via
  /// [updateProfile]. This keeps first login fast.
  void createLocalDefault({
    required String uid,
    String profileImage = '',
  }) {
    profile = Profile(userId: uid, profileImage: profileImage);
    _remoteExists = false;
    _notify();
  }

  Future<void> loadProfile(String uid) async {
    final cached = await _cache.read(uid);
    if (cached != null) {
      profile = cached.profile;
      _remoteExists = cached.remoteExists;
      _notify();
      if (!cached.isFresh) {
        unawaited(_fetchProfileFromServer(uid));
      }
      return;
    }

    profile = null;
    _remoteExists = false;
    _notify();
    await _fetchProfileFromServer(uid);
  }

  Future<void> _fetchProfileFromServer(String uid) async {
    try {
      final profileDoc = await _firestore.collection('profiles').doc(uid).get();
      if (profileDoc.exists) {
        final data = Map<String, dynamic>.from(profileDoc.data()!);
        data['user_id'] = uid;
        profile = Profile.fromJson(data);
        _remoteExists = true;
      } else {
        profile = Profile(userId: uid);
        _remoteExists = false;
      }
      if (profile != null) {
        await _cache.write(
          uid: uid,
          profile: profile!,
          remoteExists: _remoteExists,
        );
      }
    } catch (error) {
      debugPrint('Error loading profile: $error');
      profile = Profile(userId: uid);
      _remoteExists = false;
    }
    _notify();
  }

  Future<void> updateProfile(Profile updated, {String? userId}) async {
    profile = updated;
    _notify();
    if (userId == null) return;
    final ref = _firestore.collection('profiles').doc(userId);

    if (_remoteExists) {
      // Document already exists → merge only the mutable fields. The
      // subscription / verification / account fields are server-owned and must
      // never be touched here (the `update` security rule forbids them).
      final data = updated.toJson()
        ..remove('subscription_status')
        ..remove('is_verified')
        ..remove('account_status')
        ..remove('free_job_applications_used');
      await ref.set(data, SetOptions(merge: true));
    } else {
      // First write for this user → create a full, rules-valid document so it
      // satisfies the stricter `create` security rule. toJson() already carries
      // the required defaults (subscription_status 'free', is_verified false,
      // account_status 'active', free_job_applications_used 0).
      final data = updated.toJson()..['user_id'] = userId;
      await ref.set(data, SetOptions(merge: true));
      _remoteExists = true;
    }
    if (userId != null) {
      unawaited(
        _cache.write(
          uid: userId,
          profile: profile!,
          remoteExists: _remoteExists,
        ),
      );
    }
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
    final newThumbs = <String>[];
    try {
      final usedSlots = _usedGallerySlots(current);
      var slotCursor = 0;
      for (var i = 0; i < toUpload.length; i++) {
        while (usedSlots.contains(slotCursor) &&
            slotCursor < Profile.maxPhotos) {
          slotCursor += 1;
        }
        if (slotCursor >= Profile.maxPhotos) break;
        usedSlots.add(slotCursor);
        final upload = await storageService.uploadProfilePhoto(
          userId: userId,
          file: toUpload[i],
          slot: slotCursor,
        );
        newUrls.add(upload.fullUrl);
        newThumbs.add(upload.thumbUrl);
        slotCursor += 1;
      }
      await _saveGallery(
        current: current,
        currentThumbs: profile!.galleryThumbPhotos,
        newUrls: newUrls,
        newThumbUrls: newThumbs,
        mainIndex: mainIndex,
        userId: userId,
      );
    } catch (error) {
      debugPrint('Error uploading profile photo: $error');
      if (newUrls.isNotEmpty) {
        try {
          await _saveGallery(
            current: current,
            currentThumbs: profile!.galleryThumbPhotos,
            newUrls: newUrls,
            newThumbUrls: newThumbs,
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
    required List<String> currentThumbs,
    required List<String> newUrls,
    required List<String> newThumbUrls,
    required int? mainIndex,
    required String userId,
  }) async {
    final thumbsByUrl = <String, String>{};
    for (var i = 0; i < current.length; i++) {
      if (i < currentThumbs.length && currentThumbs[i].isNotEmpty) {
        thumbsByUrl[current[i]] = currentThumbs[i];
      }
    }
    for (var i = 0; i < newUrls.length; i++) {
      if (i < newThumbUrls.length && newThumbUrls[i].isNotEmpty) {
        thumbsByUrl[newUrls[i]] = newThumbUrls[i];
      }
    }

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

    final alignedThumbs = [
      for (final photo in photos) thumbsByUrl[photo] ?? '',
    ];

    await updateProfile(
      profile!.copyWith(
        profileImage: photos.first,
        photos: photos,
        photoThumbs: alignedThumbs,
      ),
      userId: userId,
    );
  }

  Set<int> _usedGallerySlots(List<String> photos) {
    final slots = <int>{};
    for (final url in photos) {
      final slot = StorageService.gallerySlotFromUrl(url);
      if (slot != null) slots.add(slot);
    }
    return slots;
  }

  Future<void> setMainProfilePhoto(String url, {String? userId}) async {
    if (profile == null || url.isEmpty) return;
    final photos = profile!.galleryPhotos;
    if (!photos.contains(url) || photos.first == url) return;
    final thumbs = profile!.galleryThumbPhotos;
    final thumbByUrl = {
      for (var i = 0; i < photos.length; i++)
        photos[i]: i < thumbs.length ? thumbs[i] : '',
    };
    final reordered = [url, ...photos.where((item) => item != url)];
    final reorderedThumbs = [
      for (final photo in reordered) thumbByUrl[photo] ?? '',
    ];
    await updateProfile(
      profile!.copyWith(
        profileImage: url,
        photos: reordered,
        photoThumbs: reorderedThumbs,
      ),
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
    final photos = profile!.galleryPhotos;
    final thumbs = profile!.galleryThumbPhotos;
    final remainingPhotos = photos.where((item) => item != url).toList();
    final remainingThumbs = <String>[];
    for (var i = 0; i < photos.length; i++) {
      if (photos[i] == url) continue;
      remainingThumbs.add(i < thumbs.length ? thumbs[i] : '');
    }
    await updateProfile(
      profile!.copyWith(
        profileImage: remainingPhotos.isEmpty ? '' : remainingPhotos.first,
        photos: remainingPhotos,
        photoThumbs: remainingThumbs,
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
    _remoteExists = false;
    unawaited(_cache.clear());
    _notify();
  }
}
