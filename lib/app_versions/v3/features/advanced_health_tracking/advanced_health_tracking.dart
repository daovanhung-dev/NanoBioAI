class V3AdvancedHealthTrackingFeature {
  const V3AdvancedHealthTrackingFeature._();

  static const status = 'planned';
  static const accessLayer = 'v3/plus-family-plus';

  static const responsibilities = <String>[
    'Add paid health tracking modules beyond the guest/basic calculators.',
    'Keep all health reads and writes user-scoped or family-scoped by trusted access.',
    'Feed dashboard and scoring through real data sources only.',
    'Avoid medical claims that are not covered by approved BD/DD content.',
  ];

  static const blockedUntil =
      'Advanced health tracking DD defines metrics, ranges, storage, and copy.';
}
