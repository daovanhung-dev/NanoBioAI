import '../entities/health_insights_entity.dart';

abstract class HealthInsightsRepository {
  Future<HealthInsightsHistoryEntity> readHistory({required int days});
}
