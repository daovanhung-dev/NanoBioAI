class SaleCommissionFeature {
  const SaleCommissionFeature._();

  static const status = 'planned';
  static const productAxis = 'sale-referral';

  static const responsibilities = <String>[
    'Represent direct 10% and second-level 5% commission records.',
    'Cap commission depth at two levels from the paying user.',
    'Create commission only from trusted successful payment events.',
    'Keep payout and accounting workflows out of Flutter client code.',
  ];

  static const blockedUntil =
      'Commission DD defines payment event source, adjustments, payout, and tests.';
}
