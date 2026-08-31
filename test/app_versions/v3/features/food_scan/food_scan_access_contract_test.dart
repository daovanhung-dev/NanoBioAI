import 'dart:io';

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

  test('Food Scan paid contract includes Plus and FamilyPlus', () {
    final plus = access('plus');
    final familyPlus = access('family_plus');

    expect(plus.isPlus, isTrue);
    expect(familyPlus.hasPaidAccess, isTrue);
    expect(familyPlus.isPlus, isFalse);
  });

  test('Food Scan app gate uses the shared paid-access contract', () {
    final source = File(
      'lib/app_versions/v3/features/food_scan/providers/food_scan_providers.dart',
    ).readAsStringSync();

    expect(source, contains('!access.hasPaidAccess'));
    expect(source, isNot(contains('!access.isPlus')));
  });
}
