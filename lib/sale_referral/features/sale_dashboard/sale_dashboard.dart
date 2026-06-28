class SaleDashboardFeature {
  const SaleDashboardFeature._();

  static const status = 'implemented-internal-v1';
  static const productAxis = 'sale-referral';

  static const responsibilities = <String>[
    'Show Sale status, referral overview, and commission summaries.',
    'Read Sale data only from trusted repository or backend contracts.',
    'Avoid exposing internal terms such as commission tree in end-user copy.',
    'Keep dashboard access separate from Free, Plus, and FamilyPlus membership.',
  ];

  static const blockedUntil =
      'Production payout/provider verification remains outside Flutter.';
}
