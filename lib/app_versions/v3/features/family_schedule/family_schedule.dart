class V3FamilyScheduleFeature {
  const V3FamilyScheduleFeature._();

  static const status = 'planned';
  static const accessLayer = 'v3/family-plus';

  static const responsibilities = <String>[
    'Show and coordinate schedule items for FamilyPlus members.',
    'Keep each schedule tied to a specific member and trusted family group.',
    'Reuse v1 schedule item concepts without importing v1 presentation code.',
    'Define notification behavior only after FamilyPlus notification DD exists.',
  ];

  static const blockedUntil =
      'Family schedule DD defines visibility, editing rights, and notification rules.';
}
