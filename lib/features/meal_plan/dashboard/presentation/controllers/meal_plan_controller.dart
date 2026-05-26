import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/storage/localdb/models/meal_plan_model.dart';
import 'package:nano_app/features/meal_plan/dashboard/data/datasources/meal_datasource.dart';
import 'package:nano_app/features/meal_plan/dashboard/domain/repositories/meal_plan_repository_impl.dart';



final mealDataSource = Provider<MealPlanDatasource>((ref) {
  return const MealPlanDatasource();
});

final mealPlanRepositoryProvider = Provider<MealPlanRepositoryImpl>((ref) {
  return MealPlanRepositoryImpl(
    datasource: ref.read(mealDataSource),
  );
});

final mealPlanControllerProvider =
    AsyncNotifierProvider<MealPlanController, List<MealPlanModel>>(
  MealPlanController.new,
);

class MealPlanController extends AsyncNotifier<List<MealPlanModel>> {
  late final MealPlanRepositoryImpl _repository;

  @override
  Future<List<MealPlanModel>> build() async {
    _repository = ref.read(mealPlanRepositoryProvider);
    return _fetchMealPlans();
  }

  Future<List<MealPlanModel>> _fetchMealPlans() async {
    return await _repository.getMealByWeeks();
  }

  Future<void> refreshMealPlans() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchMealPlans());
  }
}