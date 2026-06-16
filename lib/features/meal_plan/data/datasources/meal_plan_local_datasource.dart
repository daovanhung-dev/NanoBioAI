import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:sqflite/sqflite.dart';

import '../daos/meal_plan_dao.dart';
import '../models/meal_plan_model.dart';

class MealPlanLocalDatasource {
  const MealPlanLocalDatasource();

  Future<Database> _db() async {
    return DatabaseService.database;
  }

  Future<List<MealPlanModel>> getMealByWeeks() async {
    final db = await _db();
    final daoMealPlans = MealPlansDao(db);
    return daoMealPlans.getAll();
  }
}
