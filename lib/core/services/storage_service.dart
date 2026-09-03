import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  StorageService();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadProfilePhoto({
    required String userId,
    required File file,
    String? fileName,
  }) async {
    return uploadDocument(
      userId: userId,
      file: file,
      folder: 'profile',
      fileName: fileName,
    );
  }

  Future<String> uploadDocument({
    required String userId,
    required File file,
    required String folder,
    String? fileName,
  }) async {
    final ref = _storage
        .ref()
        .child('users')
        .child(userId)
        .child(folder)
        .child(fileName ?? '${DateTime.now().microsecondsSinceEpoch}.jpg');
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Future<void> deleteProfilePhoto(String url) async {
    if (url.isEmpty || !url.contains('firebasestorage')) return;
    await _storage.refFromURL(url).delete();
  }
}
