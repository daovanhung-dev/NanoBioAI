import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/data/datasources/meal_plan_local_datasource.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/entities/meal_plan_entity.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/entities/meal_replacement_entities.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/repositories/meal_plan_repository_impl.dart';

void main() {
  test('manual replacement awaits sync and reports pending without rolling back', () async {
    var reminderRefreshes = 0;
    var syncCalls = 0;
    final repository = MealPlanRepositoryImpl(
      datasource: const _FakeReplacementDatasource(),
      refreshReminders: () async {
        reminderRefreshes++;
      },
      syncPendingChanges: () async {
        syncCalls++;
        return MealReplacementSyncStatus.pending;
      },
    );

    final result = await repository.replaceMealByCatalogCode(
      mealId: 'meal-1',
      catalogCode: 'meal-new',
    );

    expect(result.meal.catalogCode, 'meal-new');
    expect(result.syncStatus, MealReplacementSyncStatus.pending);
    expect(reminderRefreshes, 1);
    expect(syncCalls, 1);
  });
}

class _FakeReplacementDatasource extends MealPlanLocalDatasource {
  const _FakeReplacementDatasource();

  @override
  Future<MealPlanEntity> replaceMealByCatalogCode({
    required String mealId,
    required String catalogCode,
  }) async {
    return MealPlanEntity(
      id: mealId,
      userId: 'user-1',
      planDate: '2026-08-16',
      mealType: 'breakfast',
      mealName: 'Món mới',
      description: 'Mô tả',
      calories: 300,
      protein: 10,
      carbs: 40,
      fat: 8,
      fiber: 4,
      waterMl: 200,
      mealOrder: 1,
      catalogCode: catalogCode,
      isCompleted: false,
      aiGenerated: true,
      createdAt: '2026-08-16T00:00:00Z',
      updatedAt: '2026-08-16T00:00:00Z',
    );
  }
}
