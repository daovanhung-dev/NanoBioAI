import 'package:nano_app/features/meal_plan/data/datasources/meal_plan_local_datasource.dart';
import 'package:nano_app/features/meal_plan/domain/entities/meal_plan_entity.dart';
import 'package:nano_app/features/meal_plan/domain/repositories/meal_plan_repository.dart';

class MealPlanRepositoryImpl implements MealPlanRepository {
  final MealPlanLocalDatasource datasource;
  MealPlanRepositoryImpl({required this.datasource});

  @override
  Future<List<MealPlanEntity>> getMealByWeeks() async {
    final meals = await datasource.getMealByWeeks();
    return meals.map((meal) => meal.toEntity()).toList();
  }

  @override
  Future<void> completeMealById(String id) {
    return datasource.completeMealById(id);
  }
}
