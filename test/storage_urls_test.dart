import 'package:flutter_test/flutter_test.dart';
import 'package:bombay_casting/core/services/storage_urls.dart';

void main() {
  test('parses DigitalOcean CDN URLs', () {
    const url =
        'https://talenthire-media.sgp1.cdn.digitaloceanspaces.com/users/u1/profile/gallery_0.jpg';
    expect(StorageUrls.isStorageUrl(url), isTrue);
    expect(
      StorageUrls.objectPathFromUrl(url),
      'users/u1/profile/gallery_0.jpg',
    );
  });

  test('parses legacy Firebase Storage URLs', () {
    const url =
        'https://firebasestorage.googleapis.com/v0/b/talenthire-d86a1.firebasestorage.app/o/users%2Fu1%2Fprofile%2Fgallery_1.jpg?alt=media&token=abc';
    expect(StorageUrls.isStorageUrl(url), isTrue);
    expect(
      StorageUrls.objectPathFromUrl(url),
      'users/u1/profile/gallery_1.jpg',
    );
  });
}
