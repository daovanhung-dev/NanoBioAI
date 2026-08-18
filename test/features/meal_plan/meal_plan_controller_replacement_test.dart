import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/entities/meal_plan_entity.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/entities/meal_replacement_entities.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/repositories/meal_plan_repository.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/presentation/controllers/meal_plan_controller.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/providers/meal_plan_provider.dart';

void main() {
  test('successful replacement refreshes controller and dependent projections', () async {
    final repository = _FakeMealPlanRepository();
    var invalidationCalls = 0;
    final container = ProviderContainer(
      overrides: [
        mealPlanRepositoryProvider.overrideWithValue(repository),
        mealMutationDependentsInvalidatorProvider.overrideWithValue(
          () => invalidationCalls++,
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(mealPlanControllerProvider.future);
    final result = await container
        .read(mealPlanControllerProvider.notifier)
        .replaceMealByCatalogCode(mealId: 'meal-1', catalogCode: 'meal-b');

    expect(result.meal.mealName, 'Meal B');
    expect(invalidationCalls, 1);
    expect(
      container.read(mealPlanControllerProvider).value?.single.mealName,
      'Meal B',
    );
  });

  test('failed replacement does not invalidate dependent projections', () async {
    final repository = _FakeMealPlanRepository(throwOnReplace: true);
    var invalidationCalls = 0;
    final container = ProviderContainer(
      overrides: [
        mealPlanRepositoryProvider.overrideWithValue(repository),
        mealMutationDependentsInvalidatorProvider.overrideWithValue(
          () => invalidationCalls++,
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(mealPlanControllerProvider.future);
    await expectLater(
      container
          .read(mealPlanControllerProvider.notifier)
          .replaceMealByCatalogCode(mealId: 'meal-1', catalogCode: 'meal-b'),
      throwsStateError,
    );

    expect(invalidationCalls, 0);
  });
}

class _FakeMealPlanRepository implements MealPlanRepository {
  _FakeMealPlanRepository({this.throwOnReplace = false});

  final bool throwOnReplace;
  MealPlanEntity current = _meal('Meal A', 'meal-a');

  @override
  Future<void> completeMealById(String id) async {}

  @override
  Future<List<MealPlanEntity>> getMealByWeeks() async => [current];

  @override
  Future<List<MealReplacementCandidateEntity>> getReplacementCandidates(
    String mealId,
  ) async {
    return const [
      MealReplacementCandidateEntity(
        code: 'meal-b',
        mealType: 'breakfast',
        mealName: 'Meal B',
        description: 'Replacement',
        calories: 300,
        servingSize: '1 phần',
        healthTopicName: 'Cân bằng',
      ),
    ];
  }

  @override
  Future<MealReplacementResult> replaceMealByCatalogCode({
    required String mealId,
    required String catalogCode,
  }) async {
    if (throwOnReplace) throw StateError('replace failed');
    current = _meal('Meal B', catalogCode);
    return MealReplacementResult(
      meal: current,
      syncStatus: MealReplacementSyncStatus.localOnly,
    );
  }

  @override
  Future<MealPlanEntity> replaceMealById(String id) async {
    current = _meal('Meal B', 'meal-b');
    return current;
  }
}

MealPlanEntity _meal(String name, String code) {
  return MealPlanEntity(
    id: 'meal-1',
    userId: 'user-1',
    planDate: '2026-08-17',
    mealType: 'breakfast',
    mealName: name,
    description: 'Description',
    calories: 300,
    protein: 10,
    carbs: 40,
    fat: 8,
    fiber: 5,
    waterMl: 250,
    mealOrder: 1,
    catalogCode: code,
    isCompleted: false,
    aiGenerated: true,
    createdAt: '2026-08-17T00:00:00.000Z',
    updatedAt: '2026-08-17T00:00:00.000Z',
  );
}
