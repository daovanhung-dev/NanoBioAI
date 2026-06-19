import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/tables/lifestyle_schedule_items_table.dart';
import 'package:nano_app/features/lifestyle_schedule/data/daos/lifestyle_schedule_items_dao.dart';
import 'package:nano_app/features/lifestyle_schedule/data/models/lifestyle_schedule_item_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late LifestyleScheduleItemsDao dao;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute(LifestyleScheduleItemsTable.createTable);
    dao = LifestyleScheduleItemsDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('upsertMany and getByDate return sorted schedule items', () async {
    final later = _item(id: 'later', startTime: '12:00', sortOrder: 2);
    final earlier = _item(id: 'earlier', startTime: '07:00', sortOrder: 1);

    await dao.upsertMany([later, earlier]);

    final restored = await dao.getByDate(
      userId: 'u1',
      scheduleDate: '2026-06-17',
    );

    expect(restored.map((item) => item.id), ['earlier', 'later']);
  });

  test('getByDateRange filters by user and date range', () async {
    await dao.upsertMany([
      _item(id: 'day-1', scheduleDate: '2026-06-17'),
      _item(id: 'day-2', scheduleDate: '2026-06-18'),
      _item(id: 'outside', scheduleDate: '2026-06-24'),
      _item(id: 'other-user', userId: 'u2'),
    ]);

    final restored = await dao.getByDateRange(
      userId: 'u1',
      startDate: '2026-06-17',
      endDate: '2026-06-23',
    );

    expect(restored.map((item) => item.id), ['day-1', 'day-2']);
  });

  test('deleteByUserIdAndDateRange removes only matching user range', () async {
    await dao.upsertMany([
      _item(id: 'day-1', scheduleDate: '2026-06-17'),
      _item(id: 'day-2', scheduleDate: '2026-06-18'),
      _item(id: 'outside', scheduleDate: '2026-06-24'),
      _item(id: 'other-user', userId: 'u2', scheduleDate: '2026-06-18'),
    ]);

    await dao.deleteByUserIdAndDateRange(
      userId: 'u1',
      startDate: '2026-06-17',
      endDate: '2026-06-18',
    );

    final restored = await dao.getAll();

    expect(restored.map((item) => item.id), ['other-user', 'outside']);
  });

  test('updateCompletion persists progress status', () async {
    await dao.upsertMany([_item(id: 'schedule-1')]);

    await dao.updateCompletion(
      id: 'schedule-1',
      isCompleted: true,
      currentValue: 1,
      updatedAt: '2026-06-17T07:30:00',
    );

    final restored = await dao.getById('schedule-1');

    expect(restored, isNotNull);
    expect(restored!.isCompleted, isTrue);
    expect(restored.currentValue, 1);
    expect(restored.updatedAt, '2026-06-17T07:30:00');
  });
}

LifestyleScheduleItemModel _item({
  required String id,
  String userId = 'u1',
  String scheduleDate = '2026-06-17',
  String startTime = '07:00',
  int sortOrder = 1,
}) {
  return LifestyleScheduleItemModel(
    id: id,
    userId: userId,
    scheduleDate: scheduleDate,
    startTime: startTime,
    endTime: '07:30',
    title: 'Task',
    description: 'Description',
    category: 'routine',
    sourceType: 'ai_schedule',
    targetValue: 1,
    currentValue: 0,
    unit: 'lan',
    isCompleted: false,
    sortOrder: sortOrder,
    aiGenerated: true,
    encouragement: 'Nice',
    createdAt: '2026-06-16T08:00:00',
    updatedAt: '2026-06-16T08:00:00',
  );
}
