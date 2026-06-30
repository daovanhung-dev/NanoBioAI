import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:nano_app/core/storage/localdb/sync/local_user_data_sync_dispatcher.dart';
import 'package:sqflite/sqflite.dart';

import '../daos/meal_plan_dao.dart';
import '../models/meal_plan_model.dart';

class MealPlanLocalDatasource {
  final Database? databaseOverride;

  const MealPlanLocalDatasource({this.databaseOverride});

  Future<Database> _db() async {
    return databaseOverride ?? DatabaseService.database;
  }

  Future<List<MealPlanModel>> getMealByWeeks() async {
    final db = await _db();
    final daoMealPlans = MealPlansDao(db);
    return daoMealPlans.getAll();
  }

  Future<void> completeMealById(String id) async {
    final db = await _db();
    final daoMealPlans = MealPlansDao(db);
    await daoMealPlans.updateCompleted(id: id, isCompleted: true);
    LocalUserDataSyncDispatcher.requestImmediateSync(database: db);
  }
}
