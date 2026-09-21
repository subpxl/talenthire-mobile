import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;
import 'package:bombay_casting/core/services/image_resize_service.dart';
import 'package:bombay_casting/core/services/storage_urls.dart';

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
  StorageService({FirebaseFunctions? functions})
      : _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'asia-south1');

  final FirebaseFunctions _functions;

  static const galleryPrefix = 'gallery_';
  static const galleryExtension = '.jpg';
  static const _jpegContentType = 'image/jpeg';

  static String galleryFileName(int slot) =>
      '$galleryPrefix$slot$galleryExtension';

  static String galleryThumbFileName(int slot) =>
      'thumbs/$galleryPrefix$slot$galleryExtension';

  /// Parses `gallery_N.jpg` from a storage URL, if present.
  static int? gallerySlotFromUrl(String url) {
    final key = StorageUrls.objectPathFromUrl(url);
    if (key == null) return null;
    final name = key.split('/').last;
    if (!name.startsWith(galleryPrefix) || !name.endsWith(galleryExtension)) {
      return null;
    }
    return int.tryParse(
      name.substring(galleryPrefix.length, name.length - galleryExtension.length),
    );
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
    final bytes = await file.readAsBytes();
    return uploadBytes(
      userId: userId,
      bytes: bytes,
      folder: folder,
      fileName: fileName ?? '${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
  }

  Future<String> uploadBytes({
    required String userId,
    required Uint8List bytes,
    required String folder,
    required String fileName,
  }) async {
    final objectPath = _objectPath(
      userId: userId,
      folder: folder,
      fileName: fileName,
    );
    return _uploadObject(
      objectPath: objectPath,
      bytes: bytes,
      contentType: _jpegContentType,
    );
  }

  Future<void> deleteProfilePhoto(String url) async {
    if (!StorageUrls.isStorageUrl(url)) return;
    final path = StorageUrls.objectPathFromUrl(url);
    if (path == null) return;

    await _deleteObject(path);

    final slot = gallerySlotFromUrl(url);
    if (slot == null) return;
    try {
      final thumbPath = path.replaceFirst('/profile/', '/profile/thumbs/');
      if (thumbPath != path) {
        await _deleteObject(thumbPath);
      }
    } catch (_) {}
  }

  String _objectPath({
    required String userId,
    required String folder,
    required String fileName,
  }) {
    final segments = <String>['users', userId];
    for (final segment in folder.split('/')) {
      if (segment.isNotEmpty) segments.add(segment);
    }
    segments.add(fileName);
    return segments.join('/');
  }

  Future<String> _uploadObject({
    required String objectPath,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final callable = _functions.httpsCallable('getStorageUploadUrl');
    final result = await callable.call({
      'objectPath': objectPath,
      'contentType': contentType,
      'contentLength': bytes.length,
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    final uploadUrl = data['uploadUrl'] as String?;
    final publicUrl = data['publicUrl'] as String?;
    final fallbackUploadUrl = data['fallbackUploadUrl'] as String?;
    final fallbackPublicUrl = data['fallbackPublicUrl'] as String?;

    if (uploadUrl == null || uploadUrl.isEmpty || publicUrl == null) {
      throw StateError('Upload URL was not returned by the server.');
    }

    try {
      final response = await http.put(
        Uri.parse(uploadUrl),
        headers: {
          'Content-Type': contentType,
          'x-amz-acl': 'public-read',
        },
        body: bytes,
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return publicUrl;
      }
    } catch (_) {
      // Ignored, attempt fallback below if available
    }

    if (fallbackUploadUrl != null && fallbackUploadUrl.isNotEmpty && fallbackPublicUrl != null) {
      final response = await http.put(
        Uri.parse(fallbackUploadUrl),
        headers: {
          'Content-Type': contentType,
        },
        body: bytes,
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return fallbackPublicUrl;
      }
      throw StateError(
        'Upload failed on fallback (${response.statusCode}): ${response.body}',
      );
    }

    throw StateError('Upload failed and no fallback was available.');
  }

  Future<void> _deleteObject(String objectPath) async {
    final callable = _functions.httpsCallable('deleteStorageObject');
    await callable.call({'objectPath': objectPath});
  }
}
