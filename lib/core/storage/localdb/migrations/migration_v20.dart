import 'package:sqflite/sqflite.dart';

/// Repairs legacy rows that violate declared foreign-key contracts before
/// runtime foreign-key enforcement is enabled permanently.
class MigrationV20 {
  const MigrationV20._();

  static Future<void> run(Database db) async {
    await _removeForeignKeyOrphans(db);
    await assertIntegrity(db);
  }

  static Future<void> assertIntegrity(DatabaseExecutor db) async {
    final violations = await db.rawQuery('PRAGMA foreign_key_check');
    if (violations.isNotEmpty) {
      throw StateError(
        'SQLite foreign-key integrity check failed after migration v20.',
      );
    }
  }

  static Future<void> _removeForeignKeyOrphans(Database db) async {
    final violations = await db.rawQuery('PRAGMA foreign_key_check');
    for (final violation in violations) {
      final table = violation['table']?.toString().trim() ?? '';
      final rowId = violation['rowid'];
      if (!_isSafeIdentifier(table) || rowId == null) {
        continue;
      }
      await db.delete(table, where: 'rowid = ?', whereArgs: [rowId]);
    }
  }

  static bool _isSafeIdentifier(String value) {
    return RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(value);
  }
}
