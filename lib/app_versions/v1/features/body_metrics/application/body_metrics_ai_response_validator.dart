import 'dart:convert';

import '../domain/entities/body_metrics_ai_models.dart';
import '../domain/entities/body_metrics_health_metric.dart';

class BodyMetricsAiResponseValidator {
  const BodyMetricsAiResponseValidator._();

  static BodyMetricsAiStageResult validate(String stageId, String raw) {
    final cleaned = raw
        .replaceAll(RegExp(r'^```(?:json)?\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s*```$'), '')
        .trim();
    final decoded = jsonDecode(cleaned);
    if (decoded is! Map) throw const FormatException('AI payload is not an object');
    final map = decoded.map<String, Object?>((key, value) => MapEntry(key.toString(), value));

    if (stageId == 'P05' || stageId == 'P15') {
      _narrative(map['overview'], required: true);
      _narrativeList(map['strengths'], max: 3);
      _narrativeList(map['priorities'], max: 3);
      _actions(map['actions_today'], max: 5);
      _actions(map['actions_7_days'], max: 5);
      _actions(map['actions_30_days'], max: 5);
      _narrativeList(map['missing_data'], max: 5);
      _narrativeList(map['questions_for_clinician'], max: 5);
      _metricIds(map['monitoring_metric_ids']);
      _confidence(map['confidence']);
    } else {
      _narrative(map['summary'], required: true);
      _narrativeList(map['strengths'], max: 5);
      _narrativeList(map['priorities'], max: 5);
      _narrativeList(map['actions'], max: 5);
      _metricIds(map['related_metric_ids']);
    }
    return BodyMetricsAiStageResult(stageId: stageId, success: true, payload: map);
  }

  static BodyMetricsAiSynthesis synthesis(BodyMetricsAiStageResult result) {
    if (!result.success) throw const FormatException('Synthesis stage failed');
    final map = result.payload;
    return BodyMetricsAiSynthesis(
      overview: _narrative(map['overview'], required: true),
      strengths: _narrativeList(map['strengths'], max: 3),
      priorities: _narrativeList(map['priorities'], max: 3),
      actionsToday: _actions(map['actions_today'], max: 5),
      actions7Days: _actions(map['actions_7_days'], max: 5),
      actions30Days: _actions(map['actions_30_days'], max: 5),
      monitoringMetricIds: _metricIds(map['monitoring_metric_ids']),
      missingData: _narrativeList(map['missing_data'], max: 5),
      confidence: _confidence(map['confidence']),
      questionsForClinician: _narrativeList(map['questions_for_clinician'], max: 5),
    );
  }

  static String _narrative(Object? value, {bool required = false}) {
    final text = value?.toString().trim() ?? '';
    if (required && text.length < 8) throw const FormatException('Missing narrative');
    if (text.isEmpty) return '';
    if (text.length > 480) throw const FormatException('Narrative too long');
    if (RegExp(r'\d').hasMatch(text)) throw const FormatException('Numeric claim is not allowed');
    final normalized = text.toLowerCase();
    const blocked = <String>[
      'bạn mắc',
      'được chẩn đoán',
      'chẩn đoán là',
      'chắc chắn là',
      'chắc chắn sẽ',
      'cần điều trị',
      'hãy dùng thuốc',
      'ngừng thuốc',
      'tăng liều',
      'giảm liều',
      'đổi thuốc',
      'kê thuốc',
      'tương tác thuốc chắc chắn',
      'cam kết',
    ];
    if (blocked.any(normalized.contains)) throw const FormatException('Unsafe medical claim');
    return text;
  }

  static List<BodyMetricsAiAction> _actions(Object? value, {required int max}) {
    if (value is! List || value.isEmpty || value.length > max) {
      throw const FormatException('Invalid action list');
    }
    final result = <BodyMetricsAiAction>[];
    for (final item in value) {
      if (item is! Map) throw const FormatException('Action must be an object');
      final map = item.map<String, Object?>((key, value) => MapEntry(key.toString(), value));
      result.add(BodyMetricsAiAction(
        action: _narrative(map['action'], required: true),
        reason: _narrative(map['reason'], required: true),
        relatedMetricIds: _metricIds(map['related_metric_ids']),
        priority: _priority(map['priority']),
        difficulty: _difficulty(map['difficulty']),
        trackingMetricIds: _metricIds(map['tracking_metric_ids']),
      ));
    }
    return result;
  }

  static String _priority(Object? value) => switch (value?.toString().trim().toLowerCase()) {
        'cao' => 'cao',
        'vua' || 'vừa' => 'vừa',
        'thap' || 'thấp' => 'thấp',
        _ => throw const FormatException('Invalid priority'),
      };

  static String _difficulty(Object? value) => switch (value?.toString().trim().toLowerCase()) {
        'de' || 'dễ' => 'dễ',
        'vua' || 'vừa' => 'vừa',
        'kho' || 'khó' => 'khó',
        _ => throw const FormatException('Invalid difficulty'),
      };

  static List<String> _narrativeList(Object? value, {required int max}) {
    if (value == null) return const [];
    if (value is! List) throw const FormatException('Expected list');
    if (value.length > max) throw const FormatException('List too long');
    return value.map((item) => _narrative(item)).where((item) => item.isNotEmpty).toList(growable: false);
  }

  static List<String> _metricIds(Object? value) {
    if (value == null) return const [];
    if (value is! List || value.length > 10) throw const FormatException('Invalid metric id list');
    final allowed = BodyMetricsMetricIds.all.toSet();
    final result = <String>[];
    for (final item in value) {
      final id = item.toString().trim();
      if (!allowed.contains(id)) throw FormatException('Unknown metric id: $id');
      if (!result.contains(id)) result.add(id);
    }
    return result;
  }

  static String _confidence(Object? value) {
    return switch (value?.toString().trim().toLowerCase()) {
      'cao' => 'cao',
      'vua' || 'vừa' => 'vừa',
      'thap' || 'thấp' => 'thấp',
      _ => throw const FormatException('Invalid confidence'),
    };
  }
}
