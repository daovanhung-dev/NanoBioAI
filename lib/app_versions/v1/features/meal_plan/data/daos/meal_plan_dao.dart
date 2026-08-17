import 'package:sqflite/sqflite.dart';

import '../models/meal_plan_model.dart';

class MealPlansDao {
  final DatabaseExecutor db;

  MealPlansDao(this.db);

  Future<void> insert(MealPlanModel model) async {
    await db.insert(
      'meal_plans',
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertMany(List<MealPlanModel> meals) async {
    final batch = db.batch();
    for (final meal in meals) {
      batch.insert(
        'meal_plans',
        meal.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Administrative/testing helper only. User-facing flows must use a
  /// user-scoped query.
  Future<List<MealPlanModel>> getAll() async {
    final maps = await db.query(
      'meal_plans',
      orderBy: 'plan_date ASC, meal_order ASC',
    );
    return maps.map(MealPlanModel.fromMap).toList();
  }

  Future<MealPlanModel?> getById(String id) async {
    final maps = await db.query(
      'meal_plans',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return MealPlanModel.fromMap(maps.first);
  }

  Future<MealPlanModel?> getByIdForUser({
    required String id,
    required String userId,
  }) async {
    final maps = await db.query(
      'meal_plans',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return MealPlanModel.fromMap(maps.first);
  }

  Future<List<MealPlanModel>> getByUserId(String userId) async {
    final maps = await db.query(
      'meal_plans',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'plan_date ASC, meal_order ASC',
    );
    return maps.map(MealPlanModel.fromMap).toList();
  }

  Future<List<MealPlanModel>> getByDate(String planDate) async {
    final maps = await db.query(
      'meal_plans',
      where: 'plan_date = ?',
      whereArgs: [planDate],
      orderBy: 'meal_order ASC',
    );
    return maps.map(MealPlanModel.fromMap).toList();
  }

  Future<List<MealPlanModel>> getByUserIdAndDateRange({
    required String userId,
    required String startDate,
    required String endDate,
  }) async {
    final maps = await db.query(
      'meal_plans',
      where: 'user_id = ? AND plan_date >= ? AND plan_date <= ?',
      whereArgs: [userId, startDate, endDate],
      orderBy: 'plan_date ASC, meal_order ASC',
    );
    return maps.map(MealPlanModel.fromMap).toList();
  }

  Future<void> update(MealPlanModel model) async {
    await db.update(
      'meal_plans',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [model.id],
    );
  }

  Future<void> updateCompleted({
    required String id,
    required bool isCompleted,
  }) async {
    await db.update(
      'meal_plans',
      {
        'is_completed': isCompleted ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateCompletedForUser({
    required String id,
    required String userId,
    required bool isCompleted,
  }) {
    return db.update(
      'meal_plans',
      {
        'is_completed': isCompleted ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  Future<void> delete(String id) async {
    await db.delete('meal_plans', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteByUserId(String userId) async {
    await db.delete('meal_plans', where: 'user_id = ?', whereArgs: [userId]);
  }

  Future<void> deleteByUserIdAndDateRange({
    required String userId,
    required String startDate,
    required String endDate,
  }) async {
    await db.delete(
      'meal_plans',
      where: 'user_id = ? AND plan_date >= ? AND plan_date <= ?',
      whereArgs: [userId, startDate, endDate],
    );
  }
}
