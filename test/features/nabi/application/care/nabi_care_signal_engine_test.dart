import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/features/nabi/application/care/nabi_care_signal_engine.dart';
import 'package:nano_app/features/nabi/domain/care/nabi_care_models.dart';

void main() {
  group('NabiCareSignalEngine', () {
    test('detects sleep drop against personal baseline', () {
      final snapshot = _snapshot(
        current: const {'sleep_hours': 4.8},
        baselines: const {'sleep_hours_avg_7d': 7.2},
        evidence: const {
          'health.sleep_hours.current': NabiCareEvidence(
            key: 'health.sleep_hours.current',
            value: 4.8,
            source: 'health_tracking_logs',
          ),
          'baseline.sleep_hours_avg_7d': NabiCareEvidence(
            key: 'baseline.sleep_hours_avg_7d',
            value: 7.2,
            source: 'health_tracking_logs',
          ),
        },
      );

      final signals = const NabiCareSignalEngine().evaluate(snapshot);

      expect(
        signals.any((item) => item.code == 'sleep_below_recent_pattern'),
        isTrue,
      );
    });

    test('does not emit hydration action when water restriction is recorded', () {
      final snapshot = _snapshot(
        profile: const {'water_restriction': true},
        current: const {'water_ml': 300},
        baselines: const {'water_ml_avg_7d': 1800},
      );

      final signals = const NabiCareSignalEngine().evaluate(snapshot);

      expect(
        signals.any((item) => item.code == 'water_below_personal_pattern'),
        isFalse,
      );
    });
  });
}

NabiCareSnapshot _snapshot({
  Map<String, Object?> profile = const {},
  Map<String, Object?> current = const {},
  Map<String, Object?> baselines = const {},
  Map<String, NabiCareEvidence> evidence = const {},
}) {
  return NabiCareSnapshot(
    actorKey: 'user-1',
    actorKind: 'member',
    membershipPlan: 'free',
    generatedAt: DateTime(2026, 8, 24, 12),
    profile: profile,
    current: current,
    baselines: baselines,
    adherence: const {},
    conditions: const [],
    symptoms: const [],
    medications: const [],
    labs: const [],
    goals: const [],
    evidence: evidence,
    dataQuality: const NabiCareDataQuality(
      completeness: 0.8,
      availableGroups: ['profile', 'tracking'],
    ),
  );
}
