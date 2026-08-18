import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/providers/dashboard_dynamic_provider.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/providers/lifestyle_schedule_provider.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/entities/meal_plan_entity.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/entities/meal_replacement_entities.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/repositories/meal_plan_repository.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/providers/meal_plan_provider.dart';

final mealPlanControllerProvider =
    AsyncNotifierProvider<MealPlanController, List<MealPlanEntity>>(
      MealPlanController.new,
    );

final mealMutationDependentsInvalidatorProvider = Provider<void Function()>((ref) {
  return () {
    ref.invalidate(getMealPlanProvider);
    ref.invalidate(lifestyleScheduleControllerProvider);
    ref.invalidate(dashboardDynamicProvider);
  };
});

class MealPlanController extends AsyncNotifier<List<MealPlanEntity>> {
  late final MealPlanRepository _repository;

  @override
  Future<List<MealPlanEntity>> build() async {
    _repository = ref.read(mealPlanRepositoryProvider);
    return _fetchMealPlans();
  }

  Future<List<MealPlanEntity>> _fetchMealPlans() {
    return _repository.getMealByWeeks();
  }

  Future<void> refreshMealPlans() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchMealPlans);
  }

  Future<List<MealReplacementCandidateEntity>> loadReplacementCandidates(
    String mealId,
  ) {
    return _repository.getReplacementCandidates(mealId);
  }

  Future<MealReplacementResult> replaceMealByCatalogCode({
    required String mealId,
    required String catalogCode,
  }) async {
    final result = await _repository.replaceMealByCatalogCode(
      mealId: mealId,
      catalogCode: catalogCode,
    );
    await _refreshMealMutationDependents();
    return result;
  }

  @Deprecated('Use loadReplacementCandidates + replaceMealByCatalogCode.')
  Future<MealPlanEntity> replaceMealById(String id) async {
    final updated = await _repository.replaceMealById(id);
    await _refreshMealMutationDependents();
    return updated;
  }

  Future<void> _refreshMealMutationDependents() async {
    ref.read(mealMutationDependentsInvalidatorProvider)();
    state = await AsyncValue.guard(_fetchMealPlans);
  }
}
