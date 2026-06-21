class V2UsageQuotaFeature {
  const V2UsageQuotaFeature._();

  static const status = 'planned';
  static const accessLayer = 'v2/free-authenticated';

  static const responsibilities = <String>[
    'Track Free AI chat usage with a daily limit of 3 questions.',
    'Track Free personal schedule generation with a monthly limit of 3 runs.',
    'Block quota-limited use cases before calling AI services.',
    'Keep quota reads and writes behind repository or service contracts.',
  ];

  static const blockedUntil =
      'Usage quota DD defines periods, reset timezone, trusted storage, and tests.';
}
