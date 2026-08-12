import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all current paid-access gates route through the canonical upgrade flow', () {
    final expectations = <String, List<String>>{
      'lib/app_versions/v1/features/ai_chat/presentation/pages/ai_chat_screen.dart': [
        'openMembershipUpgrade(',
        'MembershipUpgradePlan.plus',
        'Nâng cấp Plus',
      ],
      'lib/app_versions/v1/features/dashboard/presentation/pages/dashboard_page.dart': [
        'showMembershipUpgradePrompt(',
        'MembershipUpgradePlan.plus',
      ],
      'lib/app_versions/v2/features/health_modules/presentation/pages/health_module_access_page.dart': [
        'buildMembershipUpgradeRoute(',
        'MembershipUpgradePlan.plus',
      ],
      'lib/app_versions/v3/features/advanced_tracking/presentation/pages/advanced_tracking_page.dart': [
        'openMembershipUpgrade(',
        'MembershipUpgradePlan.plus',
      ],
      'lib/app_versions/v3/features/familyplus/presentation/pages/familyplus_page.dart': [
        'openMembershipUpgrade(',
        'MembershipUpgradePlan.familyPlus',
      ],
    };

    for (final entry in expectations.entries) {
      final source = File(entry.key).readAsStringSync();
      for (final token in entry.value) {
        expect(source, contains(token), reason: '${entry.key}: $token');
      }
      expect(
        source.toLowerCase(),
        isNot(contains('plan=vip')),
        reason: '${entry.key} must not introduce a VIP package code.',
      );
    }
  });

  test('V2 and V3 payment routes share the canonical plan normalizer', () {
    final v2 = File(
      'lib/app_versions/v2/router/v2_router.dart',
    ).readAsStringSync();
    final v3 = File(
      'lib/app_versions/v3/router/v3_router.dart',
    ).readAsStringSync();

    expect(v2, contains('normalizeMembershipUpgradePlan('));
    expect(v3, contains('normalizeMembershipUpgradePlan('));
    expect(v2, isNot(contains('_membershipPaymentPlanFromQuery')));
  });
}
