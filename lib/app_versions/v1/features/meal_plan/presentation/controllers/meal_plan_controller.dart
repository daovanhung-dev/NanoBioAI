import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/entities/meal_plan_entity.dart';
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

  Future<List<MealPlanEntity>> _fetchMealPlans() async {
    return await _repository.getMealByWeeks();
  }

  Future<void> refreshMealPlans() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchMealPlans());
  }
}
