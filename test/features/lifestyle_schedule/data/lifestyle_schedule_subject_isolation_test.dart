import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/daos/lifestyle_schedule_items_dao.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/datasources/lifestyle_schedule_local_datasource.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/models/lifestyle_schedule_item_model.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/services/schedule_completion_exception.dart';
import 'package:nano_app/core/storage/localdb/tables/lifestyle_schedule_items_table.dart';
import 'package:nano_app/core/storage/localdb/tables/users_table.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late LifestyleScheduleLocalDatasource datasource;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute(UsersTable.createTable);
    await db.execute(LifestyleScheduleItemsTable.createTable);
    await db.insert('users', _user('user-a', 'Người A', '2026-08-15'));
    await db.insert('users', _user('user-b', 'Người B', '2026-08-16'));
    await LifestyleScheduleItemsDao(db).upsertMany([
      _item(id: 'schedule-a', userId: 'user-a'),
      _item(id: 'schedule-b', userId: 'user-b'),
    ]);
    datasource = LifestyleScheduleLocalDatasource(
      databaseOverride: db,
      now: () => DateTime(2026, 8, 17, 8),
    );
  });

  tearDown(() => db.close());

  test('A -> B -> A reads the explicitly selected subject, not latest user', () async {
    final a1 = await datasource.getWeekSchedule(userId: 'user-a');
    final b = await datasource.getWeekSchedule(userId: 'user-b');
    final a2 = await datasource.getWeekSchedule(userId: 'user-a');

    expect(a1.fullName, 'Người A');
    expect(a1.items.map((item) => item.id), ['schedule-a']);
    expect(b.fullName, 'Người B');
    expect(b.items.map((item) => item.id), ['schedule-b']);
    expect(a2.items.map((item) => item.id), ['schedule-a']);
  });

  test('legacy unscoped completion is rejected when multiple owners exist', () async {
    expect(
      () => datasource.completeItemById(
        'schedule-a',
        completionProofPath: 'proofs/test.jpg',
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('subject cannot complete another subject schedule item by id', () async {
    expect(
      () => datasource.completeItemById(
        'schedule-a',
        userId: 'user-b',
        completionProofPath: 'proofs/test.jpg',
      ),
      throwsA(isA<ScheduleCompletionException>()),
    );
  });
}

Map<String, Object?> _user(String id, String name, String createdAt) => {
  'id': id,
  'full_name': name,
  'product_access_status': 'guest',
  'onboarding_status': 'completed',
  'created_at': createdAt,
  'updated_at': createdAt,
};

LifestyleScheduleItemModel _item({required String id, required String userId}) {
  return LifestyleScheduleItemModel(
    id: id,
    userId: userId,
    scheduleDate: '2026-08-17',
    startTime: '08:00',
    endTime: '08:30',
    title: 'Nhiệm vụ',
    category: 'health',
    sourceType: 'manual',
    createdAt: '2026-08-17T00:00:00.000Z',
    updatedAt: '2026-08-17T00:00:00.000Z',
  );
}
