import 'package:sqflite/sqflite.dart';

import '../models/lifestyle_habit_model.dart';

class LifestyleHabitsDao {
  final Database db;

  LifestyleHabitsDao(this.db);

  Future<void> insert(
    LifestyleHabitModel model,
  ) async {
    // TODO: Insert data
  }

  Future<List<LifestyleHabitModel>> getAll() async {
    return [];
  }

  Future<void> update(
    LifestyleHabitModel model,
  ) async {
    // TODO: Update data
  }

  Future<void> delete(
    String id,
  ) async {
    // TODO: Delete data
  }
}