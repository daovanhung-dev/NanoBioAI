class V3PremiumAiFeature {
  const V3PremiumAiFeature._();

  static const status = 'planned';
  static const accessLayer = 'v3/plus-family-plus';

  static const responsibilities = <String>[
    'Allow Plus and FamilyPlus AI chat without the Free daily quota.',
    'Allow Plus and FamilyPlus schedule generation without the Free monthly quota.',
    'Keep technical safety limits separate from product quota limits.',
    'Reuse trusted membership access state before enabling paid AI actions.',
  ];

  static const blockedUntil =
      'Premium AI DD defines access checks, abuse limits, and acceptance tests.';
}
