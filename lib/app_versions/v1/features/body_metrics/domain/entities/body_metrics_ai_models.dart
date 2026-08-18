import 'package:nano_app/services/access/product_access_level.dart';

import 'body_metrics_health_report.dart';
import 'body_metrics_health_snapshot.dart';

class BodyMetricsAiContext {
  final Map<String, Object?> payload;

  const BodyMetricsAiContext(this.payload);

  factory BodyMetricsAiContext.from(
    BodyMetricsHealthSnapshot snapshot,
    BodyMetricsHealthReport report,
  ) {
    final metrics = <String, Object?>{};
    for (final metric in report.metrics) {
      if (!metric.hasValue) continue;
      metrics[metric.id] = {
        if (metric.value != null) 'value': metric.value,
        if (metric.textValue != null) 'text': metric.textValue,
        'unit': metric.unit,
        'window': metric.dataWindow,
        'formula_version': metric.formulaVersion,
      };
    }
    return BodyMetricsAiContext({
      'metrics': metrics,
      'trends': report.trends.map((key, trend) => MapEntry(key, {
            'direction': trend.direction.name,
            'sample_count': trend.sampleCount,
          })),
      'declared_conditions': snapshot.declaredConditions
          .map((item) => {'code': item.code, 'name': item.name, 'severity': item.severityLevel})
          .toList(growable: false),
      'goals': snapshot.activeGoals.map((item) => item.name).toList(growable: false),
      'allergies': snapshot.allergies,
      'treatments': snapshot.treatments
          .map((item) => {
                if (item.treatmentName != null) 'treatment': item.treatmentName,
                if (item.medicationName != null) 'medication': item.medicationName,
              })
          .toList(growable: false),
      'lifestyle_flags': snapshot.lifestyle?.activeFlags ?? const <String>[],
      'schedule': {
        'planned': snapshot.schedule.plannedTaskCount,
        'completed': snapshot.schedule.completedTaskCount,
        'exercise_planned': snapshot.schedule.plannedExerciseCount,
        'exercise_completed': snapshot.schedule.completedExerciseCount,
      },
      'data_completeness_percent': (report.dataCompleteness * 100).round(),
      'data_gaps': report.dataGaps,
    });
  }
}

class BodyMetricsAiStageResult {
  final String stageId;
  final bool success;
  final Map<String, Object?> payload;
  final String? safeError;

  const BodyMetricsAiStageResult({
    required this.stageId,
    required this.success,
    required this.payload,
    this.safeError,
  });

  const BodyMetricsAiStageResult.failed(this.stageId, [this.safeError])
      : success = false,
        payload = const {};
}

class BodyMetricsAiAction {
  final String action;
  final String reason;
  final List<String> relatedMetricIds;
  final String priority;
  final String difficulty;
  final List<String> trackingMetricIds;

  const BodyMetricsAiAction({
    required this.action,
    required this.reason,
    required this.relatedMetricIds,
    required this.priority,
    required this.difficulty,
    required this.trackingMetricIds,
  });
}

class BodyMetricsAiSynthesis {
  final String overview;
  final List<String> strengths;
  final List<String> priorities;
  final List<BodyMetricsAiAction> actionsToday;
  final List<BodyMetricsAiAction> actions7Days;
  final List<BodyMetricsAiAction> actions30Days;
  final List<String> monitoringMetricIds;
  final List<String> missingData;
  final String confidence;
  final List<String> questionsForClinician;

  const BodyMetricsAiSynthesis({
    required this.overview,
    required this.strengths,
    required this.priorities,
    required this.actionsToday,
    required this.actions7Days,
    required this.actions30Days,
    required this.monitoringMetricIds,
    required this.missingData,
    required this.confidence,
    required this.questionsForClinician,
  });
}

class BodyMetricsAiBundle {
  final ProductAccessLevel accessLevel;
  final List<BodyMetricsAiStageResult> stages;
  final BodyMetricsAiSynthesis? synthesis;

  const BodyMetricsAiBundle({
    required this.accessLevel,
    required this.stages,
    required this.synthesis,
  });

  int get totalStages => accessLevel.bodyMetricsAiStages;
  int get completedStages => stages.length;
  int get successfulStages => stages.where((stage) => stage.success).length;
  bool get isPartial => successfulStages < totalStages;
}
