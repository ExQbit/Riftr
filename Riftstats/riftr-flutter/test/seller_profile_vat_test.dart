import 'package:flutter_test/flutter_test.dart';
import 'package:riftr_flutter/models/market/seller_profile.dart';

void main() {
  group('SellerProfile.validateVatId', () {
    test('rejects null and empty', () {
      expect(SellerProfile.validateVatId(null), isNotNull);
      expect(SellerProfile.validateVatId(''), isNotNull);
      expect(SellerProfile.validateVatId('  '), isNotNull);
    });

    test('accepts valid German VAT ID', () {
      expect(SellerProfile.validateVatId('DE123456789'), isNull);
      expect(SellerProfile.validateVatId('de123456789'), isNull);
      expect(SellerProfile.validateVatId('DE 123 456 789'), isNull);
    });

    test('rejects German VAT ID with wrong length', () {
      expect(SellerProfile.validateVatId('DE12345678'), isNotNull);
      expect(SellerProfile.validateVatId('DE1234567890'), isNotNull);
    });

    test('rejects German VAT ID with letters in the digit part', () {
      expect(SellerProfile.validateVatId('DE12345678X'), isNotNull);
    });

    test('accepts valid Austrian VAT ID', () {
      expect(SellerProfile.validateVatId('ATU12345678'), isNull);
      expect(SellerProfile.validateVatId('AT U12345678'), isNull);
    });

    test('rejects Austrian VAT ID without leading U', () {
      expect(SellerProfile.validateVatId('AT12345678'), isNotNull);
    });

    test('accepts other EU country codes generically', () {
      // Accepts as long as it starts with 2 letters and contains only
      // alphanumerics within the 8-14 char range. Country-specific
      // shortcuts only enforced for DE+AT.
      expect(SellerProfile.validateVatId('FR12345678901'), isNull);
      expect(SellerProfile.validateVatId('NL123456789B01'), isNull);
    });

    test('rejects too-short or too-long input', () {
      expect(SellerProfile.validateVatId('DE1234'), isNotNull);
      expect(SellerProfile.validateVatId('DE12345678901234'), isNotNull);
    });

    test('rejects input that does not start with 2 letters', () {
      expect(SellerProfile.validateVatId('1234567890'), isNotNull);
      expect(SellerProfile.validateVatId('1DE12345678'), isNotNull);
    });
  });

  group('SellerProfile.canonicalVatId', () {
    test('returns null for empty', () {
      expect(SellerProfile.canonicalVatId(null), isNull);
      expect(SellerProfile.canonicalVatId(''), isNull);
      expect(SellerProfile.canonicalVatId('   '), isNull);
    });

    test('strips whitespace and uppercases', () {
      expect(SellerProfile.canonicalVatId('de 123 456 789'),
          equals('DE123456789'));
      expect(SellerProfile.canonicalVatId('  AT u12345678  '),
          equals('ATU12345678'));
    });
  });
}
