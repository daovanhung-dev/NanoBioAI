import 'package:nano_app/app_versions/v2/features/membership_entitlement/domain/entities/effective_access.dart';
import 'package:nano_app/shared/health_features/health_feature_catalog.dart';

enum HealthModuleAccessDestination {
  loginRequired,
  comingSoon,
  upgradeRequired,
  unavailable,
}

class HealthModuleAccessResolver {
  const HealthModuleAccessResolver._();

  static HealthModuleAccessDestination resolve({
    required HealthFeatureCatalogItem item,
    required EffectiveAccess? access,
  }) {
    if (access == null) {
      return HealthModuleAccessDestination.unavailable;
    }

    if (access.isAnonymous || access.isGuest) {
      return HealthModuleAccessDestination.loginRequired;
    }

    if (access.userId.trim().isEmpty) {
      return HealthModuleAccessDestination.unavailable;
    }

    if (access.hasPaidAccess) {
      return HealthModuleAccessDestination.comingSoon;
    }

    if (!access.isFree) {
      return HealthModuleAccessDestination.unavailable;
    }

    return item.minimumAccess == HealthFeatureMinimumAccess.free
        ? HealthModuleAccessDestination.comingSoon
        : HealthModuleAccessDestination.upgradeRequired;
  }
}
