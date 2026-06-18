import 'package:sqflite/sqflite.dart';

import '../models/ai_catalog_models.dart';
import '../tables/exercise_catalog_table.dart';
import '../tables/meal_catalog_table.dart';
import '../tables/schedule_task_catalog_table.dart';

class AiCatalogDao {
  final Database db;

  const AiCatalogDao(this.db);

  Future<AiCatalogBundle> loadActiveBundle() async {
    final meals = await getActiveMeals();
    final exercises = await getActiveExercises();
    final scheduleTasks = await getActiveScheduleTasks();
    return AiCatalogBundle(
      meals: meals,
      exercises: exercises,
      scheduleTasks: scheduleTasks,
    );
  }

  Future<List<MealCatalogItemModel>> getActiveMeals({String? mealType}) async {
    final maps = await db.query(
      MealCatalogTable.tableName,
      where: mealType == null
          ? 'is_active = ?'
          : 'is_active = ? AND meal_type = ?',
      whereArgs: mealType == null ? const [1] : [1, mealType],
      orderBy: 'meal_type ASC, code ASC',
    );
    return maps.map(MealCatalogItemModel.fromMap).toList();
  }

  Future<List<ExerciseCatalogItemModel>> getActiveExercises() async {
    final maps = await db.query(
      ExerciseCatalogTable.tableName,
      where: 'is_active = ?',
      whereArgs: const [1],
      orderBy: 'code ASC',
    );
    return maps.map(ExerciseCatalogItemModel.fromMap).toList();
  }

  Future<List<ScheduleTaskCatalogItemModel>> getActiveScheduleTasks() async {
    final maps = await db.query(
      ScheduleTaskCatalogTable.tableName,
      where: 'is_active = ?',
      whereArgs: const [1],
      orderBy: 'sort_order ASC, code ASC',
    );
    return maps.map(ScheduleTaskCatalogItemModel.fromMap).toList();
  }

  Future<void> upsertMeals(List<MealCatalogItemModel> items) async {
    final batch = db.batch();
    for (final item in items) {
      batch.insert(
        MealCatalogTable.tableName,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> upsertExercises(List<ExerciseCatalogItemModel> items) async {
    final batch = db.batch();
    for (final item in items) {
      batch.insert(
        ExerciseCatalogTable.tableName,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> upsertScheduleTasks(
    List<ScheduleTaskCatalogItemModel> items,
  ) async {
    final batch = db.batch();
    for (final item in items) {
      batch.insert(
        ScheduleTaskCatalogTable.tableName,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }
}
