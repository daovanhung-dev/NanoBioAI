class SalePaymentEventsFeature {
  const SalePaymentEventsFeature._();

  static const status = 'planned';
  static const productAxis = 'sale-referral';

  static const responsibilities = <String>[
    'Receive package payment success from a trusted backend or webhook source.',
    'Avoid trusting Flutter client flags for payment or renewal success.',
    'Provide auditable inputs for commission creation after DD approval.',
    'Keep payment secrets and service-role credentials outside the app.',
  ];

  static const blockedUntil =
      'Payment event DD defines gateway, webhook, reconciliation, and security.';
}
