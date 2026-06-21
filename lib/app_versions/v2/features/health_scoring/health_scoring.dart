class V2HealthScoringFeature {
  const V2HealthScoringFeature._();

  static const status = 'planned';
  static const accessLayer = 'v2/free-authenticated';

  static const responsibilities = <String>[
    'Calculate health score from real schedule completion history.',
    'Read meal, daily task, and lifestyle schedule progress through data layer.',
    'Avoid mock, fake, or sample dashboard data in production.',
    'Prepare a clear contract for Plus and FamilyPlus scoring extensions.',
  ];

  static const blockedUntil =
      'Health scoring DD defines formula, weights, history windows, and tests.';
}
