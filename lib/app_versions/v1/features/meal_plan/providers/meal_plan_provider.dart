import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/data/datasources/meal_plan_local_datasource.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/entities/meal_plan_entity.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/repositories/meal_plan_repository.dart';

import '../domain/repositories/meal_plan_repository_impl.dart';

final mealPlanLocalDatasourceProvider = Provider<MealPlanLocalDatasource>((
  ref,
) {
  return const MealPlanLocalDatasource();
});

final mealPlanRepositoryProvider = Provider<MealPlanRepository>((ref) {
  return MealPlanRepositoryImpl(
    datasource: ref.read(mealPlanLocalDatasourceProvider),
  );
});

final getMealPlanProvider = FutureProvider<List<MealPlanEntity>>((ref) async {
  final repository = ref.read(mealPlanRepositoryProvider);
  return repository.getMealByWeeks();
});
