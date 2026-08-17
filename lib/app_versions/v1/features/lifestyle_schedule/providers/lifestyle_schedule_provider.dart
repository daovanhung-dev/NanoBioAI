import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/services/notifications/notification_bootstrap.dart';
import 'package:nano_app/services/image_picker/image_picker_provider.dart';

import '../application/schedule_health_checkin_reward_gateway.dart';
import '../application/schedule_proof_image_service.dart';
import '../application/schedule_reward_eligibility_projection_store.dart';
import '../application/schedule_reward_eligibility_reconciler.dart';
import '../application/schedule_reward_online_gateway.dart';
import '../data/datasources/daily_health_hub_local_datasource.dart';
import '../data/datasources/lifestyle_schedule_local_datasource.dart';
import '../data/repositories/daily_health_hub_repository_impl.dart';
import '../domain/entities/daily_health_snapshot_entity.dart';
import '../domain/repositories/daily_health_hub_repository.dart';
import '../domain/repositories/lifestyle_schedule_repository.dart';
import '../domain/repositories/lifestyle_schedule_repository_impl.dart';
import '../domain/services/lifestyle_schedule_window_policy.dart';
import '../presentation/controllers/daily_health_hub_controller.dart';
import '../presentation/controllers/lifestyle_schedule_controller.dart';
import '../presentation/controllers/lifestyle_schedule_state.dart';

final lifestyleScheduleClockProvider = Provider<DateTime Function()>((ref) {
  return LifestyleScheduleWindowPolicy.vietnamNow;
});

final lifestyleScheduleLocalDatasourceProvider =
    Provider<LifestyleScheduleLocalDatasource>((ref) {
  return LifestyleScheduleLocalDatasource();
});

final lifestyleScheduleRepositoryProvider =
    Provider<LifestyleScheduleRepository>((ref) {
  return LifestyleScheduleRepositoryImpl(
    datasource: ref.read(lifestyleScheduleLocalDatasourceProvider),
  );
});

final scheduleProofImageServiceProvider = Provider<ScheduleProofImageService>((
  ref,
) {
  return ScheduleProofImageService(
    imagePickerService: ref.read(imagePickerServiceProvider),
  );
});

final scheduleRewardOnlineGatewayProvider =
    Provider<ScheduleRewardOnlineGateway>((ref) {
  return const SupabaseScheduleRewardOnlineGateway();
});

final scheduleRewardEligibilityProjectionStoreProvider =
    Provider<ScheduleRewardEligibilityProjectionStore>((ref) {
  return const SqliteScheduleRewardEligibilityProjectionStore();
});

final scheduleRewardEligibilityReconcilerProvider =
    Provider<ScheduleRewardEligibilityReconciler>((ref) {
  return ScheduleRewardEligibilityReconciler(
    gateway: ref.watch(scheduleRewardOnlineGatewayProvider),
    projectionStore: ref.watch(
      scheduleRewardEligibilityProjectionStoreProvider,
    ),
  );
});

final lifestyleScheduleControllerProvider =
    AsyncNotifierProvider<LifestyleScheduleController, LifestyleScheduleState>(
  LifestyleScheduleController.new,
);

final dailyHealthHubLocalDatasourceProvider =
    Provider<DailyHealthHubLocalDatasource>((ref) {
  return DailyHealthHubLocalDatasource(
    now: ref.watch(lifestyleScheduleClockProvider),
  );
});

final dailyHealthHubRepositoryProvider = Provider<DailyHealthHubRepository>((
  ref,
) {
  return DailyHealthHubRepositoryImpl(
    datasource: ref.watch(dailyHealthHubLocalDatasourceProvider),
  );
});

final scheduleHealthCheckInRewardGatewayProvider =
    Provider<ScheduleHealthCheckInRewardGateway>((ref) {
  return const SupabaseScheduleHealthCheckInRewardGateway();
});

final dailyHealthSnapshotProvider =
    FutureProvider.autoDispose.family<DailyHealthSnapshotEntity, DateTime>((
  ref,
  date,
) {
  return ref.watch(dailyHealthHubRepositoryProvider).getSnapshot(date);
});

final dailyHealthHubControllerProvider = Provider<DailyHealthHubController>((
  ref,
) {
  return DailyHealthHubController(
    repository: ref.watch(dailyHealthHubRepositoryProvider),
    rewardGateway: ref.watch(scheduleHealthCheckInRewardGatewayProvider),
    refreshSchedule: () async {
      await ref.read(lifestyleScheduleControllerProvider.notifier).refresh();
    },
    rescheduleReminders: () => NotificationBootstrap.scheduleGeneratedReminders(),
    invalidateSnapshot: (date) {
      ref.invalidate(dailyHealthSnapshotProvider(date));
    },
  );
});
