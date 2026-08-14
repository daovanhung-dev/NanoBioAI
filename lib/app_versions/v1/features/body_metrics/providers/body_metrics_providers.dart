import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/body_metrics_ai_service.dart';
import '../data/datasources/body_metrics_local_datasource.dart';
import '../data/repositories/body_metrics_repository_impl.dart';
import '../domain/entities/body_metrics_personal_context.dart';
import '../domain/repositories/body_metrics_repository.dart';

final bodyMetricsLocalDatasourceProvider = Provider<BodyMetricsLocalDatasource>(
  (ref) => BodyMetricsLocalDatasource(),
);

final bodyMetricsRepositoryProvider = Provider<BodyMetricsRepository>((ref) {
  return BodyMetricsRepositoryImpl(
    datasource: ref.watch(bodyMetricsLocalDatasourceProvider),
  );
});

final bodyMetricsPersonalContextProvider =
    FutureProvider.autoDispose<BodyMetricsPersonalContext?>((ref) {
      return ref.watch(bodyMetricsRepositoryProvider).loadPersonalContext();
    });

final bodyMetricsAiServiceProvider = Provider<BodyMetricsAiService>(
  (ref) => const BodyMetricsAiService(),
);
