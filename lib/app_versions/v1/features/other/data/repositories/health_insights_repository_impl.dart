import '../../domain/entities/health_insights_entity.dart';
import '../../domain/repositories/health_insights_repository.dart';
import '../datasources/health_insights_local_datasource.dart';

class HealthInsightsRepositoryImpl implements HealthInsightsRepository {
  final HealthInsightsLocalDatasource datasource;

  const HealthInsightsRepositoryImpl({required this.datasource});

  @override
  Future<HealthInsightsHistoryEntity> readHistory({required int days}) {
    return datasource.readHistory(days: days);
  }
}
