import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v2/features/health_modules/health_modules.dart';
import 'package:nano_app/app_versions/v2/features/membership_entitlement/membership_entitlement.dart';
import 'package:nano_app/shared/health_features/health_feature_catalog.dart';

void main() {
  final freeModule = healthFeatureByModuleId('M20')!;
  final plusModule = healthFeatureByModuleId('M23')!;

  group('HealthModuleAccessResolver', () {
    test('requires login for guest and anonymous access', () {
      for (final access in [
        _access(productAccess: 'guest', membershipPlan: 'free'),
        _access(isAnonymous: true, membershipPlan: 'free'),
      ]) {
        expect(
          HealthModuleAccessResolver.resolve(item: freeModule, access: access),
          HealthModuleAccessDestination.loginRequired,
        );
      }
    });

    test('allows Free to open M20-M22 placeholders', () {
      for (final moduleId in ['M20', 'M21', 'M22']) {
        expect(
          HealthModuleAccessResolver.resolve(
            item: healthFeatureByModuleId(moduleId)!,
            access: _access(membershipPlan: 'free'),
          ),
          HealthModuleAccessDestination.comingSoon,
        );
      }
    });

    test('sends Free to upgrade for M23-M29', () {
      for (final item in advancedHealthFeatureCatalog.where(
        (item) => item.minimumAccess == HealthFeatureMinimumAccess.plus,
      )) {
        expect(
          HealthModuleAccessResolver.resolve(
            item: item,
            access: _access(membershipPlan: 'free'),
          ),
          HealthModuleAccessDestination.upgradeRequired,
        );
      }
    });

    test('allows Plus and FamilyPlus to open every placeholder', () {
      for (final plan in ['plus', 'family_plus']) {
        for (final item in advancedHealthFeatureCatalog) {
          expect(
            HealthModuleAccessResolver.resolve(
              item: item,
              access: _access(membershipPlan: plan),
            ),
            HealthModuleAccessDestination.comingSoon,
          );
        }
      }
    });

    test('fails closed for missing, malformed, or unknown access', () {
      expect(
        HealthModuleAccessResolver.resolve(item: plusModule, access: null),
        HealthModuleAccessDestination.unavailable,
      );
      expect(
        HealthModuleAccessResolver.resolve(
          item: plusModule,
          access: _access(userId: '', membershipPlan: 'plus'),
        ),
        HealthModuleAccessDestination.unavailable,
      );
      expect(
        HealthModuleAccessResolver.resolve(
          item: plusModule,
          access: _access(membershipPlan: 'unknown'),
        ),
        HealthModuleAccessDestination.unavailable,
      );
      expect(
        HealthModuleAccessResolver.resolve(
          item: freeModule,
          access: EffectiveAccess.fromMap(const {
            'user_id': 'user-1',
            'product_access': 'member',
          }),
        ),
        HealthModuleAccessDestination.unavailable,
      );
    });
  });
}

EffectiveAccess _access({
  String userId = 'user-1',
  bool isAnonymous = false,
  String productAccess = 'member',
  required String membershipPlan,
}) {
  return EffectiveAccess(
    userId: userId,
    isAnonymous: isAnonymous,
    productAccess: productAccess,
    membershipPlan: membershipPlan,
    saleStatus: 'none',
    onboardingStatus: 'completed',
  );
}
