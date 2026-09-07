import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Client-side JPEG thumbnails before Firebase Storage upload.
class ImageResizeService {
  ImageResizeService._();

  static const thumbnailMaxSide = 400;
  static const jpegQuality = 85;

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
    final decoded = img.decodeImage(request.bytes);
    if (decoded == null) return null;
    final resized = img.copyResize(
      decoded,
      width: decoded.width >= decoded.height ? request.maxSide : null,
      height: decoded.height > decoded.width ? request.maxSide : null,
    );
    return Uint8List.fromList(
      img.encodeJpg(resized, quality: jpegQuality),
    );
  }
}

class _ThumbnailRequest {
  const _ThumbnailRequest({required this.bytes, required this.maxSide});

  final Uint8List bytes;
  final int maxSide;
}
