import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/medication_reminders/data/repositories/sqlite_medication_reminder_repository.dart';
import 'package:nano_app/core/storage/localdb/migrations/migration_v34.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late SqliteMedicationReminderRepository repository;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
  });

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute('PRAGMA foreign_keys = ON');
    await db.execute('CREATE TABLE users (id TEXT PRIMARY KEY)');
    await MigrationV34.run(db);
    await db.insert('users', {'id': 'guest-1'});
    repository = SqliteMedicationReminderRepository(
      databaseOverride: db,
      now: () => DateTime(2026, 10, 15),
    );
    await db.insert('medication_reminders', {
      'id': 'med-1',
      'user_id': 'guest-1',
      'medicine_name': 'Medicine one',
      'times_json': '[480,900]',
      'enabled': 1,
      'created_at': '2026-10-15T00:00:00Z',
      'updated_at': '2026-10-15T00:00:00Z',
    });
  });

  tearDown(() => db.close());

  test(
    'edits times, pauses, resumes, and deletes only the local owner row',
    () async {
      expect((await repository.listForUser('guest-1')).single.reminderMinutes, [
        480,
        900,
      ]);

      await repository.updateTimes(
        userId: 'guest-1',
        reminderId: 'med-1',
        minutes: [1020, 540, 540],
      );
      var reminder = (await repository.listForUser('guest-1')).single;
      expect(reminder.reminderMinutes, [540, 1020]);

      await repository.setEnabled(
        userId: 'guest-1',
        reminderId: 'med-1',
        enabled: false,
      );
      expect((await repository.listForUser('guest-1')).single.enabled, isFalse);
      await repository.setEnabled(
        userId: 'guest-1',
        reminderId: 'med-1',
        enabled: true,
      );
      expect((await repository.listForUser('guest-1')).single.enabled, isTrue);

      await repository.delete(userId: 'guest-1', reminderId: 'med-1');
      expect(await repository.listForUser('guest-1'), isEmpty);
    },
  );
}
