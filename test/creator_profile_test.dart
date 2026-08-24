import 'package:flutter_test/flutter_test.dart';
import 'package:bombay_casting/core/models/models.dart';
import 'package:bombay_casting/features/creators/models/creator_profile.dart';

void main() {
  test('round-trips saved creator snapshots', () {
    final original = CreatorProfile(
      id: 'creator-9',
      name: 'Asha',
      title: 'Actor',
      location: 'Mumbai, Maharashtra',
      photos: const [
        CreatorPhoto(url: 'https://example.com/a.jpg', imageIndex: 3),
      ],
      isVerified: true,
      aboutInfo: const [MapEntry('Gender', 'Female')],
      workInfo: const [MapEntry('Role', 'Actor')],
      platformMetrics: [
        SocialPlatformMetric(
          platform: 'Instagram',
          handle: '@asha',
          followers: 12000,
          url: 'https://instagram.com/asha',
        ),
      ],
    );
    final restored = CreatorProfile.fromJson(original.toJson());

    expect(restored.id, 'creator-9');
    expect(restored.name, 'Asha');
    expect(restored.title, 'Actor');
    expect(restored.location, 'Mumbai, Maharashtra');
    expect(restored.isVerified, isTrue);
    expect(restored.cover.url, 'https://example.com/a.jpg');
    expect(restored.cover.imageIndex, 3);
    expect(Map.fromEntries(restored.aboutInfo), {'Gender': 'Female'});
    expect(Map.fromEntries(restored.workInfo), {'Role': 'Actor'});
    expect(restored.platformMetrics.single.handle, '@asha');
    expect(restored.platformMetrics.single.followers, 12000);
  });

  test('keeps newest creators first by created_at', () {
    final older = CreatorProfile.fromJson({
      'id': 'older',
      'name': 'Older',
      'created_at': '2026-01-01T00:00:00.000Z',
    });
    final newer = CreatorProfile.fromJson({
      'id': 'newer',
      'name': 'Newer',
      'created_at': '2026-08-01T00:00:00.000Z',
    });
    final sorted = [older, newer]
      ..sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
    expect(sorted.first.id, 'newer');
  });

  test('round-trips bookmark time so newest saved stays first', () {
    final original = CreatorProfile.fromJson({
      'id': 'creator-9',
      'name': 'Asha',
      'title': 'Actor',
      'created_at': '2026-01-01T00:00:00.000Z',
      'saved_at': '2026-08-24T10:00:00.000Z',
    });
    final restored = CreatorProfile.fromJson(original.toJson());
    expect(restored.createdAt, DateTime.parse('2026-01-01T00:00:00.000Z'));
    expect(restored.savedAt, DateTime.parse('2026-08-24T10:00:00.000Z'));
  });
}
