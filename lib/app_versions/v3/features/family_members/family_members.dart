class V3FamilyMembersFeature {
  const V3FamilyMembersFeature._();

  static const status = 'planned';
  static const accessLayer = 'v3/family-plus';

  static const responsibilities = <String>[
    'Manage FamilyPlus members and roles from trusted family membership data.',
    'Prevent cross-family data access at repository and datasource boundaries.',
    'Represent member ownership explicitly in all future read and write contracts.',
    'Keep member management unavailable to Guest, Free, and Plus-only users.',
  ];

  static const blockedUntil =
      'Family members DD defines roles, invitations, removal, and RLS policy.';
}
