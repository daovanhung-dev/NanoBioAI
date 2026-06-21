class V3FamilyOnboardingFeature {
  const V3FamilyOnboardingFeature._();

  static const status = 'planned';
  static const accessLayer = 'v3/family-plus';

  static const responsibilities = <String>[
    'Collect FamilyPlus household setup data after trusted membership confirmation.',
    'Separate family onboarding from the v1 single-user guest onboarding flow.',
    'Prepare consent and privacy gates before cross-member health access.',
    'Coordinate with family member repositories once DD is approved.',
  ];

  static const blockedUntil =
      'Family onboarding DD defines consent, member limits, and privacy rules.';
}
