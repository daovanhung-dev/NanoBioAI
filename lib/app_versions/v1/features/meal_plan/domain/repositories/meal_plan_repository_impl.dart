import 'package:nano_app/app_versions/v1/features/meal_plan/data/datasources/meal_plan_local_datasource.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/entities/meal_plan_entity.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/entities/meal_replacement_entities.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/repositories/meal_plan_repository.dart';
import 'package:nano_app/app_versions/v1/services/notifications/notification_bootstrap.dart';
import 'package:nano_app/services/supabase/auth/current_auth_user.dart';
import 'package:nano_app/services/supabase/cloud_sync/user_data_sync_outbox.dart';

typedef MealReplacementSyncCallback = Future<MealReplacementSyncStatus>
    Function();
typedef MealPlanSubjectIdResolver = Future<String> Function();

class MealPlanRepositoryImpl implements MealPlanRepository {
  MealPlanRepositoryImpl({
    required this.datasource,
    this.resolveSubjectId,
    Future<void> Function()? refreshReminders,
    MealReplacementSyncCallback? syncPendingChanges,
  }) : refreshReminders =
           refreshReminders ?? NotificationBootstrap.scheduleGeneratedReminders,
       syncPendingChanges =
           syncPendingChanges ?? _syncPendingUserDataAfterReplacement;

  final MealPlanLocalDatasource datasource;
  final MealPlanSubjectIdResolver? resolveSubjectId;
  final Future<void> Function() refreshReminders;
  final MealReplacementSyncCallback syncPendingChanges;

  @override
  Future<List<MealPlanEntity>> getMealByWeeks() async {
    return datasource.getMealEntitiesByWeeks(
      userId: await _subjectIdOrNull(),
    );
  }

  @override
  Future<void> completeMealById(String id) async {
    return datasource.completeMealById(
      id,
      userId: await _subjectIdOrNull(),
    );
  }

  @override
  Future<List<MealReplacementCandidateEntity>> getReplacementCandidates(
    String mealId,
  ) async {
    return datasource.getReplacementCandidates(
      mealId,
      userId: await _subjectIdOrNull(),
    );
  }

  @override
  Future<MealReplacementResult> replaceMealByCatalogCode({
    required String mealId,
    required String catalogCode,
  }) async {
    final updated = await datasource.replaceMealByCatalogCode(
      mealId: mealId,
      catalogCode: catalogCode,
      userId: await _subjectIdOrNull(),
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
    final userId = await _subjectIdOrNull();
    final candidates = await datasource.getReplacementCandidates(
      id,
      userId: userId,
    );
    if (candidates.isEmpty) {
      throw const NoMealReplacementAvailableException();
    }
    final updated = await datasource.replaceMealByCatalogCode(
      mealId: id,
      catalogCode: candidates.first.code,
      userId: userId,
    );
    await refreshReminders();

    try {
      await syncPendingChanges();
    } catch (_) {
      // Replacement is already durable locally. Sync will retry through the
      // normal outbox path.
    }
    return updated;
  }

  Future<String?> _subjectIdOrNull() async {
    final resolver = resolveSubjectId;
    return resolver == null ? null : resolver();
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
