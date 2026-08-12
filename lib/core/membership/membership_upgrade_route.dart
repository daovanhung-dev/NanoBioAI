const membershipPaymentRoutePath = '/v2/payments';

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
