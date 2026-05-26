import 'package:nano_app/core/storage/localdb/models/meal_plan_model.dart';
import 'package:nano_app/features/meal_plan/dashboard/data/datasources/meal_datasource.dart';
import 'package:nano_app/features/meal_plan/dashboard/domain/repositories/meal_plan_repository.dart';

class MealPlanRepositoryImpl implements MealPlanRepository {
  final MealPlanDatasource datasource;
  MealPlanRepositoryImpl({
    required this.datasource,
  });

  @override
  Future<List<MealPlanModel>> getMealByWeeks() {
    return datasource.getMealByWeeks();
  }
}

