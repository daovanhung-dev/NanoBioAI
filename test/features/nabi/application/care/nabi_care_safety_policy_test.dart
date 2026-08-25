import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/features/nabi/application/care/nabi_care_safety_policy.dart';
import 'package:nano_app/features/nabi/domain/care/nabi_care_models.dart';

void main() {
  test('removes diagnostic and medication-changing content', () {
    final snapshot = _snapshot();
    final input = NabiCareAnalysis(
      overallStatus: NabiCareOverallStatus.needsAttention,
      summary: 'Bạn bị bệnh X.',
      observations: const [
        NabiCareObservation(
          title: 'Bạn mắc bệnh X',
          detail: 'Kết luận không được phép.',
          severity: NabiCareSeverity.high,
          confidence: 1,
          evidenceKeys: ['health.sleep_hours.current'],
        ),
      ],
      actions: const [
        NabiCareAction(
          id: 'unsafe-medication',
          title: 'Điều chỉnh thuốc',
          description: 'Hãy tăng liều thuốc ngay.',
          priority: 1,
          channelHint: NabiCareChannelHint.inApp,
          evidenceKeys: ['health.sleep_hours.current'],
        ),
      ],
      questions: const [],
      attentionFlags: const [],
      missingData: const [],
      nextReviewAt: DateTime(2026, 8, 25),
      source: 'ai',
    );

    final output = const NabiCareSafetyPolicy().apply(input, snapshot);

    expect(output.summary, isNot(contains('Bạn bị')));
    expect(output.observations, isEmpty);
    expect(output.actions, isEmpty);
  });
}

NabiCareSnapshot _snapshot() {
  return NabiCareSnapshot(
    actorKey: 'user-1',
    actorKind: 'member',
    membershipPlan: 'free',
    generatedAt: DateTime(2026, 8, 24),
    profile: const {},
    current: const {'sleep_hours': 5.0},
    baselines: const {},
    adherence: const {},
    conditions: const [],
    symptoms: const [],
    medications: const [],
    labs: const [],
    goals: const [],
    evidence: const {
      'health.sleep_hours.current': NabiCareEvidence(
        key: 'health.sleep_hours.current',
        value: 5.0,
        source: 'health_tracking_logs',
      ),
    },
    dataQuality: const NabiCareDataQuality(completeness: 0.7),
  );
}
