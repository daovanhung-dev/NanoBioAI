import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/migrations/migration_manager.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
  });

  tearDown(() async {
    await db.close();
  });

  test('migration v3 adds cooking instructions to meal plans once', () async {
    await db.execute('''
      CREATE TABLE meal_plans (
        id TEXT PRIMARY KEY,
        meal_name TEXT
      )
    ''');

    await MigrationManager.runMigrations(db, 2, 3);
    await MigrationManager.runMigrations(db, 2, 3);

    final columns = await db.rawQuery('PRAGMA table_info(meal_plans)');
    final names = columns.map((column) => column['name']).toList();

    expect(names, contains('cooking_instructions'));
    expect(names.where((name) => name == 'cooking_instructions'), hasLength(1));
  });
}
