class V2HealthScoringFeature {
  const V2HealthScoringFeature._();

  static const status = 'planned';
  static const accessLayer = 'v2/free-authenticated';

  static const responsibilities = <String>[
    'Calculate health score from real schedule completion history.',
    'Read meal, daily task, and lifestyle schedule progress through data layer.',
    'Avoid mock, fake, or sample dashboard data in production.',
    'Keep the v1 local daily care score separate from the official v2 health scoring formula.',
    'Prepare a clear contract for Plus and FamilyPlus scoring extensions.',
  ];

  static const blockedUntil =
      'Q-05 closes the official formula, weights, skip/miss handling, UI score policy, and tests.';
}
