class ReferralCodeFeature {
  const ReferralCodeFeature._();

  static const status = 'planned';
  static const productAxis = 'sale-referral';

  static const responsibilities = <String>[
    'Represent trusted referral code ownership for active Sale users.',
    'Support referral code attachment during account creation after DD approval.',
    'Prevent self-referral and duplicate referral relationships through backend rules.',
    'Keep referral data separate from membership package data.',
  ];

  static const blockedUntil =
      'Referral code DD defines generation, attachment, fraud checks, and tests.';
}
