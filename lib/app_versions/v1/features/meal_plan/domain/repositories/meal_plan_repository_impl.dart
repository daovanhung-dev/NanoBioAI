import 'package:nano_app/app_versions/v1/features/meal_plan/data/datasources/meal_plan_local_datasource.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/entities/meal_plan_entity.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/repositories/meal_plan_repository.dart';
import 'package:nano_app/app_versions/v1/services/notifications/notification_bootstrap.dart';

class MealPlanRepositoryImpl implements MealPlanRepository {
  MealPlanRepositoryImpl({
    required this.datasource,
    Future<void> Function()? refreshReminders,
  }) : refreshReminders =
           refreshReminders ?? NotificationBootstrap.scheduleGeneratedReminders;

  final MealPlanLocalDatasource datasource;
  final Future<void> Function() refreshReminders;

  @override
  Future<List<MealPlanEntity>> getMealByWeeks() async {
    final meals = await datasource.getMealByWeeks();
    return meals.map((meal) => meal.toEntity()).toList();
  }

  @override
  Future<void> completeMealById(String id) {
    return datasource.completeMealById(id);
  }

  @override
  Future<MealPlanEntity> replaceMealById(String id) async {
    final updated = await datasource.replaceMealById(id);
    await refreshReminders();
    return updated;
  }
}
