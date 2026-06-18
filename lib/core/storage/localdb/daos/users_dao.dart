import 'package:sqflite/sqflite.dart';

import '../models/user_model.dart';

class UsersDao {
  static const tableName = 'users';

  final Database db;
  UsersDao(this.db);

  Future<void> insert(UserModel model) async {
    await db.insert(
      tableName,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertMany(List<UserModel> models) async {
    if (models.isEmpty) return;
    final batch = db.batch();
    for (final model in models) {
      batch.insert(
        tableName,
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<UserModel>> getAll() async {
    final maps = await db.query(tableName, orderBy: defaultOrderBy);
    return maps.map(UserModel.fromMap).toList();
  }

  Future<UserModel?> getById(String id) async {
    final maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  Future<UserModel?> getLatest() async {
    final maps = await db.query(tableName, orderBy: defaultOrderBy, limit: 1);
    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  Future<UserModel?> getByEmailOrPhone({String? email, String? phone}) async {
    final conditions = <String>[];
    final args = <Object?>[];
    if (email != null && email.trim().isNotEmpty) {
      conditions.add('email = ?');
      args.add(email.trim());
    }
    if (phone != null && phone.trim().isNotEmpty) {
      conditions.add('phone = ?');
      args.add(phone.trim());
    }
    if (conditions.isEmpty) return null;
    final maps = await db.query(
      tableName,
      where: conditions.join(' OR '),
      whereArgs: args,
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  Future<void> update(UserModel model) async {
    await db.update(
      tableName,
      model.toMap(),
      where: 'id = ?',
      whereArgs: [model.id],
    );
  }

  Future<void> delete(String id) async {
    await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  String get defaultOrderBy => 'created_at DESC';
}
