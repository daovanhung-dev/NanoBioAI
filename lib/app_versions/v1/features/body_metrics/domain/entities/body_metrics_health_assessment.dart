enum BodyMetricsOverallHealthLevel {
  good,
  fair,
  attention,
  concern,
  insufficientData,
}

class BodyMetricsHealthAssessment {
  final BodyMetricsOverallHealthLevel level;
  final String headline;
  final String summary;
  final List<String> strengths;
  final List<String> attentionItems;
  final List<String> keyMetricIds;
  final String dataConfidenceLabel;
  final bool hasEnoughData;

  const BodyMetricsHealthAssessment({
    required this.level,
    required this.headline,
    required this.summary,
    required this.strengths,
    required this.attentionItems,
    required this.keyMetricIds,
    required this.dataConfidenceLabel,
    required this.hasEnoughData,
  });

  int get strengthCount => strengths.length;
  int get attentionCount => attentionItems.length;
}
