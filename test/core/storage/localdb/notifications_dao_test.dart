import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/daos/notifications_dao.dart';
import 'package:nano_app/core/storage/localdb/models/notification_model.dart';
import 'package:nano_app/core/storage/localdb/tables/notifications_table.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late NotificationsDao dao;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute('PRAGMA foreign_keys = OFF');
    await db.execute(NotificationsTable.createTable);
    dao = NotificationsDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'insert stores notifications and getAll returns scheduled order',
    () async {
      final later = _notification(
        id: 'n-later',
        sourceId: 'meal-2',
        scheduledAt: '2026-06-17T12:00:00.000',
        notificationId: 200,
      );
      final earlier = _notification(
        id: 'n-earlier',
        sourceId: 'meal-1',
        scheduledAt: '2026-06-17T07:00:00.000',
        notificationId: 100,
      );

      await dao.insert(later);
      await dao.insert(earlier);

      final restored = await dao.getAll();

      expect(restored, hasLength(2));
      expect(restored.map((item) => item.id), ['n-earlier', 'n-later']);
      expect(restored.first.sourceType, 'meal');
      expect(restored.first.actionStatus, NotificationActionStatuses.pending);
    },
  );

  test('getByNotificationId returns matching notification', () async {
    await dao.insert(
      _notification(id: 'n1', sourceId: 'meal-1', notificationId: 123),
    );

    final restored = await dao.getByNotificationId(123);
    final missing = await dao.getByNotificationId(999);

    expect(restored, isNotNull);
    expect(restored!.id, 'n1');
    expect(missing, isNull);
  });

  test('getPendingBySources filters pending notifications by source', () async {
    await dao.insertMany([
      _notification(id: 'pending-1', sourceId: 'meal-1', notificationId: 1),
      _notification(
        id: 'done-1',
        sourceId: 'meal-2',
        notificationId: 2,
        actionStatus: NotificationActionStatuses.done,
      ),
      _notification(
        id: 'task-1',
        sourceType: 'daily_task',
        sourceId: 'task-1',
        notificationId: 3,
      ),
    ]);

    final restored = await dao.getPendingBySources(
      sourceType: 'meal',
      sourceIds: ['meal-1', 'meal-2'],
    );

    expect(restored.map((item) => item.id), ['pending-1']);
  });

  test(
    'deletePendingBySources removes only matching pending notifications',
    () async {
      await dao.insertMany([
        _notification(id: 'pending-1', sourceId: 'meal-1', notificationId: 1),
        _notification(
          id: 'done-1',
          sourceId: 'meal-1',
          notificationId: 2,
          actionStatus: NotificationActionStatuses.done,
        ),
        _notification(
          id: 'task-1',
          sourceType: 'daily_task',
          sourceId: 'meal-1',
          notificationId: 3,
        ),
      ]);

      await dao.deletePendingBySources(
        sourceType: 'meal',
        sourceIds: ['meal-1'],
      );

      final restored = await dao.getAll();

      expect(restored.map((item) => item.id).toSet(), {'done-1', 'task-1'});
    },
  );

  test('updateActionStatus marks notification response fields', () async {
    await dao.insert(
      _notification(id: 'n1', sourceId: 'meal-1', notificationId: 123),
    );

    await dao.updateActionStatus(
      id: 'n1',
      actionStatus: NotificationActionStatuses.skipped,
      respondedAt: '2026-06-17T07:10:00.000',
      updatedAt: '2026-06-17T07:10:00.000',
    );

    final restored = await dao.getByNotificationId(123);

    expect(restored, isNotNull);
    expect(restored!.actionStatus, NotificationActionStatuses.skipped);
    expect(restored.isRead, isTrue);
    expect(restored.respondedAt, '2026-06-17T07:10:00.000');
    expect(restored.updatedAt, '2026-06-17T07:10:00.000');
  });
}

NotificationModel _notification({
  required String id,
  required String sourceId,
  required int notificationId,
  String sourceType = 'meal',
  String scheduledAt = '2026-06-17T07:00:00.000',
  String actionStatus = NotificationActionStatuses.pending,
}) {
  return NotificationModel(
    id: id,
    userId: 'user-1',
    title: 'Reminder',
    body: 'Time to check in',
    type: 'reminder',
    sourceType: sourceType,
    sourceId: sourceId,
    scheduledAt: scheduledAt,
    notificationId: notificationId,
    actionStatus: actionStatus,
    payload: '{"sourceId":"$sourceId"}',
    createdAt: '2026-06-16T08:00:00.000',
    updatedAt: '2026-06-16T08:00:00.000',
  );
}
