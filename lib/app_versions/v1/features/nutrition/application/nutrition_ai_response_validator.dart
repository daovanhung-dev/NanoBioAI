import 'dart:convert';

import '../domain/entities/nutrition_intelligence_entity.dart';

/// Strict boundary between generative text and health-facing UI.
///
/// The validator intentionally rejects diagnosis/treatment language and any
/// generated number. Quantitative values are rendered from deterministic app
/// calculations instead of being authored by the model.
class NutritionAiResponseValidator {
  const NutritionAiResponseValidator();

  NutritionAiReport parse(
    String raw, {
    required Set<String> allowedEvidenceCodes,
  }) {
    final cleaned = raw
        .replaceAll(RegExp(r'^```(?:json)?\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s*```$'), '')
        .trim();
    final decoded = jsonDecode(cleaned);
    if (decoded is! Map) {
      throw const FormatException('Nutrition AI payload is not an object');
    }

    final summary = _narrative(
      decoded['summary'],
      field: 'summary',
      minLength: 8,
      maxLength: 520,
    );

    final insights = <NutritionAiInsight>[];
    final rawInsights = decoded['insights'];
    if (rawInsights is List) {
      for (final value in rawInsights.take(6)) {
        if (value is! Map) continue;
        final evidence = _evidenceCodes(
          value['evidence_codes'],
          allowedEvidenceCodes,
        );
        if (evidence.isEmpty) continue;
        insights.add(
          NutritionAiInsight(
            title: _narrative(
              value['title'],
              field: 'insight.title',
              minLength: 4,
              maxLength: 110,
            ),
            body: _narrative(
              value['body'],
              field: 'insight.body',
              minLength: 8,
              maxLength: 420,
            ),
            evidenceCodes: evidence,
            confidence: _level(value['confidence']),
            priority: _level(value['priority']),
          ),
        );
      }
    }

    return NutritionAiReport(
      summary: summary,
      insights: List.unmodifiable(insights),
      todayActions: _narrativeList(
        decoded['today_actions'],
        field: 'today_actions',
        maxItems: 5,
      ),
      weeklyActions: _narrativeList(
        decoded['weekly_actions'],
        field: 'weekly_actions',
        maxItems: 5,
      ),
      missingData: _narrativeList(
        decoded['missing_data'],
        field: 'missing_data',
        maxItems: 6,
      ),
      safetyFlags: _narrativeList(
        decoded['safety_flags'],
        field: 'safety_flags',
        maxItems: 6,
      ),
      confidence: _level(decoded['confidence']),
      generatedByAi: true,
    );
  }

  List<String> _evidenceCodes(
    Object? value,
    Set<String> allowedEvidenceCodes,
  ) {
    if (value is! List) return const [];
    final result = <String>[];
    for (final item in value) {
      final code = item?.toString().trim() ?? '';
      if (code.isEmpty || !allowedEvidenceCodes.contains(code)) continue;
      if (!result.contains(code)) result.add(code);
      if (result.length == 6) break;
    }
    return List.unmodifiable(result);
  }

  List<String> _narrativeList(
    Object? value, {
    required String field,
    required int maxItems,
  }) {
    if (value is! List) return const [];
    final result = <String>[];
    for (final item in value.take(maxItems)) {
      final text = item?.toString().trim() ?? '';
      if (text.isEmpty) continue;
      result.add(
        _narrative(
          text,
          field: field,
          minLength: 4,
          maxLength: 260,
        ),
      );
    }
    return List.unmodifiable(result);
  }

  String _narrative(
    Object? value, {
    required String field,
    required int minLength,
    required int maxLength,
  }) {
    final text = value?.toString().trim() ?? '';
    if (text.length < minLength || text.length > maxLength) {
      throw FormatException('Invalid narrative length for $field');
    }
    if (RegExp(r'\d').hasMatch(text)) {
      throw FormatException('Generated numbers are not allowed in $field');
    }

    final normalized = text.toLowerCase();
    const blocked = <String>[
      'bạn mắc',
      'bạn bị bệnh',
      'được chẩn đoán',
      'chẩn đoán là',
      'chẩn đoán rằng',
      'điều trị bằng',
      'cần điều trị',
      'hãy dùng thuốc',
      'nên dùng thuốc',
      'ngừng thuốc',
      'dừng thuốc',
      'đổi thuốc',
      'tăng liều',
      'giảm liều',
      'kê thuốc',
      'chắc chắn sẽ',
      'cam kết',
      'bảo đảm sẽ',
      'đảm bảo sẽ',
    ];
    if (blocked.any(normalized.contains)) {
      throw FormatException('Unsafe medical claim in $field');
    }
    return text;
  }

  String _level(Object? value) {
    return switch (value?.toString().trim().toLowerCase()) {
      'high' || 'cao' => 'cao',
      'medium' || 'vua' || 'vừa' => 'vừa',
      _ => 'thấp',
    };
  }
}
