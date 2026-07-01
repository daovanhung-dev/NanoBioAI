class V3FamilyScheduleFeature {
  const V3FamilyScheduleFeature._();

  static const status = 'implemented';
  static const accessLayer = 'v3/familyplus';

  static const responsibilities = <String>[
    'Show and coordinate schedule items for FamilyPlus members.',
    'Keep each schedule tied to a specific member and trusted family group.',
    'Reuse v1 schedule item concepts without importing v1 presentation code.',
    'Use selected FamilyPlus subject context before schedule generation.',
  ];

  static const runtimeRoute = '/v3/familyplus';
}
