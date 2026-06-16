import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/datasources/daily_health_tracking_local_datasource.dart';
import '../domain/repositories/daily_health_tracking_repository.dart';
import '../domain/repositories/daily_health_tracking_repository_impl.dart';
import '../presentation/controllers/daily_health_tracking_controller.dart';
import '../presentation/controllers/daily_health_tracking_state.dart';

final dailyHealthTrackingLocalDatasourceProvider =
    Provider<DailyHealthTrackingLocalDatasource>((ref) {
      return const DailyHealthTrackingLocalDatasource();
    });

final dailyHealthTrackingRepositoryProvider =
    Provider<DailyHealthTrackingRepository>((ref) {
      return DailyHealthTrackingRepositoryImpl(
        datasource: ref.read(dailyHealthTrackingLocalDatasourceProvider),
      );
    });

final dailyHealthTrackingControllerProvider =
    AsyncNotifierProvider<
      DailyHealthTrackingController,
      DailyHealthTrackingState
    >(DailyHealthTrackingController.new);
