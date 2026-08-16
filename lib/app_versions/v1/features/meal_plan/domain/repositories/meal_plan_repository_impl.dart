import 'package:nano_app/app_versions/v1/features/meal_plan/data/datasources/meal_plan_local_datasource.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/entities/meal_plan_entity.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/entities/meal_replacement_entities.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/repositories/meal_plan_repository.dart';
import 'package:nano_app/app_versions/v1/services/notifications/notification_bootstrap.dart';
import 'package:nano_app/services/supabase/auth/current_auth_user.dart';
import 'package:nano_app/services/supabase/cloud_sync/user_data_sync_outbox.dart';

typedef MealReplacementSyncCallback = Future<MealReplacementSyncStatus>
    Function();

class MealPlanRepositoryImpl implements MealPlanRepository {
  MealPlanRepositoryImpl({
    required this.datasource,
    Future<void> Function()? refreshReminders,
    MealReplacementSyncCallback? syncPendingChanges,
  }) : refreshReminders =
           refreshReminders ?? NotificationBootstrap.scheduleGeneratedReminders,
       syncPendingChanges =
           syncPendingChanges ?? _syncPendingUserDataAfterReplacement;

  final MealPlanLocalDatasource datasource;
  final Future<void> Function() refreshReminders;
  final MealReplacementSyncCallback syncPendingChanges;

  @override
  Future<List<MealPlanEntity>> getMealByWeeks() {
    return datasource.getMealEntitiesByWeeks();
  }

  @override
  Future<void> completeMealById(String id) {
    return datasource.completeMealById(id);
  }

  @override
  Future<List<MealReplacementCandidateEntity>> getReplacementCandidates(
    String mealId,
  ) {
    return datasource.getReplacementCandidates(mealId);
  }

  @override
  Future<MealReplacementResult> replaceMealByCatalogCode({
    required String mealId,
    required String catalogCode,
  }) async {
    final updated = await datasource.replaceMealByCatalogCode(
      mealId: mealId,
      catalogCode: catalogCode,
    );
    await refreshReminders();

    MealReplacementSyncStatus syncStatus;
    try {
      syncStatus = await syncPendingChanges();
    } catch (_) {
      syncStatus = MealReplacementSyncStatus.pending;
    }

    return MealReplacementResult(meal: updated, syncStatus: syncStatus);
  }

  @override
  @Deprecated('Use getReplacementCandidates + replaceMealByCatalogCode.')
  Future<MealPlanEntity> replaceMealById(String id) async {
    final candidates = await getReplacementCandidates(id);
    if (candidates.isEmpty) {
      throw const NoMealReplacementAvailableException();
    }
    final result = await replaceMealByCatalogCode(
      mealId: id,
      catalogCode: candidates.first.code,
    );
    return result.meal;
  }

  static Future<MealReplacementSyncStatus>
  _syncPendingUserDataAfterReplacement() async {
    final userId = currentSupabaseUserIdOrNull();
    if (userId == null || userId.trim().isEmpty) {
      return MealReplacementSyncStatus.localOnly;
    }

    await UserDataSyncOutbox.drainForCurrentUser();
    final pending = await UserDataSyncOutbox.shared.pendingCountForCurrentUser();
    return pending == 0
        ? MealReplacementSyncStatus.synced
        : MealReplacementSyncStatus.pending;
  }
}
