import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Client-side JPEG thumbnails before Firebase Storage upload.
class ImageResizeService {
  ImageResizeService._();

  static const thumbnailMaxSide = 300;
  static const uploadMaxSide = 1920;
  static const jpegQuality = 72;
  static const uploadJpegQuality = 85;

  /// JPEG bytes for profile upload (resize + re-encode for size and compatibility).
  static Future<Uint8List> createUploadBytes(File file) async {
    final raw = await file.readAsBytes();
    final encoded = await compute(
      _encodeUpload,
      _ThumbnailRequest(bytes: raw, maxSide: uploadMaxSide),
    );
    if (encoded != null && encoded.isNotEmpty) return encoded;
    return raw;
  }

  static Future<Uint8List?> createThumbnailBytes(
    File file, {
    int maxSide = thumbnailMaxSide,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      return await compute(
        _encodeThumbnail,
        _ThumbnailRequest(bytes: bytes, maxSide: maxSide),
      );
    } catch (error) {
      debugPrint('Thumbnail encode failed: $error');
      return null;
    }
  }

  static Uint8List? _encodeThumbnail(_ThumbnailRequest request) {
    return _encodeJpeg(request, jpegQuality);
  }

  static Uint8List? _encodeUpload(_ThumbnailRequest request) {
    return _encodeJpeg(request, uploadJpegQuality);
  }

  static Uint8List? _encodeJpeg(_ThumbnailRequest request, int quality) {
    final decoded = img.decodeImage(request.bytes);
    if (decoded == null) return null;
    final resized = img.copyResize(
      decoded,
      width: decoded.width >= decoded.height ? request.maxSide : null,
      height: decoded.height > decoded.width ? request.maxSide : null,
    );
    return Uint8List.fromList(img.encodeJpg(resized, quality: quality));
  }
}

class _ThumbnailRequest {
  const _ThumbnailRequest({required this.bytes, required this.maxSide});

  final Uint8List bytes;
  final int maxSide;
}
