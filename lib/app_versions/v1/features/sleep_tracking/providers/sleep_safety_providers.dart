import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/datasources/sleep_safety_cloud_datasource.dart';
import '../data/datasources/sleep_safety_local_datasource.dart';
import '../data/datasources/sleep_safety_reminder_service.dart';
import '../data/gateways/sleep_safety_native_gateway.dart';
import '../data/gateways/sleep_safety_notification_permission_gateway.dart';
import '../data/repositories/sleep_safety_repository_impl.dart';
import '../domain/repositories/sleep_safety_repository.dart';
import 'sleep_safety_controller.dart';

final sleepSafetyLocalDatasourceProvider = Provider<SleepSafetyLocalDatasource>(
  (ref) => const SleepSafetyLocalDatasource(),
);

final sleepSafetyCloudDatasourceProvider = Provider<SleepSafetyCloudDatasource>(
  (ref) => const SleepSafetyCloudDatasource(),
);

final sleepSafetyNativeGatewayProvider = Provider<SleepSafetyNativeGateway>(
  (ref) => const MethodChannelSleepSafetyNativeGateway(),
);

final sleepSafetyNotificationPermissionGatewayProvider =
    Provider<SleepSafetyNotificationPermissionGateway>(
  (ref) => const LocalSleepSafetyNotificationPermissionGateway(),
);

final sleepSafetyReminderServiceProvider = Provider<SleepSafetyReminderService>(
  (ref) => const SleepSafetyReminderService(),
);

final sleepSafetyRepositoryProvider = Provider<SleepSafetyRepository>((ref) {
  return SleepSafetyRepositoryImpl(
    local: ref.watch(sleepSafetyLocalDatasourceProvider),
    cloud: ref.watch(sleepSafetyCloudDatasourceProvider),
    native: ref.watch(sleepSafetyNativeGatewayProvider),
  );
});

final sleepSafetyRolloutProvider = FutureProvider<bool>((ref) {
  return ref.watch(sleepSafetyRepositoryProvider).isRolloutEnabled();
});

/// Synchronous fail-closed view of the rollout state already resolved by the
/// access gate. Reading this provider never initiates a second rollout request
/// while [sleepSafetyRolloutProvider] already contains its resolved value.
final sleepSafetyRolloutApprovedProvider = Provider<bool>((ref) {
  return ref.watch(sleepSafetyRolloutProvider).asData?.value ?? false;
});

/// Injectable M31-only permission boundary. It never requests exact-alarm
/// access, so starting microphone monitoring cannot unexpectedly send the user
/// to Special App Access immediately before foreground-service creation.
final sleepSafetyNotificationPermissionProvider =
    Provider<Future<bool> Function()>((ref) {
  final gateway = ref.watch(sleepSafetyNotificationPermissionGatewayProvider);
  return gateway.requestPermission;
});

final sleepSafetyControllerProvider =
    NotifierProvider<SleepSafetyController, SleepSafetyViewState>(
  SleepSafetyController.new,
);
