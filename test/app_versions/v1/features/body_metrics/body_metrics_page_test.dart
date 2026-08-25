import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/body_metrics/domain/entities/body_metrics_health_assessment.dart';
import 'package:nano_app/app_versions/v1/features/body_metrics/domain/entities/body_metrics_health_metric.dart';
import 'package:nano_app/app_versions/v1/features/body_metrics/domain/entities/body_metrics_health_report.dart';
import 'package:nano_app/app_versions/v1/features/body_metrics/domain/entities/body_metrics_health_snapshot.dart';
import 'package:nano_app/app_versions/v1/features/body_metrics/presentation/pages/body_metrics_page.dart';
import 'package:nano_app/app_versions/v1/features/body_metrics/providers/body_metrics_providers.dart';

void main() {
  testWidgets('shows a plain-language health conclusion without AI', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('SỨC KHỎE HIỆN TẠI'), findsOneWidget);
    expect(find.text('KHÁ ỔN'), findsOneWidget);
    expect(find.text('Bạn đang làm tốt'), findsOneWidget);
    expect(find.text('Bạn nên chú ý'), findsOneWidget);
    expect(find.text('Muốn Nabi phân tích sâu hơn?'), findsOneWidget);
  });

  testWidgets('keeps full technical metrics behind progressive disclosure', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Xem toàn bộ chỉ số'), findsOneWidget);
    expect(find.text('Ăn uống & năng lượng'), findsNothing);

    await tester.ensureVisible(find.text('Xem toàn bộ chỉ số'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xem toàn bộ chỉ số'));
    await tester.pumpAndSettle();

    expect(find.text('Ăn uống & năng lượng'), findsOneWidget);
    expect(find.text('Dữ liệu & thói quen theo dõi'), findsOneWidget);
  });

  testWidgets('keeps medical safety copy visible in the page', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Thông tin tham khảo'), findsOneWidget);
    expect(find.textContaining('không dùng để chẩn đoán bệnh'), findsOneWidget);
  });
}

Widget _app() {
  final snapshot = _snapshot();
  final report = _report();
  final assessment = const BodyMetricsHealthAssessment(
    level: BodyMetricsOverallHealthLevel.fair,
    headline: 'KHÁ ỔN',
    summary:
        'Nhìn chung sức khỏe của bạn khá ổn, nhưng có một nhóm chỉ số nên được cải thiện thêm.',
    strengths: ['Cân nặng đang trong khoảng tham khảo so với chiều cao.'],
    attentionItems: [
      'Thời lượng ngủ gần đây đang ngoài khoảng 7–9 giờ — thử điều chỉnh giờ ngủ đều hơn, từng 15–30 phút.',
    ],
    keyMetricIds: [
      BodyMetricsMetricIds.bmi,
      BodyMetricsMetricIds.sleepAverage7d,
    ],
    dataConfidenceLabel: 'Dữ liệu khá đầy đủ',
    hasEnoughData: true,
  );

  return ProviderScope(
    overrides: [
      bodyMetricsControllerProvider.overrideWith(
        () => _FakeBodyMetricsController(
          BodyMetricsState(
            status: BodyMetricsStatus.ready,
            snapshot: snapshot,
            report: report,
            assessment: assessment,
            totalAiStages: 5,
          ),
        ),
      ),
    ],
    child: const MaterialApp(home: BodyMetricsPage()),
  );
}

class _FakeBodyMetricsController extends BodyMetricsController {
  final BodyMetricsState initialState;

  _FakeBodyMetricsController(this.initialState);

  @override
  BodyMetricsState build() => initialState;

  @override
  Future<void> load() async {}
}

BodyMetricsHealthSnapshot _snapshot() {
  return BodyMetricsHealthSnapshot(
    userId: 'test-user',
    ageYears: 30,
    heightCm: 170,
    profileWeightKg: 65,
    tracking: [
      BodyMetricsTrackingPoint(
        date: DateTime(2026, 8, 25),
        weightKg: 65,
        sleepHours: 6,
      ),
    ],
    nutrition: const [],
    declaredConditions: const [],
    allergies: const [],
    treatments: const [],
    activeGoals: const [],
    schedule: const BodyMetricsScheduleSummary(),
    generatedAt: DateTime(2026, 8, 25),
  );
}

BodyMetricsHealthReport _report() {
  return BodyMetricsHealthReport(
    metrics: const [
      BodyMetricsHealthMetric(
        id: BodyMetricsMetricIds.bmi,
        category: BodyMetricsMetricCategory.body,
        title: 'BMI',
        value: 22.5,
        textValue: 'trong khoảng tham khảo',
        unit: 'kg/m²',
        status: BodyMetricsMetricStatus.info,
        source: BodyMetricsMetricSource.calculated,
        formulaVersion: 'test-v1',
        reference: 'Adult wellness screening reference; not a diagnosis',
        dataWindow: 'current',
      ),
      BodyMetricsHealthMetric(
        id: BodyMetricsMetricIds.sleepAverage7d,
        category: BodyMetricsMetricCategory.recovery,
        title: 'Giấc ngủ trung bình 7 ngày',
        value: 6,
        unit: 'giờ',
        status: BodyMetricsMetricStatus.info,
        source: BodyMetricsMetricSource.calculated,
        formulaVersion: 'test-v1',
        reference: '7–9 giờ tham khảo',
        dataWindow: '7d',
      ),
      BodyMetricsHealthMetric(
        id: BodyMetricsMetricIds.energyAlignment,
        category: BodyMetricsMetricCategory.energy,
        title: 'Mức khớp năng lượng',
        value: 95,
        unit: '%',
        status: BodyMetricsMetricStatus.info,
        source: BodyMetricsMetricSource.calculated,
        formulaVersion: 'test-v1',
        reference: 'test',
        dataWindow: '30d',
      ),
      BodyMetricsHealthMetric(
        id: BodyMetricsMetricIds.scheduleCompletion,
        category: BodyMetricsMetricCategory.adherence,
        title: 'Mức hoàn thành lịch chăm sóc',
        value: 20,
        unit: '%',
        status: BodyMetricsMetricStatus.info,
        source: BodyMetricsMetricSource.calculated,
        formulaVersion: 'test-v1',
        reference: 'not a health score',
        dataWindow: '30d',
      ),
      BodyMetricsHealthMetric(
        id: BodyMetricsMetricIds.dataCompletenessFreshness,
        category: BodyMetricsMetricCategory.dataQuality,
        title: 'Độ đầy đủ dữ liệu',
        value: 80,
        unit: '%',
        status: BodyMetricsMetricStatus.info,
        source: BodyMetricsMetricSource.calculated,
        formulaVersion: 'test-v1',
        reference: 'not a health score',
        dataWindow: 'current',
      ),
    ],
    trends: const {},
    freshnessByGroup: const {},
    dataCompleteness: 0.8,
    dataGaps: const [],
    generatedAt: DateTime(2026, 8, 25),
  );
}
