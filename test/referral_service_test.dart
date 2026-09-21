import 'package:bombay_casting/core/services/referral_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReferralService.parseReferralCode', () {
    test('returns null for empty input', () {
      expect(ReferralService.parseReferralCode(null), isNull);
      expect(ReferralService.parseReferralCode(''), isNull);
      expect(ReferralService.parseReferralCode('   '), isNull);
    });

    test('parses plain ref_code query param', () {
      expect(
        ReferralService.parseReferralCode('ref_code=ABC123'),
        'ABC123',
      );
    });

    test('parses encoded ref_code query param', () {
      expect(
        ReferralService.parseReferralCode('ref_code%3DXYZ789'),
        'XYZ789',
      );
    });

    test('parses ref_code among other params', () {
      expect(
        ReferralService.parseReferralCode(
          'utm_source=share&ref_code=AFF6&utm_medium=link',
        ),
        'AFF6',
      );
    });

    test('returns null when ref_code is missing', () {
      expect(
        ReferralService.parseReferralCode('utm_source=share&utm_medium=link'),
        isNull,
      );
    });
  });
}
