import 'health_context_snapshot.dart';

enum HealthAiContextPurpose { chat, voice, nabiCare, nutrition, schedule }

class HealthAiContextMapper {
  const HealthAiContextMapper();

  Map<String, Object?> map(
    HealthContextSnapshot snapshot, {
    required HealthAiContextPurpose purpose,
  }) {
    final common = <String, Object?>{
      'context_version': snapshot.contextVersion,
      'generated_at': snapshot.generatedAt.toIso8601String(),
      'profile': snapshot.profile,
      'current': snapshot.current,
      'data_quality': {
        'missing_groups': snapshot.freshness.missingGroups.toList(),
        'stale_groups': snapshot.freshness.staleGroups.toList(),
      },
    };
    return switch (purpose) {
      HealthAiContextPurpose.chat || HealthAiContextPurpose.voice => {
          ...common,
          'conditions': snapshot.conditions,
          'goals': snapshot.goals,
        },
      HealthAiContextPurpose.nabiCare => {
          ...common,
          'baselines': snapshot.baselines,
          'adherence': snapshot.adherence,
          'conditions': snapshot.conditions,
          'symptoms': snapshot.symptoms,
          'medications': snapshot.medications,
          'labs': snapshot.labs,
          'goals': snapshot.goals,
        },
      HealthAiContextPurpose.nutrition => {
          ...common,
          'conditions': snapshot.conditions,
          'symptoms': snapshot.symptoms,
          'medications': snapshot.medications,
          'labs': snapshot.labs,
          'goals': snapshot.goals,
        },
      HealthAiContextPurpose.schedule => {
          ...common,
          'baselines': snapshot.baselines,
          'adherence': snapshot.adherence,
          'goals': snapshot.goals,
        },
    };
  }
}
