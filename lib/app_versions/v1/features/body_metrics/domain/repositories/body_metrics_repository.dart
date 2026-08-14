import '../entities/body_metrics_personal_context.dart';

abstract interface class BodyMetricsRepository {
  Future<BodyMetricsPersonalContext?> loadPersonalContext();
}
