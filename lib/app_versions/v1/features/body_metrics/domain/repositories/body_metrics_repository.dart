import '../entities/body_metrics_health_snapshot.dart';
import '../entities/body_metrics_personal_context.dart';

abstract class BodyMetricsRepository {
  Future<BodyMetricsPersonalContext?> loadPersonalContext();
  Future<BodyMetricsHealthSnapshot?> loadHealthSnapshot();
}
