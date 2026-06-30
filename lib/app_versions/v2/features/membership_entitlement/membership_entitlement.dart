export 'domain/entities/effective_access.dart';
export 'domain/repositories/effective_access_repository.dart';
export 'providers/membership_entitlement_providers.dart';

class V2MembershipEntitlementFeature {
  const V2MembershipEntitlementFeature._();

  static const status = 'runtime_contract';
  static const accessLayer = 'v2/free-authenticated';

  static const responsibilities = <String>[
    'Read effective access from trusted Supabase membership state.',
    'Keep package decisions separate from local route or UI state.',
    'Expose Plus and FamilyPlus access as read-only app state.',
  ];
}
