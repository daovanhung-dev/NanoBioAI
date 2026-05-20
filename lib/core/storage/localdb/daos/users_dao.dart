import 'package:sqflite/sqflite.dart';

import '../models/user_model.dart';

class UsersDao {
  final Database db;

  UsersDao(this.db);

  Future<void> insert(
    UserModel model,
  ) async {
    // TODO: Insert data
  }

  Future<List<UserModel>> getAll() async {
    return [];
  }

  Future<void> update(
    UserModel model,
  ) async {
    // TODO: Update data
  }

  Future<void> delete(
    String id,
  ) async {
    // TODO: Delete data
  }
}