class V2PersonalScheduleQuotaFeature {
  const V2PersonalScheduleQuotaFeature._();

  static const status = 'planned';
  static const accessLayer = 'v2/free-authenticated';

  static const responsibilities = <String>[
    'Guard personal schedule regeneration for authenticated Free users.',
    'Allow at most 3 schedule generations per month for Free accounts.',
    'Route blocked generation attempts to a Nabi-style upgrade or wait message.',
    'Reuse v1 schedule storage and notification contracts through repositories.',
  ];

  static const blockedUntil =
      'Schedule quota DD defines monthly period, ownership, and migration rules.';
}
