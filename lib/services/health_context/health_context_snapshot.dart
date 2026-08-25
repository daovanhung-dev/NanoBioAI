import 'health_context_freshness.dart';

class HealthContextSnapshot {
  final String subjectId;
  final String actorKind;
  final String membershipPlan;
  final String contextVersion;
  final DateTime generatedAt;
  final Map<String, Object?> profile;
  final Map<String, Object?> current;
  final Map<String, Object?> baselines;
  final Map<String, Object?> adherence;
  final List<Map<String, Object?>> conditions;
  final List<Map<String, Object?>> symptoms;
  final List<Map<String, Object?>> medications;
  final List<Map<String, Object?>> labs;
  final List<Map<String, Object?>> goals;
  final HealthContextFreshness freshness;

  const HealthContextSnapshot({
    required this.subjectId,
    required this.actorKind,
    required this.membershipPlan,
    required this.contextVersion,
    required this.generatedAt,
    required this.profile,
    required this.current,
    required this.baselines,
    required this.adherence,
    required this.conditions,
    required this.symptoms,
    required this.medications,
    required this.labs,
    required this.goals,
    required this.freshness,
  });
}
