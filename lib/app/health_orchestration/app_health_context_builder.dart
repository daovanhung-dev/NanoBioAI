import 'package:nano_app/features/nabi/application/care/nabi_care_context_builder.dart';
import 'package:nano_app/features/nabi/domain/care/nabi_care_repository.dart';
import 'package:nano_app/services/health_context/health_context_freshness.dart';
import 'package:nano_app/services/health_context/health_context_reader.dart';
import 'package:nano_app/services/health_context/health_context_snapshot.dart';

class AppHealthContextBuilder implements HealthContextReader {
  final NabiCareRepository repository;
  final NabiCareContextBuilder contextBuilder;

  AppHealthContextBuilder({
    required this.repository,
    NabiCareContextBuilder? contextBuilder,
  }) : contextBuilder = contextBuilder ?? NabiCareContextBuilder();

  @override
  Future<HealthContextSnapshot> read({String? subjectId}) async {
    final raw = await repository.loadRawContext(subjectId: subjectId);
    final snapshot = contextBuilder.build(raw);
    return HealthContextSnapshot(
      subjectId: snapshot.actorKey,
      actorKind: snapshot.actorKind,
      membershipPlan: snapshot.membershipPlan,
      contextVersion: snapshot.fingerprint(),
      generatedAt: snapshot.generatedAt,
      profile: Map.unmodifiable(snapshot.profile),
      current: Map.unmodifiable(snapshot.current),
      baselines: Map.unmodifiable(snapshot.baselines),
      adherence: Map.unmodifiable(snapshot.adherence),
      conditions: List.unmodifiable(snapshot.conditions),
      symptoms: List.unmodifiable(snapshot.symptoms),
      medications: List.unmodifiable(snapshot.medications),
      labs: List.unmodifiable(snapshot.labs),
      goals: List.unmodifiable(snapshot.goals),
      freshness: HealthContextFreshness(
        missingGroups: Set.unmodifiable(snapshot.dataQuality.missingGroups),
        staleGroups: Set.unmodifiable(snapshot.dataQuality.staleGroups),
      ),
    );
  }
}
