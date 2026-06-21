class V3GoalRoadmapFeature {
  const V3GoalRoadmapFeature._();

  static const status = 'planned';
  static const accessLayer = 'v3/plus-family-plus';

  static const responsibilities = <String>[
    'Create personal roadmap experiences from user goals and health history.',
    'Keep roadmap data separated from the v1 guest onboarding draft.',
    'Read and write through repositories instead of presentation shortcuts.',
    'Expose a future extension point for FamilyPlus member roadmaps.',
  ];

  static const blockedUntil =
      'Goal roadmap BD/DD defines roadmap model, cadence, and data ownership.';
}
