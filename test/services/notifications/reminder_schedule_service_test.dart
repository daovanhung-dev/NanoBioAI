import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/daos/notifications_dao.dart';
import 'package:nano_app/core/storage/localdb/models/notification_model.dart';
import 'package:nano_app/core/storage/localdb/tables/lifestyle_schedule_items_table.dart';
import 'package:nano_app/core/storage/localdb/tables/notifications_table.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/daos/lifestyle_schedule_items_dao.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/models/lifestyle_schedule_item_model.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/entities/lifestyle_schedule_item_entity.dart';
import 'package:nano_app/app_versions/v1/services/notifications/notification_constants.dart';
import 'package:nano_app/app_versions/v1/services/notifications/notification_id_generator.dart';
import 'package:nano_app/app_versions/v1/services/notifications/notification_payload.dart';
import 'package:nano_app/app_versions/v1/services/notifications/reminder_notification_scheduler.dart';
import 'package:nano_app/app_versions/v1/services/notifications/reminder_schedule_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late LifestyleScheduleItemsDao scheduleItemsDao;
  late NotificationsDao notificationsDao;
  late FakeReminderNotificationScheduler scheduler;
  late ReminderScheduleService service;

  final fixedNow = DateTime.parse('2026-06-17T08:00:00.000');

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute('PRAGMA foreign_keys = OFF');
    await db.execute(NotificationsTable.createTable);
    await db.execute(LifestyleScheduleItemsTable.createTable);

    scheduleItemsDao = LifestyleScheduleItemsDao(db);
    notificationsDao = NotificationsDao(db);
    scheduler = FakeReminderNotificationScheduler();
    service = ReminderScheduleService(
      scheduleItemsDao: scheduleItemsDao,
      notificationsDao: notificationsDao,
      scheduler: scheduler,
      now: () => fixedNow,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('schedules only future incomplete timeline reminders', () async {
    await scheduleItemsDao.upsertMany([
      _item(id: 'past', startTime: '07:00'),
      _item(id: 'future', startTime: '12:00'),
      _item(id: 'completed', startTime: '13:00', isCompleted: true),
    ]);

    await service.scheduleGeneratedReminders();

    final rows = await notificationsDao.getAll();

    expect(scheduler.permissionRequested, isTrue);
    expect(scheduler.scheduled, hasLength(1));
    expect(rows, hasLength(1));
    expect(rows.single.sourceType, ReminderSourceTypes.lifestyleScheduleItem);
    expect(rows.single.sourceId, 'future');
    expect(scheduler.scheduled.single.scheduledAt, DateTime(2026, 6, 17, 12));
  });

  test('uses schedule item title and description as reminder copy', () async {
    await scheduleItemsDao.upsertMany([
      _item(
        id: 'details',
        title: 'Uống nước',
        description: 'Đến giờ uống 250 ml nước theo lịch trình hôm nay.',
      ),
    ]);

    await service.scheduleGeneratedReminders();

    final scheduled = scheduler.scheduled.single;
    final row = (await notificationsDao.getAll()).single;

    expect(scheduled.title, 'Uống nước');
    expect(scheduled.body, 'Đến giờ uống 250 ml nước theo lịch trình hôm nay.');
    expect(row.title, scheduled.title);
    expect(row.body, scheduled.body);
  });

  test(
    'uses Vietnamese fallback copy when schedule item copy is empty',
    () async {
      await scheduleItemsDao.upsertMany([
        _item(
          id: 'fallback-copy',
          title: ' ',
          description: ' ',
          encouragement: ' ',
        ),
      ]);

      await service.scheduleGeneratedReminders();

      final scheduled = scheduler.scheduled.single;

      expect(scheduled.title, 'Nhắc việc sức khỏe');
      expect(scheduled.body, 'Mở app để cập nhật tiến độ hôm nay');
    },
  );

  test('encodes stable payload and notification id', () async {
    await scheduleItemsDao.upsertMany([_item(id: 'schedule-stable')]);

    await service.scheduleGeneratedReminders();

    final scheduled = scheduler.scheduled.single;
    final expectedRowId =
        'reminder_user-1_lifestyle_schedule_item_schedule-stable_2026-06-17T12:00:00.000';
    final expectedNotificationId = deterministicNotificationId(expectedRowId);
    final payload = NotificationPayload.fromJsonString(scheduled.payload);
    final rows = await notificationsDao.getAll();

    expect(scheduled.id, expectedNotificationId);
    expect(payload.payloadVersion, NotificationPayload.currentPayloadVersion);
    expect(payload.notificationId, expectedNotificationId);
    expect(payload.sourceType, ReminderSourceTypes.lifestyleScheduleItem);
    expect(payload.sourceId, 'schedule-stable');
    expect(payload.scheduledAt, '2026-06-17T12:00:00.000');
    expect(payload.subjectUserId, 'user-1');
    expect(payload.actorUserId, 'user-1');
    expect(payload.correlationId, expectedRowId);
    expect(rows.single.id, expectedRowId);
    expect(rows.single.notificationId, expectedNotificationId);
  });

  test(
    'permission denied inserts rows without scheduling or throwing',
    () async {
      scheduler.permissionGranted = false;
      await scheduleItemsDao.upsertMany([_item(id: 'denied')]);

      await expectLater(service.scheduleGeneratedReminders(), completes);

      final rows = await notificationsDao.getAll();

      expect(scheduler.scheduled, isEmpty);
      expect(rows, hasLength(1));
      final payload = NotificationPayload.fromJsonString(rows.single.payload!);
      expect(payload.subjectUserId, 'user-1');
      expect(
        rows.single.actionStatus,
        NotificationActionStatuses.permissionDenied,
      );
    },
  );

  test('reschedule cancels and deletes existing pending rows', () async {
    await scheduleItemsDao.upsertMany([_item(id: 'reschedule')]);
    await notificationsDao.insert(
      _notification(id: 'old-pending', notificationId: 999),
    );

    await service.scheduleGeneratedReminders();

    final rows = await notificationsDao.getAll();

    expect(scheduler.cancelled, [999]);
    expect(rows, hasLength(1));
    expect(rows.single.id, isNot('old-pending'));
    expect(rows.single.sourceId, 'reschedule');
  });

  test('reschedule keeps pending rows for a different subject', () async {
    await scheduleItemsDao.upsertMany([_item(id: 'reschedule')]);
    await notificationsDao.insert(
      _notification(id: 'same-subject-pending', notificationId: 998),
    );
    await notificationsDao.insert(
      _notification(
        id: 'other-subject-pending',
        notificationId: 997,
        userId: 'user-2',
      ),
    );

    await service.scheduleGeneratedReminders();

    final rows = await notificationsDao.getAll();

    expect(scheduler.cancelled, [998]);
    expect(rows.any((row) => row.id == 'same-subject-pending'), isFalse);
    expect(rows.any((row) => row.id == 'other-subject-pending'), isTrue);
    expect(rows.where((row) => row.userId == 'user-1'), hasLength(1));
  });

  test('schedule failure records failed row and continues', () async {
    await scheduleItemsDao.upsertMany([
      _item(id: 'fails', startTime: '12:00'),
      _item(id: 'succeeds', scheduleDate: '2026-06-18', startTime: '07:00'),
    ]);
    final failedRowId =
        'reminder_user-1_lifestyle_schedule_item_fails_2026-06-17T12:00:00.000';
    scheduler.failScheduleIds.add(deterministicNotificationId(failedRowId));

    await service.scheduleGeneratedReminders();

    final rows = await notificationsDao.getAll();
    final failed = rows.singleWhere((row) => row.sourceId == 'fails');
    final succeeded = rows.singleWhere((row) => row.sourceId == 'succeeds');

    expect(rows, hasLength(2));
    expect(scheduler.scheduled, hasLength(1));
    expect(failed.actionStatus, NotificationActionStatuses.scheduleFailed);
    expect(succeeded.actionStatus, NotificationActionStatuses.pending);
  });
}

NotificationModel _notification({
  required String id,
  required int notificationId,
  String userId = 'user-1',
}) {
  return NotificationModel(
    id: id,
    userId: userId,
    title: 'Old reminder',
    body: 'Old reminder body',
    type: NotificationTypes.reminder,
    sourceType: ReminderSourceTypes.lifestyleScheduleItem,
    sourceId: 'reschedule',
    scheduledAt: '2026-06-17T07:00:00.000',
    notificationId: notificationId,
    actionStatus: NotificationActionStatuses.pending,
    payload: '{}',
    createdAt: '2026-06-16T08:00:00.000',
    updatedAt: '2026-06-16T08:00:00.000',
  );
}

LifestyleScheduleItemModel _item({
  required String id,
  String scheduleDate = '2026-06-17',
  String startTime = '12:00',
  String title = 'Timeline task',
  String description = 'Time to check in',
  String encouragement = 'Nice',
  bool isCompleted = false,
}) {
  return LifestyleScheduleItemModel(
    id: id,
    userId: 'user-1',
    scheduleDate: scheduleDate,
    startTime: startTime,
    endTime: '',
    title: title,
    description: description,
    category: LifestyleScheduleCategories.meal,
    sourceType: LifestyleScheduleSourceTypes.mealPlan,
    sourceId: 'meal-$id',
    targetValue: 1,
    currentValue: isCompleted ? 1 : 0,
    unit: 'lan',
    isCompleted: isCompleted,
    sortOrder: 1,
    aiGenerated: true,
    encouragement: encouragement,
    createdAt: '2026-06-16T08:00:00.000',
    updatedAt: '2026-06-16T08:00:00.000',
  );
}

class FakeReminderNotificationScheduler
    implements ReminderNotificationScheduler {
  bool permissionGranted = true;
  bool permissionRequested = false;
  final failScheduleIds = <int>{};
  final scheduled = <ScheduledReminder>[];
  final cancelled = <int>[];

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermissions() async {
    permissionRequested = true;
    return permissionGranted;
  }

  @override
  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    required String payload,
  }) async {
    if (failScheduleIds.contains(id)) {
      throw StateError('Failed to schedule $id');
    }
    scheduled.add(
      ScheduledReminder(
        id: id,
        title: title,
        body: body,
        scheduledAt: scheduledAt,
        payload: payload,
      ),
    );
  }

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
  }
}

class ScheduledReminder {
  final int id;
  final String title;
  final String body;
  final DateTime scheduledAt;
  final String payload;

  const ScheduledReminder({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledAt,
    required this.payload,
  });
}
