import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:bombay_casting/core/services/image_resize_service.dart';

class ProfilePhotoUpload {
  const ProfilePhotoUpload({
    required this.fullUrl,
    required this.thumbUrl,
    required this.slot,
  });

  final String fullUrl;
  final String thumbUrl;
  final int slot;
}

class StorageService {
  StorageService();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  static const galleryPrefix = 'gallery_';
  static const galleryExtension = '.jpg';

  static String galleryFileName(int slot) =>
      '$galleryPrefix$slot$galleryExtension';

  static String galleryThumbFileName(int slot) =>
      'thumbs/$galleryPrefix$slot$galleryExtension';

  /// Parses `gallery_N.jpg` from a Firebase download URL, if present.
  static int? gallerySlotFromUrl(String url) {
    final key = _objectPathFromDownloadUrl(url);
    if (key == null) return null;
    final name = key.split('/').last;
    if (!name.startsWith(galleryPrefix) || !name.endsWith(galleryExtension)) {
      return null;
    }
    return int.tryParse(
      name.substring(galleryPrefix.length, name.length - galleryExtension.length),
    );
  }

  static String? _objectPathFromDownloadUrl(String url) {
    if (!url.contains('firebasestorage.googleapis.com')) return null;
    const marker = '/o/';
    final start = url.indexOf(marker);
    if (start == -1) return null;
    var encoded = url.substring(start + marker.length);
    final query = encoded.indexOf('?');
    if (query != -1) encoded = encoded.substring(0, query);
    final decoded = Uri.decodeComponent(encoded);
    return decoded.isEmpty ? null : decoded;
  }

  Future<ProfilePhotoUpload> uploadProfilePhoto({
    required String userId,
    required File file,
    required int slot,
  }) async {
    final fileName = galleryFileName(slot);
    final fullUrl = await uploadDocument(
      userId: userId,
      file: file,
      folder: 'profile',
      fileName: fileName,
    );

    var thumbUrl = fullUrl;
    final thumbBytes = await ImageResizeService.createThumbnailBytes(file);
    if (thumbBytes != null) {
      thumbUrl = await uploadBytes(
        userId: userId,
        bytes: thumbBytes,
        folder: 'profile/thumbs',
        fileName: galleryFileName(slot),
      );
    }

    return ProfilePhotoUpload(
      fullUrl: fullUrl,
      thumbUrl: thumbUrl,
      slot: slot,
    );
  }

  Future<String> uploadDocument({
    required String userId,
    required File file,
    required String folder,
    String? fileName,
  }) async {
    final ref = _storageRef(
      userId: userId,
      folder: folder,
      fileName: fileName ?? '${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Future<String> uploadBytes({
    required String userId,
    required Uint8List bytes,
    required String folder,
    required String fileName,
  }) async {
    final ref = _storageRef(
      userId: userId,
      folder: folder,
      fileName: fileName,
    );
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Reference _storageRef({
    required String userId,
    required String folder,
    required String fileName,
  }) {
    Reference ref = _storage.ref().child('users').child(userId);
    for (final segment in folder.split('/')) {
      if (segment.isNotEmpty) ref = ref.child(segment);
    }
    return ref.child(fileName);
  }

  Future<void> deleteProfilePhoto(String url) async {
    if (url.isEmpty || !url.contains('firebasestorage')) return;
    await _storage.refFromURL(url).delete();
    final slot = gallerySlotFromUrl(url);
    if (slot == null) return;
    try {
      final path = _objectPathFromDownloadUrl(url);
      if (path == null) return;
      final thumbPath = path.replaceFirst(
        '/profile/',
        '/profile/thumbs/',
      );
      if (thumbPath != path) {
        await _storage.ref(thumbPath).delete();
      }
    } catch (_) {}
  }
}
