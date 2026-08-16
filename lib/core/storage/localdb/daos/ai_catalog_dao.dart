import 'package:sqflite/sqflite.dart';

import '../models/ai_catalog_models.dart';
import '../tables/exercise_catalog_table.dart';
import '../tables/meal_catalog_table.dart';
import '../tables/schedule_task_catalog_table.dart';

class AiCatalogDao {
  final Database db;

  const AiCatalogDao(this.db);

  Future<AiCatalogBundle> loadActiveBundle() async {
    final meals = await getActiveMeals(planEligibleOnly: false);
    final exercises = await getActiveExercises();
    final scheduleTasks = await getActiveScheduleTasks();
    return AiCatalogBundle(
      meals: meals,
      exercises: exercises,
      scheduleTasks: scheduleTasks,
    );
  }

  Future<List<MealCatalogItemModel>> getActiveMeals({
    String? mealType,
    bool planEligibleOnly = false,
  }) async {
    final clauses = <String>['is_active = ?'];
    final arguments = <Object?>[1];
    if (planEligibleOnly) {
      clauses.add('is_plan_eligible = ?');
      arguments.add(1);
    }
    if (mealType != null && mealType.trim().isNotEmpty) {
      final normalizedType = mealType.trim().toLowerCase();
      clauses.add('(meal_type = ? OR meal_type = ?)');
      arguments
        ..add(normalizedType)
        ..add('unclassified');
    }
    final maps = await db.query(
      MealCatalogTable.tableName,
      where: clauses.join(' AND '),
      whereArgs: arguments,
      orderBy: 'meal_type ASC, code ASC',
    );
    return maps.map(MealCatalogItemModel.fromMap).toList(growable: false);
  }

  Future<MealCatalogItemModel?> getMealByCode(String code) async {
    final rows = await db.query(
      MealCatalogTable.tableName,
      where: 'code = ? AND is_active = ?',
      whereArgs: [code, 1],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return MealCatalogItemModel.fromMap(rows.first);
  }

  Future<List<MealCatalogItemModel>> getSourceRecipesForTopic(
    String topicCode,
  ) async {
    final rows = await db.query(
      MealCatalogTable.tableName,
      where: 'health_topic_code = ? AND is_active = ?',
      whereArgs: [topicCode, 1],
      orderBy: 'source_recipe_order ASC, code ASC',
    );
    return rows.map(MealCatalogItemModel.fromMap).toList(growable: false);
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

  Future<void> replaceMeals(List<MealCatalogItemModel> items) async {
    await db.transaction((txn) async {
      await txn.delete(MealCatalogTable.tableName);
      if (items.isEmpty) return;

      final batch = txn.batch();
      for (final item in items) {
        batch.insert(
          MealCatalogTable.tableName,
          item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
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
