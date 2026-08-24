import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v2/features/membership_entitlement/domain/entities/effective_access.dart';

void main() {
  EffectiveAccess access(String plan) => EffectiveAccess(
    userId: 'user-1',
    isAnonymous: false,
    productAccess: plan == 'free' ? 'free' : plan,
    membershipPlan: plan,
    saleStatus: 'none',
    onboardingStatus: 'completed',
  );

  test('Food Scan PLUS contract must use isPlus, not hasPaidAccess', () {
    final plus = access('plus');
    final familyPlus = access('family_plus');

    expect(plus.isPlus, isTrue);
    expect(familyPlus.hasPaidAccess, isTrue);
    expect(familyPlus.isPlus, isFalse);
  });
}
