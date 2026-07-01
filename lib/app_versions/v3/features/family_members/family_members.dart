class V3FamilyMembersFeature {
  const V3FamilyMembersFeature._();

  static const status = 'implemented';
  static const accessLayer = 'v3/familyplus';

  static const responsibilities = <String>[
    'Manage FamilyPlus members and roles from trusted family membership data.',
    'Prevent cross-family data access at repository and datasource boundaries.',
    'Represent member ownership explicitly in read and write contracts.',
    'Keep member management unavailable to Guest, Free, and Plus-only users.',
  ];

  static const runtimeRoute = '/v3/familyplus';
}
