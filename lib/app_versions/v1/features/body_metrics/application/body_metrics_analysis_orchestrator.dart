import 'package:nano_app/services/access/product_access_level.dart';
import 'package:nano_app/services/access/product_access_reader.dart';

import '../domain/entities/body_metrics_ai_models.dart';
import '../domain/entities/body_metrics_health_report.dart';
import '../domain/entities/body_metrics_health_snapshot.dart';
import 'body_metrics_ai_response_validator.dart';
import 'body_metrics_ai_service.dart';
import 'body_metrics_prompt_builder.dart';

typedef BodyMetricsAiProgress = void Function(int completed, int total, String stageId);

class BodyMetricsAnalysisOrchestrator {
  final BodyMetricsAiService aiService;
  final ProductAccessReader accessReader;

  const BodyMetricsAnalysisOrchestrator({
    required this.aiService,
    required this.accessReader,
  });

  Future<BodyMetricsAiBundle> analyze({
    required BodyMetricsHealthSnapshot snapshot,
    required BodyMetricsHealthReport report,
    BodyMetricsAiProgress? onProgress,
  }) async {
    final access = await accessReader.read();
    final total = access.bodyMetricsAiStages;
    final context = BodyMetricsAiContext.from(snapshot, report);
    final results = <BodyMetricsAiStageResult>[];
    final stageIds = [
      'P01', 'P02', 'P03', 'P04', 'P05',
      if (access.isPaid) ...['P06', 'P07', 'P08', 'P09', 'P10', 'P11', 'P12', 'P13', 'P14', 'P15'],
    ];

    for (final stageId in stageIds) {
      final dependencies = _dependencies(stageId, results);
      BodyMetricsAiStageResult result;
      try {
        final prompt = BodyMetricsPromptBuilder.build(
          stageId: stageId,
          context: context,
          dependencies: dependencies,
        );
        final raw = await aiService.generateStage(prompt);
        result = BodyMetricsAiResponseValidator.validate(stageId, raw);
      } catch (_) {
        result = BodyMetricsAiStageResult.failed(
          stageId,
          'Stage không đạt kiểm tra an toàn hoặc tạm thời không khả dụng.',
        );
      }
      results.add(result);
      onProgress?.call(results.length, total, stageId);
    }

    BodyMetricsAiSynthesis? synthesis;
    final preferredId = access.isPaid ? 'P15' : 'P05';
    final preferred = results.where((item) => item.stageId == preferredId && item.success).firstOrNull;
    final freeFallback = results.where((item) => item.stageId == 'P05' && item.success).firstOrNull;
    final synthesisStage = preferred ?? freeFallback;
    if (synthesisStage != null) {
      try {
        synthesis = BodyMetricsAiResponseValidator.synthesis(synthesisStage);
      } catch (_) {
        synthesis = null;
      }
    }
    return BodyMetricsAiBundle(
      accessLevel: access,
      stages: results,
      synthesis: synthesis,
    );
  }

  List<BodyMetricsAiStageResult> _dependencies(
    String stageId,
    List<BodyMetricsAiStageResult> results,
  ) {
    bool include(BodyMetricsAiStageResult item) => switch (stageId) {
          'P05' => const {'P01', 'P02', 'P03', 'P04'}.contains(item.stageId),
          'P06' || 'P07' || 'P08' || 'P09' || 'P10' || 'P11' || 'P12' || 'P13' => item.stageId == 'P05',
          'P14' => const {'P06', 'P07', 'P08', 'P09', 'P10', 'P11', 'P12', 'P13'}.contains(item.stageId),
          'P15' => item.stageId == 'P05' || item.stageId == 'P14',
          _ => false,
        };
    return results.where(include).toList(growable: false);
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    for (final item in this) return item;
    return null;
  }
}
