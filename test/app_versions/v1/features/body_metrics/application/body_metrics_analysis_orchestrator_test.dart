import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/body_metrics/application/body_metrics_ai_service.dart';
import 'package:nano_app/app_versions/v1/features/body_metrics/application/body_metrics_analysis_orchestrator.dart';
import 'package:nano_app/app_versions/v1/features/body_metrics/domain/entities/body_metrics_health_report.dart';
import 'package:nano_app/app_versions/v1/features/body_metrics/domain/entities/body_metrics_health_snapshot.dart';
import 'package:nano_app/services/access/product_access_level.dart';
import 'package:nano_app/services/access/product_access_reader.dart';

class _FakeAccessReader implements ProductAccessReader {
  final ProductAccessLevel level;
  const _FakeAccessReader(this.level);

  @override
  Future<ProductAccessLevel> read() async => level;
}

void main() {
  BodyMetricsHealthSnapshot snapshot() => BodyMetricsHealthSnapshot(
        userId: 'private-id-never-sent-to-ai',
        tracking: const [],
        nutrition: const [],
        declaredConditions: const [],
        allergies: const [],
        treatments: const [],
        activeGoals: const [],
        schedule: const BodyMetricsScheduleSummary(),
        generatedAt: DateTime(2026, 8, 18),
      );

  BodyMetricsHealthReport report() => BodyMetricsHealthReport(
        metrics: const [],
        trends: const {},
        freshnessByGroup: const {},
        dataCompleteness: .2,
        dataGaps: const ['Thiếu dữ liệu theo dõi gần đây'],
        generatedAt: DateTime(2026, 8, 18),
      );

  Future<void> runCase(ProductAccessLevel level, int expected) async {
    var calls = 0;
    final service = BodyMetricsAiService(textGenerator: (prompt) async {
      calls++;
      final finalStage = prompt.contains('STAGE: P05') || prompt.contains('STAGE: P15');
      if (finalStage) {
        return '{"overview":"Nabi khuyên bạn tiếp tục theo dõi đều đặn","strengths":[],"priorities":[],"actions_today":[{"action":"Tiếp tục duy trì thói quen đang ổn định","reason":"Dữ liệu hiện tại phù hợp để tiếp tục theo dõi","related_metric_ids":[],"priority":"vua","difficulty":"de","tracking_metric_ids":[]}],"actions_7_days":[{"action":"Tiếp tục duy trì thói quen đang ổn định","reason":"Dữ liệu hiện tại phù hợp để tiếp tục theo dõi","related_metric_ids":[],"priority":"vua","difficulty":"de","tracking_metric_ids":[]}],"actions_30_days":[{"action":"Tiếp tục duy trì thói quen đang ổn định","reason":"Dữ liệu hiện tại phù hợp để tiếp tục theo dõi","related_metric_ids":[],"priority":"vua","difficulty":"de","tracking_metric_ids":[]}],"monitoring_metric_ids":[],"missing_data":[],"confidence":"vua","questions_for_clinician":[]}';
      }
      return '{"summary":"Nabi khuyên bạn tiếp tục theo dõi đều đặn","strengths":[],"priorities":[],"actions":[],"related_metric_ids":[]}';
    });
    final orchestrator = BodyMetricsAnalysisOrchestrator(
      aiService: service,
      accessReader: _FakeAccessReader(level),
    );
    final bundle = await orchestrator.analyze(snapshot: snapshot(), report: report());
    expect(calls, expected);
    expect(bundle.totalStages, expected);
    expect(bundle.synthesis, isNotNull);
  }

  test('Free executes exactly five stages', () async {
    await runCase(ProductAccessLevel.free, 5);
  });

  test('Plus executes exactly fifteen stages', () async {
    await runCase(ProductAccessLevel.plus, 15);
  });

  test('FamilyPlus executes exactly fifteen stages', () async {
    await runCase(ProductAccessLevel.familyPlus, 15);
  });
}
