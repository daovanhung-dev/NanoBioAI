import 'package:nano_app/core/storage/localdb/daos/meal_plan_dao.dart';
import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:nano_app/core/storage/localdb/models/meal_plan_model.dart';
import 'package:sqflite/sqflite.dart';

class MealPlanDatasource {
  const MealPlanDatasource();

  Future<Database> _db() async {
    return DatabaseService.database;
  }

  Future<List<MealPlanModel>> getMealByWeeks() async {
    final db = await _db();
    final daoMealPlans = MealPlansDao(db);
    return daoMealPlans.getAll();
  }
}