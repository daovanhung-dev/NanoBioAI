import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/entities/meal_plan_entity.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/entities/meal_replacement_entities.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/repositories/meal_plan_repository.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/providers/meal_plan_provider.dart';

final mealPlanControllerProvider =
    AsyncNotifierProvider<MealPlanController, List<MealPlanEntity>>(
      MealPlanController.new,
    );

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
    state = AsyncData(await _fetchMealPlans());
    return result;
  }

  @Deprecated('Use loadReplacementCandidates + replaceMealByCatalogCode.')
  Future<MealPlanEntity> replaceMealById(String id) async {
    final updated = await _repository.replaceMealById(id);
    state = AsyncData(await _fetchMealPlans());
    return updated;
  }
}
