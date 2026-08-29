import 'package:nano_app/app_versions/v1/features/daily_health_tracking/domain/repositories/daily_health_tracking_repository.dart';
import 'package:nano_app/core/access/local_subject_resolver.dart';
import 'package:nano_app/core/storage/localdb/daos/health_tracking_logs_dao.dart';
import 'package:nano_app/core/storage/localdb/database_service.dart';

import '../domain/water_tracking_repository.dart';
import 'water_tracking_local_store.dart';

/// Production repository: the user-selected target remains a local preference,
/// while the consumed amount uses the canonical health_tracking_logs writer so
/// Dashboard, Nutrition, Body Metrics and NaBi read the same hydration value.
final class IntegratedWaterTrackingRepository implements WaterTrackingRepository {
  final WaterTrackingLocalStore localStore;
  final DailyHealthTrackingRepository dailyHealthRepository;
  final LocalSubjectResolver subjectResolver;

  const IntegratedWaterTrackingRepository({
    required this.localStore,
    required this.dailyHealthRepository,
    required this.subjectResolver,
  });

  @override
  Future<WaterTrackingSnapshot> load(DateTime localDay) async {
    final local = await localStore.load(localDay);
    final subjectId = await subjectResolver.resolve();
    final db = await DatabaseService.database;
    final tracking = await HealthTrackingLogsDao(db).getByUserAndDate(
      userId: subjectId,
      logDate: _dateKey(localDay),
    );
    return WaterTrackingSnapshot(
      targetMl: local.targetMl,
      amountMl: tracking?.waterMl ?? 0,
    );
  }

  @override
  Future<void> saveTargetMl(int targetMl) => localStore.saveTargetMl(targetMl);

  @override
  Future<void> saveAmountMl(DateTime localDay, int amountMl) {
    // WaterTrackingPage writes the active local day only. DailyHealthTracking
    // owns the canonical today-row upsert and preserves the other metrics.
    return dailyHealthRepository.setTodayWater(amountMl);
  }
}

/// Local-only adapter retained for injected/offline stores and focused widget
/// tests. Production composition uses [IntegratedWaterTrackingRepository].
final class LocalOnlyWaterTrackingRepository implements WaterTrackingRepository {
  final WaterTrackingLocalStore localStore;

  const LocalOnlyWaterTrackingRepository(this.localStore);

  @override
  Future<WaterTrackingSnapshot> load(DateTime localDay) =>
      localStore.load(localDay);

  @override
  Future<void> saveTargetMl(int targetMl) => localStore.saveTargetMl(targetMl);

  @override
  Future<void> saveAmountMl(DateTime localDay, int amountMl) =>
      localStore.saveAmountMl(localDay, amountMl);
}

String _dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
