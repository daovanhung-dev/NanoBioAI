const membershipPaymentRoutePath = '/v2/payments';

const membershipTransferReferencePattern = r'^NB[0-9A-F]{12}$';

final RegExp _membershipTransferReferenceRegExp = RegExp(
  membershipTransferReferencePattern,
);

abstract final class MembershipUpgradePlan {
  static const plus = 'plus';
  static const familyPlus = 'family_plus';

  const MembershipUpgradePlan._();
}

String normalizeMembershipUpgradePlan(String? planCode) {
  final normalized = planCode?.trim().toLowerCase();
  return normalized == MembershipUpgradePlan.familyPlus
      ? MembershipUpgradePlan.familyPlus
      : MembershipUpgradePlan.plus;
}

String? normalizeMembershipTransferReference(String? value) {
  final normalized = value?.trim().toUpperCase();
  if (normalized == null || normalized.isEmpty) return null;
  return _membershipTransferReferenceRegExp.hasMatch(normalized)
      ? normalized
      : null;
}

String membershipUpgradeActionLabel(String? planCode) {
  return normalizeMembershipUpgradePlan(planCode) ==
          MembershipUpgradePlan.familyPlus
      ? 'Nâng cấp FamilyPlus'
      : 'Nâng cấp Plus';
}

String buildMembershipUpgradeRoute(String? planCode) {
  return Uri(
    path: membershipPaymentRoutePath,
    queryParameters: {'plan': normalizeMembershipUpgradePlan(planCode)},
  ).toString();
}
