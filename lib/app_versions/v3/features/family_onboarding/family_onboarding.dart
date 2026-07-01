class V3FamilyOnboardingFeature {
  const V3FamilyOnboardingFeature._();

  static const status = 'implemented';
  static const accessLayer = 'v3/familyplus';

  static const responsibilities = <String>[
    'Collect FamilyPlus household setup data after trusted membership confirmation.',
    'Separate family onboarding from the v1 single-user guest onboarding flow.',
    'Prepare consent and privacy gates before cross-member health access.',
    'Coordinate with FamilyPlus group and member repository contracts.',
  ];

  static const runtimeRoute = '/v3/familyplus';
}
