import '../../domain/entities/body_metrics_health_snapshot.dart';
import '../../domain/entities/body_metrics_personal_context.dart';
import '../../domain/repositories/body_metrics_repository.dart';
import '../datasources/body_metrics_local_datasource.dart';

typedef BodyMetricsSubjectResolver = Future<String> Function();

class BodyMetricsRepositoryImpl implements BodyMetricsRepository {
  final BodyMetricsLocalDatasource datasource;
  final BodyMetricsSubjectResolver resolveSubjectId;

  const BodyMetricsRepositoryImpl({
    required this.datasource,
    required this.resolveSubjectId,
  });

  @override
  Future<BodyMetricsPersonalContext?> loadPersonalContext() async {
    final subjectId = await resolveSubjectId();
    return datasource.loadPersonalContext(userId: subjectId);
  }

  @override
  Future<BodyMetricsHealthSnapshot?> loadHealthSnapshot() async {
    final subjectId = await resolveSubjectId();
    return datasource.loadHealthSnapshot(userId: subjectId);
  }
}
