import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/body_metrics/domain/entities/body_metrics_ai_models.dart';
import 'package:nano_app/app_versions/v1/features/body_metrics/domain/entities/body_metrics_health_report.dart';
import 'package:nano_app/app_versions/v1/features/body_metrics/domain/entities/body_metrics_health_snapshot.dart';

void main() {
  test('AI context strips user id, full name and technical identity fields', () {
    final snapshot = BodyMetricsHealthSnapshot(
      userId: 'secret-user-id',
      fullName: 'Private Name',
      tracking: const [],
      nutrition: const [],
      declaredConditions: const [],
      allergies: const [],
      treatments: const [],
      activeGoals: const [],
      schedule: const BodyMetricsScheduleSummary(),
      generatedAt: DateTime(2026, 8, 18),
    );
    final report = BodyMetricsHealthReport(
      metrics: const [],
      trends: const {},
      freshnessByGroup: const {},
      dataCompleteness: 0,
      dataGaps: const [],
      generatedAt: DateTime(2026, 8, 18),
    );

    final serialized = BodyMetricsAiContext.from(snapshot, report).payload.toString();
    expect(serialized, isNot(contains('secret-user-id')));
    expect(serialized, isNot(contains('Private Name')));
    expect(serialized, isNot(contains('email')));
    expect(serialized, isNot(contains('phone')));
    expect(serialized, isNot(contains('proof')));
  });
}
