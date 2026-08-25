class SleepAiSection {
  const SleepAiSection({
    required this.key,
    required this.title,
    required this.summary,
    required this.evidence,
    required this.recommendations,
    required this.confidence,
  });

  final String key;
  final String title;
  final String summary;
  final List<String> evidence;
  final List<String> recommendations;
  final double confidence;

  Map<String, Object?> toJson() => {
        'key': key,
        'title': title,
        'summary': summary,
        'evidence': evidence,
        'recommendations': recommendations,
        'confidence': confidence,
      };

  factory SleepAiSection.fromJson(String key, Map<String, Object?> json) {
    List<String> strings(Object? raw) => raw is List
        ? raw
            .whereType<Object>()
            .map((value) => value.toString().trim())
            .where((value) => value.isNotEmpty)
            .take(6)
            .toList(growable: false)
        : const [];

    return SleepAiSection(
      key: key,
      title: _nonEmpty(json['title']) ?? key,
      summary: json['summary']?.toString().trim() ?? '',
      evidence: strings(json['evidence']),
      recommendations: strings(json['recommendations']),
      confidence: ((json['confidence'] as num?)?.toDouble() ?? 0.5)
          .clamp(0.0, 1.0).toDouble(),
    );
  }

  static String? _nonEmpty(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}

class SleepAiAnalysisResult {
  const SleepAiAnalysisResult({
    required this.model,
    required this.generatedAt,
    required this.sections,
  });

  final String model;
  final DateTime generatedAt;
  final List<SleepAiSection> sections;

  Map<String, Object?> toJson() => {
        'model': model,
        'generated_at': generatedAt.toIso8601String(),
        'sections': sections.map((section) => section.toJson()).toList(),
      };
}
