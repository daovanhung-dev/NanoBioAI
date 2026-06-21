import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v2/features/membership_entitlement/membership_entitlement.dart';

void main() {
  group('membershipDisplayInfoForTier', () {
    test('maps known tiers to stable display codes and labels', () {
      expect(membershipDisplayInfoForTier('guest').code, 'guest');
      expect(membershipDisplayInfoForTier('guest').label, contains('Khách'));

      expect(membershipDisplayInfoForTier('free').code, 'free');
      expect(membershipDisplayInfoForTier('free').label, contains('Free'));

      expect(membershipDisplayInfoForTier('plus').code, 'plus');
      expect(membershipDisplayInfoForTier('plus').label, contains('Plus'));

      expect(membershipDisplayInfoForTier('family_plus').code, 'family_plus');
      expect(membershipDisplayInfoForTier('familyplus').code, 'family_plus');
      expect(
        membershipDisplayInfoForTier('family_plus').label,
        contains('FamilyPlus'),
      );
    });

    test('falls back to Free for blank local tier', () {
      expect(membershipDisplayInfoForTier(null).code, 'free');
      expect(membershipDisplayInfoForTier('').code, 'free');
    });
  });
}
