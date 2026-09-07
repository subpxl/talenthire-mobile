import 'package:bombay_casting/core/models/models.dart';
import 'package:bombay_casting/core/utils/input_validators.dart';
import 'package:bombay_casting/features/jobs/utils/video_link_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InputValidators', () {
    test('rejects emails that only contain @', () {
      expect(InputValidators.isValidEmail('not-an-email'), isFalse);
      expect(InputValidators.isValidEmail('a@b'), isFalse);
      expect(InputValidators.emailError('user@'), isNotNull);
      expect(InputValidators.isValidEmail('user@example.com'), isTrue);
      expect(InputValidators.emailError('user@example.com'), isNull);
    });

    test('requires a name', () {
      expect(InputValidators.nameError(''), isNotNull);
      expect(InputValidators.nameError('   '), isNotNull);
      expect(InputValidators.nameError('Asha'), isNull);
    });

    test('validates Indian PAN format', () {
      expect(InputValidators.panError(''), isNull);
      expect(InputValidators.panError('ABCDE1234F'), isNull);
      expect(InputValidators.panError('abcde1234f'), isNull);
      expect(InputValidators.panError('ABCDE123'), isNotNull);
      expect(InputValidators.panError('12345ABCDE'), isNotNull);
    });
  });

  group('VideoLinkUtils', () {
    test('accepts YouTube and Instagram hosts', () {
      expect(
        VideoLinkUtils.isYouTubeOrInstagram(
          'https://www.youtube.com/shorts/eUatFTYYlkc',
        ),
        isTrue,
      );
      expect(
        VideoLinkUtils.isYouTubeOrInstagram('youtu.be/eUatFTYYlkc'),
        isTrue,
      );
      expect(
        VideoLinkUtils.isYouTubeOrInstagram(
          'https://www.instagram.com/reel/abc123/',
        ),
        isTrue,
      );
      expect(
        VideoLinkUtils.introVideoError('https://drive.google.com/file/d/x'),
        isNotNull,
      );
      expect(VideoLinkUtils.introVideoError(''), isNull);
    });
  });

  group('Profile.completionPercentage', () {
    test('stays below 100 without verification or intro video', () {
      final profile = Profile(
        userId: 'u1',
        profileImage: 'https://cdn.example/photo.jpg',
        bio: 'About me',
        contact: '@asha',
        city: 'Mumbai',
        gender: 'Female',
        age: 24,
        languages: const ['Hindi'],
        niches: const ['Beauty'],
        formData: const {
          'creator': {
            'collab_types': ['Paid'],
            'platforms': ['Instagram'],
          },
        },
      );

      expect(profile.completionPercentage, lessThan(100));
      expect(profile.completionPercentage, 80);
    });

    test('reaches 100 with verification docs and intro video', () {
      final profile = Profile(
        userId: 'u1',
        profileImage: 'https://cdn.example/photo.jpg',
        bio: 'About me',
        contact: '@asha',
        city: 'Mumbai',
        gender: 'Female',
        age: 24,
        languages: const ['Hindi'],
        niches: const ['Beauty'],
        formData: const {
          'creator': {
            'collab_types': ['Paid'],
            'platforms': ['Instagram'],
          },
          'verification': {
            'pan_number': 'ABCDE1234F',
            'pan_card': 'https://cdn.example/pan.jpg',
          },
          'videos': {
            'introduction_link': 'https://youtube.com/shorts/abc',
          },
        },
      );

      expect(profile.completionPercentage, 100);
    });
  });
}
