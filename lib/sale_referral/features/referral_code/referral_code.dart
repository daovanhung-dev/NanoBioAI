class ReferralCodeFeature {
  const ReferralCodeFeature._();

  static const status = 'implemented-internal-v1';
  static const productAxis = 'sale-referral';

  static const responsibilities = <String>[
    'Represent trusted referral code ownership for active Sale users.',
    'Support referral code attachment during account creation after DD approval.',
    'Prevent self-referral and duplicate referral relationships through backend rules.',
    'Keep referral data separate from membership package data.',
  ];

  static const blockedUntil =
      'Advanced fraud scoring and Admin manual reassign flow remain backend decisions.';
}
