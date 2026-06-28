class SaleCommissionFeature {
  const SaleCommissionFeature._();

  static const status = 'implemented-internal-v1';
  static const productAxis = 'sale-referral';

  static const responsibilities = <String>[
    'Represent direct 10% commission records.',
    'Keep commission depth to the direct referred customer only.',
    'Create commission only from trusted successful payment events.',
    'Keep payout and accounting workflows out of Flutter client code.',
  ];

  static const blockedUntil =
      'External payout, tax and bank transfer policy remain out of Flutter scope.';
}
