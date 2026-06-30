import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/daos/health_tracking_logs_dao.dart';
import 'package:nano_app/core/storage/localdb/daos/notifications_dao.dart';
import 'package:nano_app/core/storage/localdb/models/notification_model.dart';
import 'package:nano_app/core/storage/localdb/sync/local_user_data_sync_dispatcher.dart';
import 'package:nano_app/core/storage/localdb/tables/daily_health_tasks_table.dart';
import 'package:nano_app/core/storage/localdb/tables/health_tracking_logs_table.dart';
import 'package:nano_app/core/storage/localdb/tables/lifestyle_schedule_items_table.dart';
import 'package:nano_app/core/storage/localdb/tables/meal_plans_table.dart';
import 'package:nano_app/core/storage/localdb/tables/notifications_table.dart';
import 'package:nano_app/app_versions/v1/features/daily_health_tracking/data/daos/daily_health_tasks_dao.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/daos/lifestyle_schedule_items_dao.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/datasources/lifestyle_schedule_local_datasource.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/models/lifestyle_schedule_item_model.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/entities/lifestyle_schedule_item_entity.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/data/daos/meal_plan_dao.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/data/models/meal_plan_model.dart';
import 'package:nano_app/app_versions/v1/services/notifications/notification_action_handler.dart';
import 'package:nano_app/app_versions/v1/services/notifications/notification_constants.dart';
import 'package:nano_app/app_versions/v1/services/notifications/notification_payload.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late NotificationsDao notificationsDao;
  late MealPlansDao mealPlansDao;
  late LifestyleScheduleItemsDao scheduleItemsDao;
  late NotificationActionHandler handler;
  late int syncRequests;

  final fixedNow = DateTime.parse('2026-06-17T07:15:00.000');

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute('PRAGMA foreign_keys = OFF');
    await db.execute(NotificationsTable.createTable);
    await db.execute(MealPlansTable.createTable);
    await db.execute(DailyHealthTasksTable.createTable);
    await db.execute(LifestyleScheduleItemsTable.createTable);
    await db.execute(HealthTrackingLogsTable.createTable);

    notificationsDao = NotificationsDao(db);
    mealPlansDao = MealPlansDao(db);
    scheduleItemsDao = LifestyleScheduleItemsDao(db);
    syncRequests = 0;
    LocalUserDataSyncDispatcher.register(({Database? database}) {
      syncRequests++;
    });
    handler = NotificationActionHandler(
      notificationsDao: notificationsDao,
      mealPlansDao: mealPlansDao,
      dailyHealthTasksDao: DailyHealthTasksDao(db),
      lifestyleScheduleItemsDao: scheduleItemsDao,
      lifestyleScheduleDatasource: LifestyleScheduleLocalDatasource(
        databaseOverride: db,
        now: () => fixedNow,
      ),
      database: db,
      now: () => fixedNow,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('done schedule item completes timeline item and linked meal', () async {
    await mealPlansDao.insert(_meal(id: 'meal-1'));
    await scheduleItemsDao.upsertMany([
      _schedule(
        id: 'schedule-1',
        sourceType: LifestyleScheduleSourceTypes.mealPlan,
        sourceId: 'meal-1',
      ),
    ]);
    await notificationsDao.insert(
      _notification(id: 'n-schedule-1', notificationId: 101),
    );

    await handler.handleAction(
      actionId: NotificationActionIds.done,
      notificationId: 101,
      payload: _payload(notificationId: 101, sourceId: 'schedule-1'),
    );

    final notification = await notificationsDao.getByNotificationId(101);
    final schedule = await scheduleItemsDao.getById('schedule-1');
    final meal = await mealPlansDao.getById('meal-1');
    final log = await HealthTrackingLogsDao(
      db,
    ).getByUserAndDate(userId: 'user-1', logDate: '2026-06-17');

    expect(notification, isNotNull);
    expect(notification!.actionStatus, NotificationActionStatuses.done);
    expect(notification.isRead, isTrue);
    expect(schedule!.isCompleted, isTrue);
    expect(meal!.isCompleted, isTrue);
    expect(log!.dailyScore, 100);
    expect(syncRequests, greaterThanOrEqualTo(1));
  });

  test('skipped records response without completing schedule source', () async {
    await scheduleItemsDao.upsertMany([
      _schedule(
        id: 'schedule-2',
        sourceType: LifestyleScheduleSourceTypes.aiSchedule,
        sourceId: '',
      ),
    ]);
    await notificationsDao.insert(
      _notification(
        id: 'n-schedule-2',
        notificationId: 201,
        sourceId: 'schedule-2',
      ),
    );

    await handler.handleAction(
      actionId: NotificationActionIds.skipped,
      notificationId: 201,
      payload: _payload(notificationId: 201, sourceId: 'schedule-2'),
    );

    final notification = await notificationsDao.getByNotificationId(201);
    final schedule = await scheduleItemsDao.getById('schedule-2');

    expect(notification, isNotNull);
    expect(notification!.actionStatus, NotificationActionStatuses.skipped);
    expect(notification.isRead, isTrue);
    expect(schedule!.isCompleted, isFalse);
    expect(syncRequests, 1);
  });

  test('handled action is idempotent on retry', () async {
    await mealPlansDao.insert(_meal(id: 'meal-idempotent'));
    await scheduleItemsDao.upsertMany([
      _schedule(
        id: 'schedule-idempotent',
        sourceType: LifestyleScheduleSourceTypes.mealPlan,
        sourceId: 'meal-idempotent',
      ),
    ]);
    await notificationsDao.insert(
      _notification(
        id: 'n-idempotent',
        notificationId: 211,
        sourceId: 'schedule-idempotent',
      ),
    );

    await handler.handleAction(
      actionId: NotificationActionIds.done,
      notificationId: 211,
      payload: _payload(notificationId: 211, sourceId: 'schedule-idempotent'),
    );
    final syncAfterFirstAction = syncRequests;

    await handler.handleAction(
      actionId: NotificationActionIds.done,
      notificationId: 211,
      payload: _payload(notificationId: 211, sourceId: 'schedule-idempotent'),
    );

    final notification = await notificationsDao.getByNotificationId(211);
    final meal = await mealPlansDao.getById('meal-idempotent');

    expect(notification!.actionStatus, NotificationActionStatuses.done);
    expect(meal!.isCompleted, isTrue);
    expect(syncRequests, syncAfterFirstAction);
  });

  test('subject mismatch records failure without completing source', () async {
    await mealPlansDao.insert(_meal(id: 'meal-subject'));
    await scheduleItemsDao.upsertMany([
      _schedule(
        id: 'schedule-subject',
        sourceType: LifestyleScheduleSourceTypes.mealPlan,
        sourceId: 'meal-subject',
      ),
    ]);
    await notificationsDao.insert(
      _notification(
        id: 'n-subject',
        notificationId: 212,
        sourceId: 'schedule-subject',
      ),
    );

    await handler.handleAction(
      actionId: NotificationActionIds.done,
      notificationId: 212,
      payload: _payload(
        notificationId: 212,
        sourceId: 'schedule-subject',
        subjectUserId: 'user-2',
      ),
    );

    final notification = await notificationsDao.getByNotificationId(212);
    final schedule = await scheduleItemsDao.getById('schedule-subject');
    final meal = await mealPlansDao.getById('meal-subject');

    expect(notification!.actionStatus, NotificationActionStatuses.actionFailed);
    expect(notification.isRead, isTrue);
    expect(schedule!.isCompleted, isFalse);
    expect(meal!.isCompleted, isFalse);
    expect(syncRequests, 1);
  });

  test(
    'source owner mismatch records failure without completing source',
    () async {
      await mealPlansDao.insert(_meal(id: 'meal-owner', userId: 'user-2'));
      await scheduleItemsDao.upsertMany([
        _schedule(
          id: 'schedule-owner',
          userId: 'user-2',
          sourceType: LifestyleScheduleSourceTypes.mealPlan,
          sourceId: 'meal-owner',
        ),
      ]);
      await notificationsDao.insert(
        _notification(
          id: 'n-owner',
          notificationId: 213,
          sourceId: 'schedule-owner',
        ),
      );

      await handler.handleAction(
        actionId: NotificationActionIds.done,
        notificationId: 213,
        payload: _payload(notificationId: 213, sourceId: 'schedule-owner'),
      );

      final notification = await notificationsDao.getByNotificationId(213);
      final schedule = await scheduleItemsDao.getById('schedule-owner');
      final meal = await mealPlansDao.getById('meal-owner');

      expect(
        notification!.actionStatus,
        NotificationActionStatuses.actionFailed,
      );
      expect(schedule!.isCompleted, isFalse);
      expect(meal!.isCompleted, isFalse);
    },
  );

  test('done with missing schedule source records action failure', () async {
    await notificationsDao.insert(
      _notification(
        id: 'n-missing-schedule',
        notificationId: 401,
        sourceId: 'missing-schedule',
      ),
    );

    await handler.handleAction(
      actionId: NotificationActionIds.done,
      notificationId: 401,
      payload: _payload(notificationId: 401, sourceId: 'missing-schedule'),
    );

    final notification = await notificationsDao.getByNotificationId(401);

    expect(notification, isNotNull);
    expect(notification!.actionStatus, NotificationActionStatuses.actionFailed);
    expect(notification.isRead, isTrue);
  });

  test('done with unsupported source records action failure', () async {
    await notificationsDao.insert(
      _notification(
        id: 'n-unsupported-source',
        notificationId: 402,
        sourceType: 'unknown_source',
        sourceId: 'unknown-source-id',
      ),
    );

    await handler.handleAction(
      actionId: NotificationActionIds.done,
      notificationId: 402,
      payload: _payload(
        notificationId: 402,
        sourceType: 'unknown_source',
        sourceId: 'unknown-source-id',
      ),
    );

    final notification = await notificationsDao.getByNotificationId(402);

    expect(notification, isNotNull);
    expect(notification!.actionStatus, NotificationActionStatuses.actionFailed);
    expect(notification.isRead, isTrue);
  });

  test('invalid payload does not crash or update notification', () async {
    await notificationsDao.insert(
      _notification(id: 'n-invalid', notificationId: 301),
    );

    await expectLater(
      handler.handleAction(
        actionId: NotificationActionIds.done,
        notificationId: 301,
        payload: '{invalid',
      ),
      completes,
    );

    final notification = await notificationsDao.getByNotificationId(301);

    expect(notification, isNotNull);
    expect(notification!.actionStatus, NotificationActionStatuses.pending);
    expect(notification.isRead, isFalse);
  });
}

NotificationModel _notification({
  required String id,
  required int notificationId,
  String sourceType = ReminderSourceTypes.lifestyleScheduleItem,
  String sourceId = 'schedule-1',
}) {
  return NotificationModel(
    id: id,
    userId: 'user-1',
    title: 'Reminder',
    body: 'Time to check in',
    type: NotificationTypes.reminder,
    sourceType: sourceType,
    sourceId: sourceId,
    scheduledAt: '2026-06-17T07:00:00.000',
    notificationId: notificationId,
    actionStatus: NotificationActionStatuses.pending,
    payload: _payload(
      notificationId: notificationId,
      sourceType: sourceType,
      sourceId: sourceId,
    ),
    createdAt: '2026-06-16T08:00:00.000',
    updatedAt: '2026-06-16T08:00:00.000',
  );
}

String _payload({
  required int notificationId,
  String sourceType = ReminderSourceTypes.lifestyleScheduleItem,
  required String sourceId,
  String? subjectUserId,
}) {
  return NotificationPayload(
    notificationId: notificationId,
    sourceType: sourceType,
    sourceId: sourceId,
    scheduledAt: '2026-06-17T07:00:00.000',
    subjectUserId: subjectUserId,
  ).toJsonString();
}

MealPlanModel _meal({required String id, String userId = 'user-1'}) {
  return MealPlanModel(
    id: id,
    userId: userId,
    planDate: '2026-06-17',
    mealType: 'breakfast',
    mealName: 'Oatmeal',
    description: 'Light breakfast',
    calories: 350,
    protein: 12,
    carbs: 45,
    fat: 8,
    fiber: 6,
    waterMl: 300,
    mealOrder: 1,
    startTime: '07:00',
    endTime: '07:30',
    cookingInstructions: 'Cook oats. Add fruit.',
    isCompleted: false,
    aiGenerated: true,
    createdAt: '2026-06-16T08:00:00.000',
    updatedAt: '2026-06-16T08:00:00.000',
  );
}

LifestyleScheduleItemModel _schedule({
  required String id,
  String userId = 'user-1',
  required String sourceType,
  required String sourceId,
}) {
  return LifestyleScheduleItemModel(
    id: id,
    userId: userId,
    scheduleDate: '2026-06-17',
    startTime: '07:00',
    endTime: '07:30',
    title: 'Timeline task',
    description: 'Description',
    category: sourceType == LifestyleScheduleSourceTypes.mealPlan
        ? LifestyleScheduleCategories.meal
        : LifestyleScheduleCategories.routine,
    sourceType: sourceType,
    sourceId: sourceId.isEmpty ? null : sourceId,
    targetValue: 1,
    currentValue: 0,
    unit: 'lan',
    isCompleted: false,
    sortOrder: 1,
    aiGenerated: true,
    encouragement: 'Good',
    createdAt: '2026-06-16T08:00:00.000',
    updatedAt: '2026-06-16T08:00:00.000',
  );
}
