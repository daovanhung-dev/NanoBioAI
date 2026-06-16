// lib/features/dashboard/data/repositories/dashboard_repository_impl.dart
import 'package:nano_app/features/dashboard/data/datasources/dashboard_local_datasource.dart';
import 'package:nano_app/features/meal_plan/data/models/meal_plan_model.dart';
import '../../domain/entities/dashboard_entity.dart';
import '../../domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardLocalDatasource datasource;

  DashboardRepositoryImpl({required this.datasource});

  @override
  Future<DashboardEntity> fetchDashboard() {
    return datasource.fetchDashboard();
  }

  @override
  Future<void> saveMealPlan(List<MealPlanModel> mealPlans) {
    return datasource.saveMealPlan(mealPlans);
  }
}
