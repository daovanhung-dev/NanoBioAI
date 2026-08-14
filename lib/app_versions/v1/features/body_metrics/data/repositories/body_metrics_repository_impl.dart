import '../../domain/entities/body_metrics_personal_context.dart';
import '../../domain/repositories/body_metrics_repository.dart';
import '../datasources/body_metrics_local_datasource.dart';

class BodyMetricsRepositoryImpl implements BodyMetricsRepository {
  final BodyMetricsLocalDatasource datasource;

  const BodyMetricsRepositoryImpl({required this.datasource});

  @override
  Future<BodyMetricsPersonalContext?> loadPersonalContext() =>
      datasource.loadPersonalContext();
}
