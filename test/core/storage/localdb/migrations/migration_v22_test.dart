import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/migrations/migration_v22.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  test('migration v22 creates local-only Food Scan tables', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);

    await db.execute('CREATE TABLE users (id TEXT PRIMARY KEY)');
    await db.insert('users', {'id': 'user-1'});
    await MigrationV22.run(db);

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name LIKE 'food_scan_%' ORDER BY name",
    );
    expect(
      tables.map((row) => row['name']).toList(),
      ['food_scan_analyses', 'food_scan_items'],
    );

    await db.insert('food_scan_analyses', {
      'id': 'scan-1',
      'user_id': 'user-1',
      'image_local_path': '/local/food.jpg',
      'result_json': '{}',
      'created_at': '2026-08-24T00:00:00Z',
      'updated_at': '2026-08-24T00:00:00Z',
    });
    final rows = await db.query('food_scan_analyses');
    expect(rows.single['user_id'], 'user-1');
  });
}
