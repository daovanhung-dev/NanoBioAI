import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/storage/localdb/models/meal_plan_model.dart';
import 'package:nano_app/features/meal_plan/dashboard/data/datasources/meal_datasource.dart';

import '../domain/repositories/meal_plan_repository_impl.dart';

final mealDataSource = Provider<MealPlanDatasource>((ref) {
  return const MealPlanDatasource();
});

final mealPlanRepositoryProvider = Provider<MealPlanRepositoryImpl>((ref) {
  return MealPlanRepositoryImpl(
    datasource: ref.read(mealDataSource),
  );
});

final getMealPlanProvider = FutureProvider<List<MealPlanModel>>((ref) async {
  final repository = ref.read(mealPlanRepositoryProvider);
  return repository.getMealByWeeks();
});